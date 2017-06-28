"""
@author: rhallmen
@date: 24.06.2017
"""

from antlr4 import *
from sxlLexer import sxlLexer
from sxlParser import sxlParser
from sxlVisitor import sxlVisitor

class Signal(object):
    def __init__(self):
        self.position = None
        self.mode = None
        self.isInput = None
        self.reset = None

    def check(self):
        """After parsing all attributes must have values.
        check is a helper to facilitate this checking.
        If no reset is given, the assumption of reset = 0 is made.
        """
        assert self.position is not None
        assert self.mode is not None
        assert self.isInput is not None
        if self.reset is None:
            self.reset = 0


class Position(object):
    def __init__(self, isRange: bool, left: int, right: int = None):
        assert isRange is not None
        assert left is not None

        self.isRange = isRange
        self.left = left
        self.right = left # intentional. len() will always work this way
        if isRange:
            assert left > right
            self.right = right

    def __str__(self):
        if self.isRange:
            return "({} DOWNTO {})".format(self.left, self.right)

        return "({})".format(self.left)

    def decl(self):
        if self.isRange:
            return "({} DOWNTO 0)".format(self.left-self.right)

        return "({})".format(self.left)
    
    def __len__(self):
        return self.left - self.right + 1

class SignalVisitor(sxlVisitor):
    """
    Parse a sxl file with focus on getting information on signals.
    """

    def __init__(self):
        self.sigs = {}
        self.notifies = {}
        self.regs = {}
        self._current_reg = None
        self._current_sig = None

    def visitRegister(self, ctx: sxlParser.RegisterContext):
        key = ctx.LABEL().getText()
        self.regs[key] = []
        self._current_reg = self.regs[key]
        self.visitChildren(ctx)

    def visitSignal(self, ctx: sxlParser.SignalContext):
        key = ctx.LABEL().getText()
        self.sigs[key] = Signal()
        self._current_sig = self.sigs[key]
        self.visitChildren(ctx)
        self._current_sig.check()
        self._current_reg.append(self._current_sig)

    def visitSigPosition(self, ctx: sxlParser.SigPositionContext):
        self.visit(ctx.position())

    def visitPosSingle(self, ctx: sxlParser.PosSingleContext):
        val = int(ctx.getText())
        pos = Position(False, val)
        self._current_sig.position = pos

    def visitPosRange(self, ctx: sxlParser.PosRangeContext):
        left, right = ctx.getText().split(':')
        pos = Position(True, int(left), int(right))
        self._current_sig.position = pos

    def visitSigmode(self, ctx: sxlParser.SigmodeContext):
        mode = ctx.key.text
        if mode in ['rw', 'wo']:
            isInput = False
        else:
            isInput = True
        self._current_sig.mode = mode
        self._current_sig.isInput = isInput

    def visitResetInt(self, ctx: sxlParser.ResetIntContext):
        self._current_sig.reset = int(ctx.getText())

    def visitResetHex(self, ctx: sxlParser.ResetHexContext):
        self._current_sig.reset = int(ctx.getText(), 16)

    def visitRegNotify(self, ctx: sxlParser.RegNotifyContext):
        notify = self.visit(ctx.notify())
        key = ctx.parentCtx.LABEL().getText()
        self.notifies[key] = notify

    def visitNotify(self, ctx: sxlParser.NotifyContext):
        return ctx.key.text

    @classmethod
    def parse_file(cls, path):
        """Parse SXL file and return visitor."""
        inp = FileStream(path)
        lexer = sxlLexer(inp)
        stream = CommonTokenStream(lexer)
        parser = sxlParser(stream)
        tree = parser.blocks()
        visitor = cls()
        visitor.visit(tree)
        return visitor
