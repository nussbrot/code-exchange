# Generated from sxl.g4 by ANTLR 4.7
from antlr4 import *
if __name__ is not None and "." in __name__:
    from .sxlParser import sxlParser
else:
    from sxlParser import sxlParser

# This class defines a complete generic visitor for a parse tree produced by sxlParser.

class sxlVisitor(ParseTreeVisitor):

    # Visit a parse tree produced by sxlParser#sxl_file.
    def visitSxl_file(self, ctx:sxlParser.Sxl_fileContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#import_statement.
    def visitImport_statement(self, ctx:sxlParser.Import_statementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#blocks.
    def visitBlocks(self, ctx:sxlParser.BlocksContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#block.
    def visitBlock(self, ctx:sxlParser.BlockContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#block_item.
    def visitBlock_item(self, ctx:sxlParser.Block_itemContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#registers.
    def visitRegisters(self, ctx:sxlParser.RegistersContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#register.
    def visitRegister(self, ctx:sxlParser.RegisterContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#regDescription.
    def visitRegDescription(self, ctx:sxlParser.RegDescriptionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#regAddr.
    def visitRegAddr(self, ctx:sxlParser.RegAddrContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#regSignals.
    def visitRegSignals(self, ctx:sxlParser.RegSignalsContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#regNotify.
    def visitRegNotify(self, ctx:sxlParser.RegNotifyContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#signals.
    def visitSignals(self, ctx:sxlParser.SignalsContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#signal.
    def visitSignal(self, ctx:sxlParser.SignalContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#dontcare.
    def visitDontcare(self, ctx:sxlParser.DontcareContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#sigPosition.
    def visitSigPosition(self, ctx:sxlParser.SigPositionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#sigMode.
    def visitSigMode(self, ctx:sxlParser.SigModeContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#sigReset.
    def visitSigReset(self, ctx:sxlParser.SigResetContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#enumeration.
    def visitEnumeration(self, ctx:sxlParser.EnumerationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#enum_item.
    def visitEnum_item(self, ctx:sxlParser.Enum_itemContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#description.
    def visitDescription(self, ctx:sxlParser.DescriptionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#address.
    def visitAddress(self, ctx:sxlParser.AddressContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#size.
    def visitSize(self, ctx:sxlParser.SizeContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#value.
    def visitValue(self, ctx:sxlParser.ValueContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#notify.
    def visitNotify(self, ctx:sxlParser.NotifyContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#unit.
    def visitUnit(self, ctx:sxlParser.UnitContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#unit_value.
    def visitUnit_value(self, ctx:sxlParser.Unit_valueContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#numrep.
    def visitNumrep(self, ctx:sxlParser.NumrepContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#numrep_value.
    def visitNumrep_value(self, ctx:sxlParser.Numrep_valueContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#range_item.
    def visitRange_item(self, ctx:sxlParser.Range_itemContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#range_value.
    def visitRange_value(self, ctx:sxlParser.Range_valueContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#position.
    def visitPosition(self, ctx:sxlParser.PositionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#posSingle.
    def visitPosSingle(self, ctx:sxlParser.PosSingleContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#posRange.
    def visitPosRange(self, ctx:sxlParser.PosRangeContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#sigmode.
    def visitSigmode(self, ctx:sxlParser.SigmodeContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#resetval.
    def visitResetval(self, ctx:sxlParser.ResetvalContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#resetInt.
    def visitResetInt(self, ctx:sxlParser.ResetIntContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#resetHex.
    def visitResetHex(self, ctx:sxlParser.ResetHexContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#type_item.
    def visitType_item(self, ctx:sxlParser.Type_itemContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by sxlParser#type_val.
    def visitType_val(self, ctx:sxlParser.Type_valContext):
        return self.visitChildren(ctx)



del sxlParser