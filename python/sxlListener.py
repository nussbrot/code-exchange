# Generated from sxl.g4 by ANTLR 4.7
from antlr4 import *
if __name__ is not None and "." in __name__:
    from .sxlParser import sxlParser
else:
    from sxlParser import sxlParser

# This class defines a complete listener for a parse tree produced by sxlParser.
class sxlListener(ParseTreeListener):

    # Enter a parse tree produced by sxlParser#sxl_file.
    def enterSxl_file(self, ctx:sxlParser.Sxl_fileContext):
        pass

    # Exit a parse tree produced by sxlParser#sxl_file.
    def exitSxl_file(self, ctx:sxlParser.Sxl_fileContext):
        pass


    # Enter a parse tree produced by sxlParser#import_statement.
    def enterImport_statement(self, ctx:sxlParser.Import_statementContext):
        pass

    # Exit a parse tree produced by sxlParser#import_statement.
    def exitImport_statement(self, ctx:sxlParser.Import_statementContext):
        pass


    # Enter a parse tree produced by sxlParser#blocks.
    def enterBlocks(self, ctx:sxlParser.BlocksContext):
        pass

    # Exit a parse tree produced by sxlParser#blocks.
    def exitBlocks(self, ctx:sxlParser.BlocksContext):
        pass


    # Enter a parse tree produced by sxlParser#block.
    def enterBlock(self, ctx:sxlParser.BlockContext):
        pass

    # Exit a parse tree produced by sxlParser#block.
    def exitBlock(self, ctx:sxlParser.BlockContext):
        pass


    # Enter a parse tree produced by sxlParser#block_item.
    def enterBlock_item(self, ctx:sxlParser.Block_itemContext):
        pass

    # Exit a parse tree produced by sxlParser#block_item.
    def exitBlock_item(self, ctx:sxlParser.Block_itemContext):
        pass


    # Enter a parse tree produced by sxlParser#registers.
    def enterRegisters(self, ctx:sxlParser.RegistersContext):
        pass

    # Exit a parse tree produced by sxlParser#registers.
    def exitRegisters(self, ctx:sxlParser.RegistersContext):
        pass


    # Enter a parse tree produced by sxlParser#register.
    def enterRegister(self, ctx:sxlParser.RegisterContext):
        pass

    # Exit a parse tree produced by sxlParser#register.
    def exitRegister(self, ctx:sxlParser.RegisterContext):
        pass


    # Enter a parse tree produced by sxlParser#regDescription.
    def enterRegDescription(self, ctx:sxlParser.RegDescriptionContext):
        pass

    # Exit a parse tree produced by sxlParser#regDescription.
    def exitRegDescription(self, ctx:sxlParser.RegDescriptionContext):
        pass


    # Enter a parse tree produced by sxlParser#regAddr.
    def enterRegAddr(self, ctx:sxlParser.RegAddrContext):
        pass

    # Exit a parse tree produced by sxlParser#regAddr.
    def exitRegAddr(self, ctx:sxlParser.RegAddrContext):
        pass


    # Enter a parse tree produced by sxlParser#regSignals.
    def enterRegSignals(self, ctx:sxlParser.RegSignalsContext):
        pass

    # Exit a parse tree produced by sxlParser#regSignals.
    def exitRegSignals(self, ctx:sxlParser.RegSignalsContext):
        pass


    # Enter a parse tree produced by sxlParser#regNotify.
    def enterRegNotify(self, ctx:sxlParser.RegNotifyContext):
        pass

    # Exit a parse tree produced by sxlParser#regNotify.
    def exitRegNotify(self, ctx:sxlParser.RegNotifyContext):
        pass


    # Enter a parse tree produced by sxlParser#signals.
    def enterSignals(self, ctx:sxlParser.SignalsContext):
        pass

    # Exit a parse tree produced by sxlParser#signals.
    def exitSignals(self, ctx:sxlParser.SignalsContext):
        pass


    # Enter a parse tree produced by sxlParser#signal.
    def enterSignal(self, ctx:sxlParser.SignalContext):
        pass

    # Exit a parse tree produced by sxlParser#signal.
    def exitSignal(self, ctx:sxlParser.SignalContext):
        pass


    # Enter a parse tree produced by sxlParser#dontcare.
    def enterDontcare(self, ctx:sxlParser.DontcareContext):
        pass

    # Exit a parse tree produced by sxlParser#dontcare.
    def exitDontcare(self, ctx:sxlParser.DontcareContext):
        pass


    # Enter a parse tree produced by sxlParser#sigPosition.
    def enterSigPosition(self, ctx:sxlParser.SigPositionContext):
        pass

    # Exit a parse tree produced by sxlParser#sigPosition.
    def exitSigPosition(self, ctx:sxlParser.SigPositionContext):
        pass


    # Enter a parse tree produced by sxlParser#sigMode.
    def enterSigMode(self, ctx:sxlParser.SigModeContext):
        pass

    # Exit a parse tree produced by sxlParser#sigMode.
    def exitSigMode(self, ctx:sxlParser.SigModeContext):
        pass


    # Enter a parse tree produced by sxlParser#sigReset.
    def enterSigReset(self, ctx:sxlParser.SigResetContext):
        pass

    # Exit a parse tree produced by sxlParser#sigReset.
    def exitSigReset(self, ctx:sxlParser.SigResetContext):
        pass


    # Enter a parse tree produced by sxlParser#enumeration.
    def enterEnumeration(self, ctx:sxlParser.EnumerationContext):
        pass

    # Exit a parse tree produced by sxlParser#enumeration.
    def exitEnumeration(self, ctx:sxlParser.EnumerationContext):
        pass


    # Enter a parse tree produced by sxlParser#enum_item.
    def enterEnum_item(self, ctx:sxlParser.Enum_itemContext):
        pass

    # Exit a parse tree produced by sxlParser#enum_item.
    def exitEnum_item(self, ctx:sxlParser.Enum_itemContext):
        pass


    # Enter a parse tree produced by sxlParser#description.
    def enterDescription(self, ctx:sxlParser.DescriptionContext):
        pass

    # Exit a parse tree produced by sxlParser#description.
    def exitDescription(self, ctx:sxlParser.DescriptionContext):
        pass


    # Enter a parse tree produced by sxlParser#address.
    def enterAddress(self, ctx:sxlParser.AddressContext):
        pass

    # Exit a parse tree produced by sxlParser#address.
    def exitAddress(self, ctx:sxlParser.AddressContext):
        pass


    # Enter a parse tree produced by sxlParser#size.
    def enterSize(self, ctx:sxlParser.SizeContext):
        pass

    # Exit a parse tree produced by sxlParser#size.
    def exitSize(self, ctx:sxlParser.SizeContext):
        pass


    # Enter a parse tree produced by sxlParser#value.
    def enterValue(self, ctx:sxlParser.ValueContext):
        pass

    # Exit a parse tree produced by sxlParser#value.
    def exitValue(self, ctx:sxlParser.ValueContext):
        pass


    # Enter a parse tree produced by sxlParser#notify.
    def enterNotify(self, ctx:sxlParser.NotifyContext):
        pass

    # Exit a parse tree produced by sxlParser#notify.
    def exitNotify(self, ctx:sxlParser.NotifyContext):
        pass


    # Enter a parse tree produced by sxlParser#unit.
    def enterUnit(self, ctx:sxlParser.UnitContext):
        pass

    # Exit a parse tree produced by sxlParser#unit.
    def exitUnit(self, ctx:sxlParser.UnitContext):
        pass


    # Enter a parse tree produced by sxlParser#unit_value.
    def enterUnit_value(self, ctx:sxlParser.Unit_valueContext):
        pass

    # Exit a parse tree produced by sxlParser#unit_value.
    def exitUnit_value(self, ctx:sxlParser.Unit_valueContext):
        pass


    # Enter a parse tree produced by sxlParser#numrep.
    def enterNumrep(self, ctx:sxlParser.NumrepContext):
        pass

    # Exit a parse tree produced by sxlParser#numrep.
    def exitNumrep(self, ctx:sxlParser.NumrepContext):
        pass


    # Enter a parse tree produced by sxlParser#numrep_value.
    def enterNumrep_value(self, ctx:sxlParser.Numrep_valueContext):
        pass

    # Exit a parse tree produced by sxlParser#numrep_value.
    def exitNumrep_value(self, ctx:sxlParser.Numrep_valueContext):
        pass


    # Enter a parse tree produced by sxlParser#range_item.
    def enterRange_item(self, ctx:sxlParser.Range_itemContext):
        pass

    # Exit a parse tree produced by sxlParser#range_item.
    def exitRange_item(self, ctx:sxlParser.Range_itemContext):
        pass


    # Enter a parse tree produced by sxlParser#range_value.
    def enterRange_value(self, ctx:sxlParser.Range_valueContext):
        pass

    # Exit a parse tree produced by sxlParser#range_value.
    def exitRange_value(self, ctx:sxlParser.Range_valueContext):
        pass


    # Enter a parse tree produced by sxlParser#position.
    def enterPosition(self, ctx:sxlParser.PositionContext):
        pass

    # Exit a parse tree produced by sxlParser#position.
    def exitPosition(self, ctx:sxlParser.PositionContext):
        pass


    # Enter a parse tree produced by sxlParser#posSingle.
    def enterPosSingle(self, ctx:sxlParser.PosSingleContext):
        pass

    # Exit a parse tree produced by sxlParser#posSingle.
    def exitPosSingle(self, ctx:sxlParser.PosSingleContext):
        pass


    # Enter a parse tree produced by sxlParser#posRange.
    def enterPosRange(self, ctx:sxlParser.PosRangeContext):
        pass

    # Exit a parse tree produced by sxlParser#posRange.
    def exitPosRange(self, ctx:sxlParser.PosRangeContext):
        pass


    # Enter a parse tree produced by sxlParser#sigmode.
    def enterSigmode(self, ctx:sxlParser.SigmodeContext):
        pass

    # Exit a parse tree produced by sxlParser#sigmode.
    def exitSigmode(self, ctx:sxlParser.SigmodeContext):
        pass


    # Enter a parse tree produced by sxlParser#resetval.
    def enterResetval(self, ctx:sxlParser.ResetvalContext):
        pass

    # Exit a parse tree produced by sxlParser#resetval.
    def exitResetval(self, ctx:sxlParser.ResetvalContext):
        pass


    # Enter a parse tree produced by sxlParser#resetInt.
    def enterResetInt(self, ctx:sxlParser.ResetIntContext):
        pass

    # Exit a parse tree produced by sxlParser#resetInt.
    def exitResetInt(self, ctx:sxlParser.ResetIntContext):
        pass


    # Enter a parse tree produced by sxlParser#resetHex.
    def enterResetHex(self, ctx:sxlParser.ResetHexContext):
        pass

    # Exit a parse tree produced by sxlParser#resetHex.
    def exitResetHex(self, ctx:sxlParser.ResetHexContext):
        pass


    # Enter a parse tree produced by sxlParser#type_item.
    def enterType_item(self, ctx:sxlParser.Type_itemContext):
        pass

    # Exit a parse tree produced by sxlParser#type_item.
    def exitType_item(self, ctx:sxlParser.Type_itemContext):
        pass


    # Enter a parse tree produced by sxlParser#type_val.
    def enterType_val(self, ctx:sxlParser.Type_valContext):
        pass

    # Exit a parse tree produced by sxlParser#type_val.
    def exitType_val(self, ctx:sxlParser.Type_valContext):
        pass


