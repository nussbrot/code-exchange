"""
@author: rhallmen
@date: 19.06.2017
"""

from antlr4 import *
from sxlLexer import sxlLexer
from sxlParser import sxlParser
from sxlVisitor import sxlVisitor

class RegisterAddressVisitor(sxlVisitor):
    """
    Parse a sxl file and return an array of all found register addresses
    """

    def __init__(self):
        self.addr = {}
        self.validate = []
        self.has_read_notify = False
        self._current_reg = None

    def visitRegister(self, ctx: sxlParser.RegisterContext):
        """
        Inform children about the name of the current register.
        Then recurse over the children.
        """

        self._current_reg = ctx.LABEL().getText()
        num = self.visitChildren(ctx)
        # Now we know if this register has one of the register_item:
        # - notifier
        # - signals
        # The children increment there result in these cases.
        if num > 0:
            self.validate.append(self._current_reg)
        return num

    def defaultResult(self):
        """Make return type integer"""
        return 0

    def aggregateResult(self, aggregate, nextResult):
        """Default result adds the return values of all children"""
        return aggregate + nextResult

    def visitRegAddr(self, ctx: sxlParser.RegAddrContext):
        tmp = self.visit(ctx.address())
        self.addr[self._current_reg] = tmp
        return 0

    def visitAddress(self, ctx: sxlParser.AddressContext):
        return int(ctx.HEX().getText(), 16)

    def visitRegSignals(self, ctx: sxlParser.RegSignalsContext):
        """
        Just calling this rule means there is at least one register.
        Therefore we can immediately return, since this is all we need to know.
        """
        return ctx.signals().getChildCount()

    def visitRegNotify(self, ctx: sxlParser.RegNotifyContext):
        return self.visit(ctx.notify())

    def visitNotify(self, ctx: sxlParser.NotifyContext):
        """ This function serves two jobs:
        - set has_read_notify if this node is a read notification
        - return 1, because it is a notify node
        """
        token = ctx.key.text
        notify = token in ['rw', 'ro']
        self.has_read_notify = self.has_read_notify or notify
        return 1


    @classmethod
    def parse_file(cls, path):
        inp = FileStream(path)
        lexer = sxlLexer(inp)
        stream = CommonTokenStream(lexer)
        parser = sxlParser(stream)
        tree = parser.blocks()
        visitor = cls()
        visitor.visit(tree)
        return visitor.addr
