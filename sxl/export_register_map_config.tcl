package require sxl
package provide export_register_map_config 1.0



namespace eval export_register_map_config {

    #--------------------------------------------
    #   helper functions
    #--------------------------------------------
    proc convNameUpper {name} {
        return [string trimleft [string toupper $name]]
    }

    proc convFix88ToBit {value} {
        set mul [expr {$value * 256}]
        set bitsInHex [format 0x%04x [expr {int($mul)}]]
        return $bitsInHex
    }

    proc convFix1616ToBit {value} {
        set mul [expr {$value * 65536}]
        set bitsInHex [format 0x%08x [expr {int($mul)}]]
        return $bitsInHex
    }

    #--------------------------------------------
    #   entry point
    #--------------------------------------------
    proc generate_config {sxlFile cRuntimeParameter mstName } {
        #open file input
        set inFileId [open $sxlFile r]
        #open file output

        set headerFileExt ".h"
        set sourceFileExt ".c"
        set rangemapFileExt "RangeMap.c"
        set headerFileName $cRuntimeParameter$headerFileExt
        set sourceFileName $cRuntimeParameter$sourceFileExt
        set rangemapFileName $cRuntimeParameter$rangemapFileExt

        # call all generater functions
        set headerFileId [open $headerFileName w]
        set sourceFileId [open $sourceFileName w]
        set rangemapFileId [open $rangemapFileName w]

        genHeader $sxlFile $mstName $headerFileId
        genSoure $sxlFile $mstName $sourceFileId
        genRangeMap $sxlFile $mstName $rangemapFileId
    }

    #--------------------------------------------
    #   source generator
    #--------------------------------------------
    proc genSoure {sxlFile mstName sourceFileId} {
        set outFileHeader "

        #include \"RuntimeParameter.h

uint32_t RuntimeParameter_GetSignal(RuntimeSignal_t a_runtimeSignal)
{

}
void RuntimeParameter_SetSignal(RuntimeSignal_t a_runtimeSignal, uint32_t a_value)
{

}
uint32_t RuntimeParameter_RegisterFunction(RuntimeSignal_t a_runtimeSignal, RuntimeFuncptr_t a_runtimeFuncptr)
{

}"

    puts $sourceFileId $outFileHeader
    }


