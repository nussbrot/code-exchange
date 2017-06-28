"""
This module can export a Wishbone slave to VHDL from an SXL 'block' description
@author rhallmen
@date 20.06.2017
"""

import sys
import math
import re
from string import Template
from getpass import getuser
import datetime
import argparse
from os.path import basename, splitext

from antlr4 import *

sys.path.append('../python')
from sxlLexer import sxlLexer
from sxlParser import sxlParser
from sxlVisitor import sxlVisitor
from BlockSizeVisitor import BlockSizeVisitor
from RegisterAddressVisitor import RegisterAddressVisitor
from SignalVisitor import SignalVisitor, Position

class WbTemplate(Template):
    """
    Subclass of Template class, because our templates use %identifier% as
    placeholder. Also note the % at the end, this requires special handling
    with an dictionary, since % is not an allowed character for python ids.
    E.g. %id% -> the identifier to match is id%.
    """

    delimiter = '%'
    idpattern = r'[_a-z][_a-z0-9]*?%'

    @classmethod
    def from_file(cls, path):
        """Get an instance of this class with the template string
        read from file @path
        """
        with open(path, 'r') as file:
            tpl = file.read()
        return cls(tpl)


def _setup_parser():
    parser = argparse.ArgumentParser(description="Export a wishbone slave")
    parser.add_argument('-p', '--project', default='Solectrix Uber Project')
    parser.add_argument('-t', '--template', default='wb_reg_no_rst.tpl.vhd')
    parser.add_argument('sxl_file', help="sxl input")
    parser.add_argument('sxl_block', help="which sxl block from sxl_file to export")
    parser.add_argument('vhdl_file', help="vhdl output")
    return parser

def _setup_dictionary(project, vhdl_file, tpl_file):
    """
    All placeholders found in the template file need to have a
    key value pair in a dictionary. For all SXL independent placeholders
    this dict is build right here.
    """

    date = datetime.date.today()

    library = """
LIBRARY fun_lib;
USE fun_lib.wishbone_pkg.ALL;
"""

    id_dic = {
        'TPL_YEAR%':date.year,
        'TPL_DATE%':date.strftime('%d.%m.%Y'),
        'TPL_SCRIPT%':basename(__file__),
        'TPL_TPLFILE%':basename(tpl_file),
        'TPL_USER%':getuser(),
        'TPL_LIBRARY%':library,
        'TPL_PROCEDURES%':'',
        'TPL_PROJECT%':project,
        'TPL_VHDLFILE%':basename(vhdl_file),
        'TPL_MODULE%':basename(splitext(vhdl_file)[0]),
    }

    return id_dic

def _setup_sxl_parse_tree(path):
    """Returning an ANTLR parse tree of the SXL file at path"""
    inp = FileStream(path)
    lexer = sxlLexer(inp)
    stream = CommonTokenStream(lexer)
    parser = sxlParser(stream)
    tree = parser.blocks()
    return tree

FIRST_CAP_RE = re.compile('(.)([A-Z][a-z]+)')
ALL_CAP_RE = re.compile('([a-z0-9])([A-Z])')
def convert(name):
    """Convert CamelCase to camel_case"""
    name = FIRST_CAP_RE.sub(r'\1_\2', name)
    return ALL_CAP_RE.sub(r'\1_\2', name).lower()

def double_quote(string):
    """Place double quotes around the given string"""
    return '"' + string + '"'

def single_quote(string):
    """Place single quotes around the given string"""
    return "'" + string + "'"

ADDR_PRE = "c_addr_"
def _rename_addr_dict(dic):
    old_keys = list(dic.keys())
    for key in old_keys:
        name = ADDR_PRE + convert(key)
        dic[name] = dic.pop(key)

INDENT = "  "
def _join_with_indent(lis, indent_level):
    string = "\n" + indent_level*INDENT
    return string.join(lis)

def _format_reg_addr(dic):
    # sort dict for addresses
    sort = sorted(dic.items(), key=lambda x: x[1])
    string = "CONSTANT {:21} : INTEGER := 16#{:04x}#;"
    result = []
    for name, addr in sort:
        result.append(string.format(name, addr))

    return result

def _format_addr_validation(items):
    string = "'1' WHEN {},"
    result = []
    for key in items:
        result.append(string.format(ADDR_PRE + convert(key)))

    return result

def _format_notifier_constant(has_notify):
    string = "CONSTANT {:21} : BOOLEAN := {};"
    return [string.format("c_has_read_notifies", str(has_notify).upper())]

OUT_PRE = "o_"
IN_PRE = "i_"
VECTOR = "STD_LOGIC_VECTOR"
BIT = "STD_LOGIC"
PORT_STRING = "{:25} : {:3} {};"
def _format_port_signal(signals):
    """
    This deviates from the other format functions, because the dict
    we get is filled with shallow Signal objects.
    """
    result = []
    for key, sig in signals.items():
        if sig.isInput:
            _name = IN_PRE
            _dir = "IN"
        else:
            _name = OUT_PRE
            _dir = "OUT"
        _name += convert(key)
        if sig.position.isRange:
            _type = VECTOR + sig.position.decl()
        else:
            _type = BIT

        result.append(PORT_STRING.format(_name, _dir, _type))

    return result

