package require sxl
package require md5

package provide export_block_driver 1.0

namespace eval export_block_driver {
    variable blocks     {}
    variable slaves     {}
    variable outFolder  "c_out"

    proc registerSlave {slaveName slaveAddress} {
        variable blocks
        variable slaves

        set blockName [::sxl::parameter get $slaveName.block]

        if {$blockName != ""} {
            if {[lsearch -exact $blocks $blockName] == -1} {
                puts "Registering block: ${blockName}"

                lappend blocks $blockName
            }
        }

        set slave [list $slaveName $slaveAddress]

        if {[lsearch -exact $slaves $slave] == -1} {
            puts "Registering slave: ${slaveName} @ $slaveAddress "

            lappend slaves $slave
        }
    }

    proc createBlockDriver {blockDriverTemplate block headerFile} {
        if {[catch {open $blockDriverTemplate r} blockDriverTemplateFile]} {
            error "export_block_driver::createBlockDrivers(): Cannot open $blockDriverTemplate"
        }

        set templateText [read $blockDriverTemplateFile]

        createBlockDriverEx $templateText $block $headerFile
    }

    proc createBlockDriverEx {templateText block headerFile} {
        set registers [createRegisterList $block]
        set signals [createSignalList $block $registers]

        set blockDriverHeaderData [createFileName $templateText $block]
        set blockDriverHeaderData [createBlockVersion $blockDriverHeaderData $block]
        set blockDriverHeaderData [createRegisterOffsets $blockDriverHeaderData $block $registers]
        set blockDriverHeaderData [createRegisterDefines $blockDriverHeaderData $block $signals]
        set blockDriverHeaderData [createRegisterStruct $blockDriverHeaderData $block $signals]

        WriteIfModified $headerFile $blockDriverHeaderData
    }

    proc createBlockDrivers {blockDriverTemplate} {
        variable blocks
        variable outFolder

        if {[catch {open $blockDriverTemplate r} blockDriverTemplateFile]} {
            error "export_block_driver::createBlockDrivers(): Cannot open $blockDriverTemplate"
        }

        if {![file exists $outFolder]} {
            file mkdir $outFolder
        }

        set templateText [read $blockDriverTemplateFile]

        foreach block $blocks {
            set blockDriverHeader     [file join $outFolder ${block}.h]

            createBlockDriverEx $templateText $block $blockDriverHeader
        }
    }

    proc createSystemHeader {systemHeaderTemplate deviceName} {
        variable slaves
        variable outFolder

        if {[catch {open $systemHeaderTemplate r} systemHeaderFile]} {
            error "export_block_driver::createSystemHeader(): Cannot open $systemHeaderTemplate"
        }

        set systemHeaderName "system_header_[string tolower $deviceName]"

        set templateText [read $systemHeaderFile]
        set templateText [createFileName $templateText [convNameUpper $systemHeaderName]]

        if {![file exists $outFolder]} {
          file mkdir $outFolder
        }
        set systemHeader [file join $outFolder ${systemHeaderName}.h]

        set slaveAddressText ""
        foreach slave $slaves {
            set slaveName [convNameUpper [lindex [split [lindex $slave 0] .] end]]
            set slaveAddress [lindex $slave 1]
            set slaveAddressString "0x[format %08X ${slaveAddress}]U | SOFTCORE_WISHBONE_OFFSET"

           append slaveAddressText "\#\define [format %-40s ${slaveName}_BASE] \(${slaveAddressString}\)\n"
        }

        regsub {%TPL_MODULE_ADDRESSES%} $templateText $slaveAddressText templateText

        WriteIfModified $systemHeader $templateText
    }

    proc createBlockVersion {templateText block} {
        set blockVersion [::sxl::parameter get $block.revid]

        if {$blockVersion != ""} {
            set blockVersion [expr int($blockVersion)]

        } else {
            set blockVersion 0
        }

        set blockVersionString "0x[format %08X ${blockVersion}]U"
        # set blockVersionText "#define [convNameUpper $block]_VERSION ${blockVersionString}"
        set blockVersionText "// TODO Update version"

        regsub {%TPL_BLOCK_VERSION%} $templateText $blockVersionText templateText

        return $templateText
    }

    proc createFileName {templateText fileName} {
        regsub {%TPL_FILE%} $templateText $fileName templateText
        regsub -all {%TPL_HEADER_GUARD%} $templateText [convNameUpper $fileName] templateText

        return $templateText
    }

