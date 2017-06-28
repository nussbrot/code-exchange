#
# Generate a Tex Register Definition
#

package require sxl
package provide export_tex 1.0

source [file dirname [info script]]/sxl_helper.tcl

namespace eval export_tex {

  # -----------------------------------------------------------------------------
  #   Helpers
  # -----------------------------------------------------------------------------

  proc convName {name} {
    # we don't want no underscore symbols in tex
    return [string trimleft [regsub -all {([_])} $name { }]]
  }

  # -----------------------------------------------------------------------------
  #   Process file
  # -----------------------------------------------------------------------------
  proc translate {inFile outFile parameter} {
    set sxl_filename $inFile
    set out_filename $outFile
    
    #set colorlist {niceyellow niceorange}
    set colorlist {black}
    
    # parse paramters
    set mstName ""
    set i 0
    while {$i < [llength ${parameter}]} {
      set argument [lindex ${parameter} $i]
      switch -glob -- ${argument} {
        -m  {
              incr i
              set mstName [lindex ${parameter} $i]
            }
        *   {puts stderr "\n--> ERROR: don't know option \"${argument}\"\n"; pUsage; return}
        default { break }
      }
      incr i
    }
    
    # init sxl
    if {[catch {::sxl::sxl_init} result]} {
      error $result
      return
    }
    
    # read sxl file
    if {[catch {::sxl::fileIO::readFile $sxl_filename} result]} {
      error $result
      return
    }
    set devname [::sxl::cfg::getDeviceInfo "name"]
    set devname_up [string toupper $devname]
    set devname_low [string tolower $devname]
    
    set total_text {}
    
    # get and sort blocks
    set slaveList {}
    set blockList {}
    set slaveList [get_sxl_slavelist [string tolower $mstName]]
    set slaveList [lsort -integer -index 1 $slaveList]

    #puts [join $slaveList \n]
    foreach {slaveName slaveAddr} [join $slaveList] {
      set block [::sxl::parameter get $slaveName.block]
      #puts "$slaveName: $block"
      if {$block != ""} {
        lappend blockList [list $block $slaveAddr]
      }
    }

    # register insertion
    set tpl_registers {}
    set tpl_reg_bits {}
    set tpl_reg_values {}
    # every block
    foreach {blockName blockAddr} [join $blockList] {
      
      # no registers
      if {![info exists ::sxl::cfg::regs($blockName)]} continue
       
      # sort registers by addr
      set regList {}
      foreach reg [::sxl::register list $blockName] {
        set regName [lindex [split $reg .] end]
        set regAddr [expr [::sxl::parameter get $reg.addr]]
        lappend regList [list $regName $regAddr [::sxl::parameter get $reg.desc]]
      }
      set regList [lsort -integer -index 1 $regList]
      
      set blockBaseAddr $blockAddr
      
      set module_text {}
      # Add Block
      set tmpname "[::export_tex::convName $blockName]"
      append total_text "\\newpage\n"
      append total_text "\\section\{$tmpname \(Offset 0x[format %08X $blockBaseAddr]\)\}\n"
      append total_text "\n\n"
      # print the registers
      foreach {regName regAddr regDesc} [join $regList] {
        if {$regAddr == ""} {
          continue
        }
        set reg_text {}

        # add Register (+ description)
        set tmpname "[::export_tex::convName $regName]"
        append reg_text "\\subsection\{$tmpname\}\n"
        append reg_text "\{$regDesc\}\n"
        append reg_text "\\begin\{register\}\{h\}\{$tmpname\}\{0x[format %08X $regAddr]\}\% name=$tmpname\n"
        append reg_text "\\vspace\{1ex\}\n"
        set bytefields {}
        set signalTable {}

        if {![info exists ::sxl::cfg::sigs($blockName,$regName)]} {
          # Register without signals
          append bytefields "\\begin\{bytefield\}\[endianness=big,bitwidth=1.25em\]\{32\}\n"
          append bytefields "\\bitheader\{31,0\} \\\\\n"
          append bytefields "\\bitbox\{32\}\{$tmpname\}\n"
          append bytefields "\\end\{bytefield\}\n"
        } else {
          # SIGNALs Exists
          append signalTable "\\begin\{tabularx\}\{\\textwidth\}\{c c p\{9cm\} c \}\n"
          append signalTable "\\toprule\n"
          append signalTable "\\textbf\{Bit\} \& \\textbf\{Type\} \& \\textbf\{Function\} \& \\textbf\{Reset\} \\\\\n"
          append signalTable "\\toprule \\toprule\n"
          
          # handle all signals of a register, sort by signal position
          set sigList {}
          foreach sig $::sxl::cfg::sigs($blockName,$regName) {
            set sigName [lindex [split $sig .] end]
            set sigPos [::sxl::parameter get $blockName.$regName.$sig.pos]
            set sigReset [::sxl::parameter get $blockName.$regName.$sig.reset]
            set sigMode [::sxl::parameter get $blockName.$regName.$sig.mode]
            set sigType [::sxl::parameter get $blockName.$regName.$sig.type]
            set pos [split $sigPos :]
            set sigMsb 0
            set sigLsb 0
            if {[llength $pos] == 1} {
              # Single Bit
              set sigMsb $pos
              set sigLsb $pos
            } else {
              # Multi Bits
              foreach {sigMsb sigLsb} $pos {}
            }
            lappend sigList [list $sigName $sigMsb $sigLsb $sigMode $sigType $sigReset]
          }
          # sort by MSB
          set sigList [lsort -integer -decreasing -index 1 $sigList]
          # add register values
          set lastSigPos 31
          set colorIndex 0
          foreach {sigName sigMsb sigLsb sigMode sigType sigReset} [join $sigList] {
            set sigLen 1
            set sigPos $sigLsb
            set sigBits $sigLsb
            set sigColor [lindex $colorlist $colorIndex]
            if { $sigMsb == $sigLsb} {
              # Single Bit
            } else {
              # Multi Bits
              set sigLen [expr $sigMsb - $sigLsb + 1]
              set sigBits $sigMsb:$sigLsb
            }
            # add filler for missing bytefileds
            if { $sigMsb != $lastSigPos } {
              set fillLen [expr $lastSigPos - $sigMsb ]
              set fillPos [expr $sigMsb + 1 ]
              append bytefields "\{\\color\{gray\} \\regfieldb\{\}  \{$fillLen\}\{$fillPos\}\}\%\n"
            }
            set lastSigPos [expr $sigPos - 1]
            set tmpname "[::export_tex::convName $sigName]"
            append bytefields "\{\\color\{$sigColor\} \\regfieldb\{$tmpname\}  \{$sigLen\}\{$sigPos\}\}\%\n"
            append signalTable "\\color\{$sigColor\} $sigBits \& $sigMode    \& $tmpname\  \& $sigReset    \\\\\n"
            # handle enums
            if { $sigType == "enum" && [info exists ::sxl::cfg::enums($blockName,$regName,$sigName)]} {
              # handle all enums of a signal, sort by value
              set enumList {}
              foreach enum $::sxl::cfg::enums($blockName,$regName,$sigName) {
                set enumName [lindex [split $enum .] end]
                set enumValue [::sxl::parameter get $blockName.$regName.$sigName.$enum.value]
                set enumDesc [::sxl::parameter get $blockName.$regName.$sigName.$enum.desc]
                lappend enumList [list $enumName $enumValue $enumDesc]
              }
              # sort by value
              set enumList [lsort -integer -index 1 $enumList]
              foreach {enumName enumValue enumDesc} [join $enumList] {
                append signalTable "\\color\{$sigColor\}  \&     \& $enumValue\: $enumDesc   \&  \\\\\n"
              }
            }
            append signalTable "\\midrule \n"
            # next color for next signal
            set colorIndex [expr $colorIndex +1]
            if { $colorIndex == [llength $colorlist]} {
              set colorIndex 0
            }
          }
          append signalTable "\\end\{tabularx\}\n"
        }
        append reg_text $bytefields
        append reg_text "\\vspace\{0.5 cm\}\n"
        append reg_text "\\newline\n"
        append reg_text $signalTable
        append reg_text "\\label\{$tmpname\}\%\n"
        append reg_text "\\end\{register\}\n"
        append reg_text "\\newpage\n"
        append reg_text "\n\n"
        append total_text $reg_text
      }
    }

    # write Header file
    if {[catch "open $out_filename w" fid]} {
      error "Could not write to file $out_filename!"
    }
    puts -nonewline $fid $total_text
    close $fid    
    return 0
  }
}