READ_POST = "_trd"
WRITE_POST = "_twr"
def iter_notify_port(notifies):
    """
    Generator. Expects a dict containing the name of the
    notifier as keys and the mode ('rw'|'wo'|'ro') as value.
    """
    for key, mode in notifies.items():
        if mode in ['ro', 'rw']:
            _name = OUT_PRE + convert(key) + READ_POST
            yield _name
        if mode in ['wo', 'rw']:
            _name = OUT_PRE + convert(key) + WRITE_POST
            yield _name

def _format_port_notify(notifies):
    """
    This function expects a dict containing the name of the
    notifier as keys and the mode ('rw'|'wo'|'ro') as value.
    Notifies are always outputs.
    """
    result = []
    for _name in iter_notify_port(notifies):
        result.append(PORT_STRING.format(_name, "OUT", BIT))

    return result

def _check_reset(reset, pos):
    assert 2**len(pos) > reset

def _reset_bit_twiddling(reset, pos, old_reset):
    _check_reset(reset, pos)
    # we made sure reset fits into pos. No further checks are needed.
    return old_reset | (reset << pos.right)

WO_PRE = "s_wo_"
T_PRE = "s_trg_"
RW_PRE = "s_rw_"
C_PRE = "s_const_"
REG_PRE = "s_reg_"
MODE_DIC = {'wo':WO_PRE, 't':T_PRE, 'rw':RW_PRE, 'c':C_PRE}
def _format_register_decl(regs):
    """
    This function expects an dict of a list. With the keys being
    the register names and the list containing corresponding
    signal objects.
    """
    result = []
    _type = VECTOR + Position(True, 31, 0).decl()
    string = 'SIGNAL {:30} : {} := x"{:08x}";'
    for key, sigs in regs.items():
        _reset = 0
        _name = REG_PRE + convert(key)
        for sig in sigs:
            _reset = _reset_bit_twiddling(sig.reset, sig.position, _reset)

        result.append(string.format(_name, _type, _reset))

    return result

def _format_signal_decl(sigs):
    """
    Write-only and Trigger signals also need a signal declaration
    This function takes a dict of named signals.
    """
    result = []
    string = 'SIGNAL {:30} : {} := {};'
    for key, sig in sigs.items():
        _type = VECTOR + str(sig.position)
        _reset = "f_reset_cast({}, {})".format(sig.reset, len(sig.position))
        if len(sig.position) == 1:
            _type = BIT
            _reset = single_quote(str(sig.reset))
        if sig.mode not in ['wo', 't']:
            continue

        _name = MODE_DIC[sig.mode] + convert(key)
        result.append(string.format(_name, _type, _reset))


    return result

def _format_register_default(sigs, notifies):
    """
    Grab trigger signals from sigs and notifies from notifies.
    """
    result = []
    string = '{:30} <= {};'

    # handle trigger signals
    for key, sig in sigs.items():
        if sig.mode not in ['t']:
            continue
        _name = T_PRE + convert(key)
        _value = "(OTHERS => '0')"
        if len(sig.position) == 1:
            _value = "'0'"
        result.append(string.format(_name, _value))

    # handle notifies
    _value = "'0'"
    for _name in iter_notify_port(notifies):
        result.append(string.format(_name, _value))

    return result

def main(project, sxl_file, sxl_block, vhdl_file, tpl_file):
    """The main routine of this module"""
    # setup dictionary
    id_dic = _setup_dictionary(project, vhdl_file, tpl_file)
    tree = _setup_sxl_parse_tree(sxl_file)

    # get the block size
    v = BlockSizeVisitor()
    v.visit(tree)
    tmp = v.dict[sxl_block]
    block_size = math.ceil(math.log(tmp, 2))
    id_dic['TPL_WBSIZE%'] = block_size

    # get the register addresses
    v = RegisterAddressVisitor()
    v.visit(tree)
    dic = v.addr
    _rename_addr_dict(dic)
    const = _format_reg_addr(dic)
    const.extend(_format_notifier_constant(v.has_read_notify))
    id_dic['TPL_CONSTANTS%'] = _join_with_indent(const, 1)

    # re-use the above visitor to also handle address validation
    validate = _format_addr_validation(v.validate)
    id_dic['TPL_ADDR_VALIDATION%'] = _join_with_indent(validate, 2)

    # look at port declaration
    v = SignalVisitor()
    v.visit(tree)
    ports = _format_port_signal(v.sigs)
    ports.extend(_format_port_notify(v.notifies))
    id_dic['TPL_PORTS%'] = _join_with_indent(ports, 2)

    # look at register and signal declaration
    signals = _format_register_decl(v.regs)
    signals.extend(_format_signal_decl(v.sigs))
    id_dic['TPL_REGISTERS%'] = _join_with_indent(signals, 1)

    # look at default values
    defaults = _format_register_default(v.sigs, v.notifies)
    id_dic['TPL_REG_DEFAULT%'] = _join_with_indent(defaults, 3)

    # do the template substitution
    tpl = WbTemplate.from_file(tpl_file)
    print(tpl.safe_substitute(id_dic))

if __name__ == '__main__':
    PARSER = _setup_parser()
    ARGS = PARSER.parse_args()
    main(
        ARGS.project, ARGS.sxl_file, ARGS.sxl_block,
        ARGS.vhdl_file, ARGS.template)