    proc createRegisterList {blockName} {
        set registers {}

        foreach register [::sxl::register list $blockName] {
            set registerName [lindex [split $register .] end]
            set registerAddress [expr [::sxl::parameter get $register.addr]]

            lappend registers [list $blockName $registerName $registerAddress]
        }

        set sortedRegisters [lsort -integer -index 2 $registers]

        return $sortedRegisters
    }

    proc createSignalList {blockName registers} {
        set registerSignalList {}

        foreach register $registers {
            set registerName [lindex $register 1]
            set signalList {}

            if {[info exists ::sxl::cfg::sigs($blockName,$registerName)]} {

                foreach signal $::sxl::cfg::sigs($blockName,$registerName) {
                    set signalName [lindex [split $signal .] end]

                    set signalPosition [::sxl::parameter get $blockName.$registerName.$signal.pos]
                    set positionList [split $signalPosition :]

                    set signalWidth 0
                    set signalStart 0

                    if {[llength $positionList] == 1} {
                        set signalWidth 1
                        set signalStart [lindex $positionList 0]
                    } else {
                        set signalStart [lindex $positionList 1]
                        set signalEnd [lindex $positionList 0]

                        set signalWidth [expr ($signalEnd - $signalStart) + 1]
                    }

                    set flagList {}
                    if {[info exists ::sxl::cfg::flags($blockName,$registerName,$signal)]} {
                        foreach flag $::sxl::cfg::flags($blockName,$registerName,$signal) {
                            set flagPosition [::sxl::parameter get $blockName.$registerName.$signal.$flag.pos]
                            lappend flagList  [list $flag $flagPosition]
                        }
                    }

                    lappend signalList [list $signalName $signalStart $signalWidth $flagList]

                }
            } else {
                puts "Empty register: ${registerName}"
            }

            set sortedSignalList [lsort -integer -index 1 $signalList]

            lappend registerSignalList [list $registerName $sortedSignalList]
        }

        return $registerSignalList
    }

    proc createRegisterOffsets {templateText blockName registers} {
        set registerOffsetText ""

        foreach register $registers {
            set blockName [convNameUpper [lindex $register 0]]
            set registerName [convNameUpper [lindex $register 1]]
            set address [lindex $register 2]

            set offsetName "${blockName}_${registerName}_OFFSET"

            append registerOffsetText "\#\define [format %-40s ${offsetName}] \(0x[format %08X ${address}]U\)\n"
        }

        regsub {%TPL_REGISTER_OFFSETS%} $templateText $registerOffsetText templateText

        return $templateText
    }

    proc createRegisterDefines {templateText blockName registerSignals} {
        set registerDefineText ""

        foreach registerSignal $registerSignals {
            set registerName [lindex $registerSignal 0]
            set registerNameU [convNameUpper $registerName]
            set signals [lindex $registerSignal 1]

            set partName [convNameUpper "${blockName}_${registerNameU}"]

            # set macroName ""
            # set registerWidth 0

            # set regType [string toupper [::sxl::parameter get $blockName.$registerName.type]]
            # if {$regType == "BYTE"} {
                # set macroName "__IO_REG8_BIT"
                # set registerWidth 8
            # } elseif {$regType == "WORD"} {
                # set macroName "__IO_REG16_BIT"
                # set registerWidth 16
            # } else {
                set macroName "__IO_REG32_BIT"
                set registerWidth 32
            # }

            append registerDefineText [createSignalStruct $signals $partName $registerWidth]
            append registerDefineText "${macroName}(${partName}, ${partName}_bits);\n\n"

            set offsetName "${partName}_OFFSET"
            set address "((uint32_t)base + ${offsetName})"

            append registerDefineText "#define ${partName}_REG(base) \\\n    LINT_SUPPRESS_CAST \\\n    (*(__IO ${partName}_type*)${address}) \\\n     LINT_RESTORE\n"
            append registerDefineText "#define ${partName}(base) \\\n    LINT_SUPPRESS_CAST \\\n    (*(__IO ${partName}_type*)${address}).RAW \\\n    LINT_RESTORE\n"
            append registerDefineText "#define ${partName}_bit(base) \\\n    LINT_SUPPRESS_CAST \\\n    (*(__IO ${partName}_type*)${address}).BITS \\\n    LINT_RESTORE\n\n"
        }

        regsub {%TPL_SIGNAL_STRUCTS%} $templateText $registerDefineText templateText

        return $templateText
    }

