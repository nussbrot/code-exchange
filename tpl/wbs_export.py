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
from SignalVisitor import SignalVisitor, Position, Signal

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
def _addr_name(name):
    return ADDR_PRE + convert(name)

def _rename_addr_dict(dic):
    old_keys = list(dic.keys())
    for key in old_keys:
        name = _addr_name(key)
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
        result.append(string.format(_addr_name(key)))

    return result

def _format_notifier_constant(has_notify):
    string = "CONSTANT {:21} : BOOLEAN := {};"
    return [string.format("c_has_read_notifies", str(has_notify).upper())]

OUT_PRE = "o_"
IN_PRE = "i_"
PORT_DIC = {True:IN_PRE, False:OUT_PRE}
def _port_name(sig: Signal):
    return PORT_DIC[sig.isInput] + convert(sig.name)

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
            _dir = "IN"
        else:
            _dir = "OUT"
        if sig.position.isRange:
            _type = VECTOR + sig.position.decl()
        else:
            _type = BIT

        _name = _port_name(sig)
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
            yield (_name, "read")
        if mode in ['wo', 'rw']:
            _name = OUT_PRE + convert(key) + WRITE_POST
            yield (_name, "read")

def _format_port_notify(notifies):
    """
    This function expects a dict containing the name of the
    notifier as keys and the mode ('rw'|'wo'|'ro') as value.
    Notifies are always outputs.
    """
    result = []
    for _name, _ in iter_notify_port(notifies):
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
SIGNAL_DIC = {'wo':WO_PRE, 't':T_PRE, 'rw':RW_PRE, 'c':C_PRE}
def _sig_name(sig: Signal):
    return SIGNAL_DIC[sig.mode] + convert(sig.name)

def _reg_name(reg):
    return REG_PRE + convert(reg)

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
        _name = _reg_name(key)
        for sig in sigs:
            _reset = _reset_bit_twiddling(sig.reset, sig.position, _reset)

        result.append(string.format(_name, _type, _reset))

    return result

def _format_register_default(sigs, notifies):
    """
    Grab trigger signals from sigs and notifies from notifies.
    Default values are set on port names
    """
    result = []
    string = '{:30} <= {};'

    # handle trigger signals
    for sig in iter_signals_with_mode(sigs.values(), ['t']):
        _name = _port_name(sig)
        _value = "(OTHERS => '0')"
        if len(sig.position) == 1:
            _value = "'0'"
        result.append(string.format(_name, _value))

    # handle notifies
    _value = "'0'"
    for _name, _ in iter_notify_port(notifies):
        result.append(string.format(_name, _value))

    return result

def _mask_from_pos(pos: Position):
    return (2**len(pos)-1) << pos.right

def _format_mask(mask):
    return 'x"{:08x}"'.format(mask)

def _format_register_write(regs, validate, notifies):
    """
    All writes must be gathered and written to a result list.
    However this is unfortunately complicated.
    - notifies: a dict with reg name as key and the notify type as value.
    - validate: a list with validated register names. Only those may be added.
    - regs: a dict with reg names as keys and corresponding signals as items.
    """
    result = []
    str_case = "WHEN {} =>"
    fun_dic = {"rw":"set_reg", "wo":"set_reg", "t":"set_trg"}
    str_reg = INDENT + "{}(s_int_data, s_int_we, {}, {});"
    str_write_vec = INDENT + "set_write_port(s_int_data, s_int_we, {left}, {right}, {name});"
    str_write_bit = INDENT + "set_write_port(s_int_data, s_int_we, {left}, {name});"
    str_not = INDENT + "set_notify({}, {});"
    not_dic = {"read":"s_int_trd", "write":"s_int_twr"}
    # looping over validated registers
    for reg_name in validate:
        # First add the address. If we don't need it we will remove it later.
        result.append(str_case.format(_addr_name(reg_name)))
        # Each name in validate is also in regs, but not necessarily in notifies
        sigs = regs[reg_name]
        mask = 0
        has_items = False
        for sig in sigs:
            if sig.mode in ['rw']:
                has_items = True
                # for rw registers a single statement is added, after building the mask
                mask |= _mask_from_pos(sig.position)
            if sig.mode in ['wo', 't']:
                has_items = True
                string_dic = {
                    "left":sig.position.left,
                    "right":sig.position.right,
                    "name":_port_name(sig)}
                # write only signals have their own statement and map directly to ports
                if len(sig.position) == 1:
                    string = str_write_bit
                else:
                    string = str_write_vec
                result.append(string.format(**string_dic))

        # add rw if a mask is set
        if mask > 0:
            result.append(str_reg.format(fun_dic['rw'], _format_mask(mask), _reg_name(reg_name)))
        # check if register has notifier
        if reg_name in notifies:
            has_items = True
            for name, mode in iter_notify_port({reg_name:notifies[reg_name]}):
                result.append(str_not.format(not_dic[mode], name))

        # if we don't have items added, we remove the address
        if not has_items:
            result.pop()
    return result