    #--------------------------------------------
    #   header generator
    #--------------------------------------------
    proc genHeader {sxlFile mstName headerFileId} {
        set regList {}
        set outFileHeader "
/*
 * SpiDatalinkRM_Config.c
 * auto generated from sxl
 */

#include <stdint.h>

#ifndef INCLUDE_GUARD_H
#define INCLUDE_GUARD_H

#define RP_READ_ONLY 0xFFFFFFFFU

typedef void (*RuntimeFuncptr_t)(uint32_t a_address, uint32_t a_data);

typedef enum
\{
    TYPE_UINT8,
    TYPE_SINT8,
    TYPE_UFIX8_8,
    TYPE_SFIX8_8,
    TYPE_UINT16,
    TYPE_SINT16,
    TYPE_UFIX16_16,
    TYPE_SFIX16_16,
    TYPE_UINT32,
    TYPE_SINT32,
    TYPE_ENUM,
    TYPE_BOOL,
    TYPE_RAW
\} Numrep_t;

typedef struct
\{
    uint8_t addr;
    uint8_t shift;
    uint32_t begin;
    uint32_t end;
    uint32_t mask;
    Numrep_t numrep;
\} SpiRegisterMapConfig_t;

typedef struct
\{
    uint32_t baseAddress;
\} RuntimeParameter_t;

extern SpiRegisterMapConfig_t g_RegisterMapConfig\[\];

typedef enum
\{"
    puts $headerFileId $outFileHeader

    set blockToParse "WbsSpiDatalinkRmsMem"
    # init sxl
        if {[catch {::sxl::sxl_init} result]} {
            error $result
            return
        }
        # read sxl file
        if {[catch {::sxl::fileIO::readFile $sxlFile} result]} {
            error $result
            return
        }

        # Sort Slaves
        set slaveList {}
        set slaveList [get_sxl_slavelist [string tolower $mstName]]
        set slaveList [lsort -integer -index 1 $slaveList]

       # puts $rangemapFileId [join $slaveList \n]

        # every block
        foreach {slaveName slaveAddr} [join $slaveList] {
            #puts $rangemapFileId "$slaveName"

            set blockName [::sxl::parameter get $slaveName.block]
            #set blockAddr $slaveAddr
            #puts $rangemapFileId "$blockName"

            # block WbsSpiDatalinkRm OR no registers or block does not exist
            if {$blockName != "$blockToParse" || ![info exists ::sxl::cfg::regs($blockName)]} {
                continue
            }

            # here we have only the block WbsSpiDatalinkRm
            #puts $rangemapFileId "$blockName"

            # get all defined registers in sxl file
            foreach reg [::sxl::register list $blockName] {
                set regName [lindex [split $reg .] end]
                set regAddr [expr [::sxl::parameter get $reg.addr]]
                lappend regList [list $regName $regAddr]
            }
            #puts $rangemapFileId $regList

            set sigMask 0
            foreach {regName regAddr} [join $regList] {
                #puts $rangemapFileId $regAddr
                #puts $rangemapFileId $expectedRegAddr

                #get every signal
                if {[info exists ::sxl::cfg::sigs($blockName,$regName)]} {
                    # handle all signals of a register, sort by signal position
                    foreach sig $::sxl::cfg::sigs($blockName,$regName) {
                        set sigName [lindex [split $sig .] end]
                        if {"$sigName" == "$regName"} {
                            set signal [convNameUpper "$sigName,"]
                            puts $headerFileId "    SIG_$signal"
                        } else {
                            set registerAndSignal [convNameUpper "$regName\_$sigName,"]
                            puts $headerFileId "    SIG_$registerAndSignal"
                        }
                     }


                }
            }
        }

    puts $headerFileId "\} RuntimeSignal_t;

typedef enum
\{"

    foreach {regName regAddr} [join $regList] {
        puts $headerFileId "    [convNameUpper REG_$regName],"
    }

    puts $headerFileId "\} RuntimeRegister_t;\n"
    puts $headerFileId "#endif /* INCLUDE_GUARD_H */"
    }


    #--------------------------------------------
    #   range map generator
    #--------------------------------------------
    proc genRangeMap {sxlFile mstName rangemapFileId} {

        set blockToParse "WbsSpiDatalinkRmsMem"

        set outFileHeader "
/*
 * SpiDatalinkRM_Config.c
 * auto generated from sxl
 */

#include \"RuntimeParameter.h

SpiRegisterMapConfig_t g_RegisterMapConfig\[\] = {
    /* {Addr, Shift, Begin, End, Mask, Numrep},  SignalName */"

        # write out file header
        puts $rangemapFileId $outFileHeader

        # init sxl
        if {[catch {::sxl::sxl_init} result]} {
            error $result
            return
        }
        # read sxl file
        if {[catch {::sxl::fileIO::readFile $sxlFile} result]} {
            error $result
            return
        }

        # Sort Slaves
        set slaveList {}
        set slaveList [get_sxl_slavelist [string tolower $mstName]]
        set slaveList [lsort -integer -index 1 $slaveList]

       # puts $rangemapFileId [join $slaveList \n]

        # every block
        foreach {slaveName slaveAddr} [join $slaveList] {
            #puts $rangemapFileId "$slaveName"

            set blockName [::sxl::parameter get $slaveName.block]
            #set blockAddr $slaveAddr
            #puts $rangemapFileId "$blockName"

            # block WbsSpiDatalinkRm OR no registers or block does not exist
            if {$blockName != "$blockToParse" || ![info exists ::sxl::cfg::regs($blockName)]} {
                continue
            }

            # here we have only the block WbsSpiDatalinkRm
            #puts $rangemapFileId "$blockName"

            # get all defined registers in sxl file
            foreach reg [::sxl::register list $blockName] {
                set regName [lindex [split $reg .] end]
                set regAddr [expr [::sxl::parameter get $reg.addr]]
                lappend regList [list $regName $regAddr]
            }
            #puts $rangemapFileId $regList

            set sigMask 0
            foreach {regName regAddr} [join $regList] {
                #puts $rangemapFileId $regAddr
                #puts $rangemapFileId $expectedRegAddr

                #get every signal
                if {[info exists ::sxl::cfg::sigs($blockName,$regName)]} {
                    # handle all signals of a register, sort by signal position
                    foreach sig $::sxl::cfg::sigs($blockName,$regName) {
                        set sigName [lindex [split $sig .] end]
                        set sigRange [::sxl::parameter get $blockName.$regName.$sig.range]
                        set sigPos  [split [::sxl::parameter get $blockName.$regName.$sig.pos] :]
                        set sigMode [::sxl::parameter get $blockName.$regName.$sig.mode]
                        set sigNumrep "TYPE_"
                        append sigNumrep [::sxl::parameter get $blockName.$regName.$sig.numrep]
                        #replace . with _ and store result to sigNumrep
                        regsub -all \\. $sigNumrep "_" sigNumrep
                        set sigNumrep [convNameUpper $sigNumrep]

                        if {"$sigMode" == "ro"} {
                            set sigRange "RP_READ_ONLY:RP_READ_ONLY"
                        }
                        set sigRangeMin [lindex [split $sigRange :] 0]
                        set sigRangeMax [lindex [split $sigRange :] 1]
                        # next line is only filled with a value when we have a notation like -38:2:38
                        set sigRangeEnd [lindex [split $sigRange :] 2]
                        if {"$sigRangeEnd" != ""} {
                            set sigRangeMax $sigRangeEnd
                        }

                        if {"$sigRangeMin" == "?"} {
                            # set to minimum
                            if {"$sigNumrep" == "TYPE_SINT32"} {
                                set sigRangeMin "0x80000000"
                        }
                        } else {
                            if {"$sigMode" != "ro" && "$sigRangeMin" != ""} {
                                if {"$sigNumrep" == "TYPE_UFIX8_8" || "$sigNumrep" == "TYPE_SFIX8_8"} {
                                    set sigRangeMin [convFix88ToBit $sigRangeMin]
                                }
                                if {"$sigNumrep" == "TYPE_UFIX16_16" || "$sigNumrep" == "TYPE_SFIX16_16"} {
                                    set sigRangeMin [convFix1616ToBit $sigRangeMin]
                                }
                            }
                        }

                        if {"$sigRangeMax" == "?"} {
                            # set to maximum
                            if {"$sigNumrep" == "TYPE_SINT32"} {
                                set sigRangeMax "0x7fffffff"
                            }
                        } else {
                            if {"$sigMode" != "ro" && "$sigRangeMax" != ""} {
                                if {"$sigNumrep" == "TYPE_UFIX8_8" || "$sigNumrep" == "TYPE_SFIX8_8"} {
                                    set sigRangeMax [convFix88ToBit $sigRangeMax]
                                }
                                if {"$sigNumrep" == "TYPE_UFIX16_16" || "$sigNumrep" == "TYPE_SFIX16_16"} {
                                    set sigRangeMax [convFix1616ToBit $sigRangeMax]
                            }
                        }

                         if {("$sigNumrep" == "TYPE_RAW") && ("$sigMode" != "ro")} {
                            set sigRangeMin "0x0"
                            set sigRangeMax "0xFFFFFFFF"
                         }


                        }
                        #get mask from pos
                        foreach {msb lsb} $sigPos {
                            if {$lsb == ""} {
                                set lsb $msb
                            }

                            # add suffix U for unsigned
                            if {"$sigRangeMin" != "RP_READ_ONLY"} {
                                set sigRangeMin [format 0x%.8X [expr {$sigRangeMin & 0xFFFFFFFF}]]U
                            }
                            if {"$sigRangeMax" != "RP_READ_ONLY"} {
                                set sigRangeMax [format 0x%.8X [expr {$sigRangeMax & 0xFFFFFFFF}]]U
                            }

                            set sigMask [expr ((2**($msb-$lsb+1)-1) << $lsb)]
                            puts $rangemapFileId "    {0x[format %04X $regAddr]U, [format $lsb]U, $sigRangeMin, $sigRangeMax, 0x[format %08X $sigMask]U, $sigNumrep}, /* $regName\_$sigName */"
                        }
                    }
                }
            }
        }
        puts $rangemapFileId "};"
    }
}