    proc createSignalStruct {signals structName registerWidth} {
        set signalStructText ""

        append signalStructTextStruct "typedef struct COMPILER_ATTRIBUTE(packed) \{\n"

        set signalDict [dict create]

        set lastSignalEnd 0
        set widthSum 0

        set lines {}
        set lineCounter 0
        set bitfieldType "Bitfield_t"

        foreach signal $signals {
            set signalName [convNameUpper [lindex $signal 0]]
            set signalStart [lindex $signal 1]
            set signalWidth [lindex $signal 2]
            set flagList [convNameUpper [lindex $signal 3]]


            set startDifference [expr $signalStart - $lastSignalEnd]

            if {$startDifference >= 0} {
                if {$startDifference > 0} {
                    lappend lines "    __IO ${bitfieldType} : ${startDifference};\n"
                    set widthSum [expr $widthSum + $startDifference]

                    set lineCounter [expr $lineCounter + 1]
                }

                set lastSignalEnd [expr $signalStart + $signalWidth]

                lappend lines "    __IO ${bitfieldType} ${signalName} : ${signalWidth};\n"

                # only write signalname when struct name does not contain the signalname
                if {[string match *$signalName* $structName]} {
                    append signalStructText "#define ${structName}_LENGTH (${signalWidth}U)\n"
                } else {
                    append signalStructText "#define ${structName}_${signalName}_LENGTH (${signalWidth}U)\n"
                }


                foreach flag $flagList {
                    set flagName [lindex $flag 0]
                    set flagPos [lindex $flag 1]

                    set splitLine [split $flagPos ":"]
                    set flagPosEnd [lindex $splitLine 0]
                    set flagPosStart [lindex $splitLine 1]

                    set mask 1
                    set smaller $flagPosEnd
                    if { $flagPosStart != "" && $flagPosStart < $flagPosEnd } {
                        set smaller $flagPosStart
                        set mask 0x[format %08X [expr {(1 << ($flagPosEnd - $flagPosStart + 1))-1}]]
                    }

                    # only write signalname when struct name does not contain the signalname
                    if {[string match *$signalName* $structName]} {
                        append signalStructText "#define ${structName}_${flagName} (${mask}UL << ${smaller}UL)\n"
                    } else {
                        append signalStructText "#define ${structName}_${signalName}_${flagName} (${mask}UL << ${smaller}UL)\n"
                    }
                }

                set widthSum [expr $widthSum + $signalWidth]

                set lineCounter [expr $lineCounter + 1]
            } else {
                set lastLineIndex [expr $lineCounter - 1]
                set lastLine [lindex $lines $lastLineIndex]

                set splitLine [split $lastLine ":"]
                set firstPart [string trimright [lindex $splitLine 0]]
                set secondPart [string trimleft [lindex $splitLine 1]]

                set newLine "${firstPart}_${signalName} : ${secondPart}"

                set lines [lreplace $lines $lastLineIndex $lastLineIndex $newLine]
            }
        }

        foreach line $lines {
            append signalStructTextStruct $line
        }

        if {$widthSum != $registerWidth} {
            set widthDifference [expr $registerWidth - $widthSum]
            append signalStructTextStruct "    __IO ${bitfieldType} : ${widthDifference};\n"
        }

        append signalStructTextStruct "\} ${structName}_bits;\n\n"

        append signalStructText $signalStructTextStruct

        return $signalStructText
    }

    proc createRegisterStruct {templateText blockName signals} {
        set blockNameU [convNameUpper "${blockName}"]

        set blockRegisterText ""
        append blockRegisterText "typedef struct COMPILER_ATTRIBUTE(packed) \{\n"

        foreach signal $signals {
            set registerName [lindex $signal 0]
            set registerNameU [convNameUpper $registerName]

            append blockRegisterText "    __IO ${blockNameU}_${registerNameU}_bits ${registerNameU};\n"
        }

        append blockRegisterText "\} ${blockNameU}_type;\n\n"
        append blockRegisterText "#define ${blockNameU}_REG(base) (*(__IO ${blockNameU}_type*)base)\n"

        # regsub {%TPL_REGISTER_STRUCT} $templateText $blockRegisterText templateText
        regsub {%TPL_REGISTER_STRUCT%} $templateText "" templateText

        return $templateText
    }

    proc convNameUpper {name} {
        return [string trimleft [string toupper $name]]
    }

    proc WriteIfModified {filePath data} {
        set fileData ""

        if {[catch {open $filePath r} fileHandle] == 0} {
            set fileData [read $fileHandle]
            close $fileHandle
        }

        set fileChecksum [md5::md5 -hex $fileData]
        set dataChecksum [md5::md5 -hex $data]

        if {$fileChecksum != $dataChecksum} {
            puts "Generated data has modifications against ${filePath}"

            if {[catch {open $filePath w} fileHandle]} {
                error "Error write opening file: $filePath"
            }

            puts -nonewline $fileHandle $data
            close $fileHandle
        }
    }
}
