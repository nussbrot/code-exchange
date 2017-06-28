"""
This module can be used to extract the size of the blocks in an SXL file
@author: rhallmen
@date: 24.06.2017
"""

from antlr4 import *
from sxlLexer import sxlLexer
from sxlParser import sxlParser
from sxlVisitor import sxlVisitor

class BlockSizeVisitor(sxlVisitor):
    """
    Parse a sxl file and return a dict of all block sizes.
    If a block does not have the size tag, the maximum register address
    is used to estimate an lower bound for the size.
    """

    def __init__(self):
        self.dict = {}

    def _cast_hex(self, ctx):
        return int(ctx.HEX().getText(), 16)

    def visitBlock(self, ctx: sxlParser.BlockContext):
        key = ctx.LABEL().getText()
        items = ctx.block_item()
        for item in items:
            if item.size():
                value = self.visit(item.size())
                break
        else:
            raise RuntimeError("block {0} has no size attribute.".format(key))

        self.dict[key] = value

    def visitSize(self, ctx: sxlParser.SizeContext):
        return self._cast_hex(ctx)

    def visitAddress(self, ctx: sxlParser.AddressContext):
        return self._cast_hex(ctx)

    @classmethod
    def parse_file(cls, path):
        inp = FileStream(path)
        lexer = sxlLexer(inp)
        stream = CommonTokenStream(lexer)
        parser = sxlParser(stream)
        tree = parser.blocks()
        visitor = cls()
        visitor.visit(tree)
        return visitor