def iter_signals_with_mode(sigs, mode_list):
    """
    return an iterator over sigs where sig.mode is in mode_list
    """
    return filter(lambda sig: sig.mode in mode_list, sigs)

def _format_read_only(regs):
    """
    Needed are read-only signals and their corresponding register names
    """
    string = "{:39} <= {};"
    result = []
    for reg_name, sigs in regs.items():
        # just iterate over read-only signals
        for sig in iter_signals_with_mode(sigs, ['ro']):
            reg_slice = _reg_name(reg_name) + str(sig.position)
            result.append(string.format(reg_slice, _port_name(sig)))

    return result

def _format_register_out(validate, regs):
    """
    - validate: a list with all validated register names
    - regs: a dictionary with register name as key and a list of signals as values
    """
    string = "{reg:25} AND {mask} WHEN {addr},"
    result = []
    for reg in validate:
        string_dic = {"reg":_reg_name(reg), "addr":_addr_name(reg)}
        mask = 0
        for sig in iter_signals_with_mode(regs[reg], ['ro', 'c', 'rw']):
            mask |= _mask_from_pos(sig.position)

        # add only if there are signals to read back
        if mask > 0:
            string_dic["mask"] = _format_mask(mask)
            result.append(string.format(**string_dic))
    return result

def _format_output_mapping(regs):
    """
    All registers that can be read back, but are output ports need to be mapped
    here. Currently these are signals with mode 'c' and 'rw'.
    This will be obsolete once we decide to allow VHDL 2008, where ports with
    mode out can be read back.
    - regs: a dict with register name as key and a list of signals as value
    """
    string = "{port:25} <= {reg}{slice};"
    result = []
    for reg, sigs in regs.items():
        string_dic = {"reg":_reg_name(reg)}
        for sig in iter_signals_with_mode(sigs, ['rw', 'c']):
            string_dic["port"] = _port_name(sig)
            string_dic["slice"] = str(sig.position)
            result.append(string.format(**string_dic))

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
    addr_dic = v.addr
    _rename_addr_dict(addr_dic)
    const = _format_reg_addr(addr_dic)
    const.extend(_format_notifier_constant(v.has_read_notify))
    id_dic['TPL_CONSTANTS%'] = _join_with_indent(const, 1)

    # re-use the above visitor to also handle address validation
    valids = v.validate
    validate = _format_addr_validation(valids)
    id_dic['TPL_ADDR_VALIDATION%'] = _join_with_indent(validate, 2)

    # look at port declaration
    v = SignalVisitor()
    v.visit(tree)
    ports = _format_port_signal(v.sigs)
    ports.extend(_format_port_notify(v.notifies))
    id_dic['TPL_PORTS%'] = _join_with_indent(ports, 2)

    # look at register and signal declaration
    signals = _format_register_decl(v.regs)
    id_dic['TPL_REGISTERS%'] = _join_with_indent(signals, 1)

    # look at default values
    defaults = _format_register_default(v.sigs, v.notifies)
    id_dic['TPL_REG_DEFAULT%'] = _join_with_indent(defaults, 3)

    # look at wishbone write
    writes = _format_register_write(v.regs, valids, v.notifies)
    id_dic['TPL_REG_WR%'] = _join_with_indent(writes, 4)

    # look at wishbone read-only
    reads = _format_read_only(v.regs)
    id_dic['TPL_REG_RD%'] = _join_with_indent(reads, 3)

    # look at wishbone read back
    readout = _format_register_out(valids, v.regs)
    id_dic['TPL_REG_DATA_OUT%'] = _join_with_indent(readout, 2)

    # look at output port mapping
    mapping = _format_output_mapping(v.regs)
    id_dic['TPL_PORT_REG_OUT%'] = _join_with_indent(mapping, 1)

    # do the template substitution
    tpl = WbTemplate.from_file(tpl_file)
    with open(vhdl_file, 'w') as file:
        file.write(tpl.substitute(id_dic))

if __name__ == '__main__':
    PARSER = _setup_parser()
    ARGS = PARSER.parse_args()
    main(
        ARGS.project, ARGS.sxl_file, ARGS.sxl_block,
        ARGS.vhdl_file, ARGS.template)
