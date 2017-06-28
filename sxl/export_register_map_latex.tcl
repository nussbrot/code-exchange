#
# Generate a Tex Register Definition
#

package require sxl
package provide export_register_map_latex 1.0

namespace eval export_register_map_latex {

  # -----------------------------------------------------------------------------
  #   Helpers
  # -----------------------------------------------------------------------------
  proc convName {name} {
    # we don't want no underscore symbols in tex
    return [string trimleft [regsub -all {([_])} $name { }]]
  }

  proc escapeLatex {str} {
    set result {}
    foreach char [split $str {}] {
      switch $char {
        _       {append result "\\_"}
        default {append result $char}
      }
    }
    return $result
  }


  # parse pos field and return a list {msb lsb}
  # if it is a single bit field, the list has msb=lsb
  proc sxl_parse_signal_pos {block register signal} {
    set sigPos [::sxl::parameter get $block.$register.$signal.pos]
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
    return [list $sigMsb $sigLsb]
  }

  # forms a sorted list of signals
  proc get_sorted_signal_fields {block register} {
    set sigList {}
    foreach sig $::sxl::cfg::sigs($block,$register) {
      set sigName [lindex [split $sig .] end]
      set _ [lassign [sxl_parse_signal_pos $block $register $sigName] sigMsb]

      lappend sigList [list $sigName $sigMsb]
    }
    # sort by MSB and return indices
    set indices [lsort -integer -decreasing -index 1 -indices $sigList]
    # form a sorted sigList
    set sigSorted {}
    foreach index $indices {
      lappend sigSorted [lindex $sigList [list $index 0]]
    }
    return $sigSorted
  }

  # parse a desc field since we allow special commands inside:
  # - 'LATEX_INPUT file_name' will read the file and use its contents for the
  #   desc field. The rest of the field will be ignored.
  # - if the content doesn't start with a notifier from the above list, it will
  #   be used as it is for the desc field
  proc latex_parse_desc {desc} {
    set str {}
    if {$desc != ""} {
      set cmd [lindex [split $desc] 0]
      set tex [lindex [split $desc] 1]
      switch $cmd {
        "LATEX_INPUT" {
          append str "\\input\{$tex\}\n"
        }
        default {
          append str [escapeLatex $desc]
        }
      }
    }
    return $str
  }

  # the env setup
  # there are two versions:
  # latex_register_begin and latex_section_begin
  # will format addr as hexnumber
  # will format name with convName
  # will create a label reg:lowercase_name
  # will parse the desc field of the sxl.register
  proc latex_register_begin {block name} {
    # get SXL parameter
    set addr [::sxl::parameter get $block.$name.addr]
    set desc [::sxl::parameter get $block.$name.desc]
    # address defaults to empty, we only write address field if it is set
    set hexaddr {}
    if { [string length $addr] > 0 } {
      # get leading zeroes. by address 0x1 we get 0x01
      set hexaddr "0x[format %02X $addr]"
    }
    set convname "[::export_register_map_latex::convName $name]"
    set str {}
    append str "\\begin\{register\}\{bth\}\{$convname\}\{$hexaddr\}\n"
    append str "\\label\{reg:[string tolower $convname]\}\n"
    append str "\\begin\{regdesc\}\n"
    append str [latex_parse_desc $desc]
    append str "\n\\end\{regdesc\}\n"
    append str "\\begin\{center\}\n"
    return $str
  }

  proc latex_section_begin {block name} {
    # get SXL parameter
    set addr [::sxl::parameter get $block.$name.addr]
    set desc [::sxl::parameter get $block.$name.desc]
    # address defaults to empty, we only write address field if it is set
    set hexaddr {}
    if { [string length $addr] > 0 } {
      # get leading zeroes. by address 0x1 we get 0x01
      set hexaddr "(0x[format %02X $addr])"
    }
    set convname "[::export_register_map_latex::convName $name]"
    set str {}
    append str "\\subsection\[$convname\]\{$convname $hexaddr\}\n"
    append str "\\label\{reg:[string tolower $convname]\}\n"
    append str [latex_parse_desc $desc]
    append str "\\begin\{center\}\n"
    return $str
  }

  # closing the env
  proc latex_register_end {} {
    set str {}
    append str "\\end\{center\}\n"
    append str "\\end\{register\}\n"
    # Insert a float barrier to prevent an overflow in case of many registers.
    append str "\\FloatBarrier\n"
    append str "\n\n"
    return $str
  }
  proc latex_section_end {} {
    set str {}
    append str "\\end\{center\}\n"
    # Insert a float barrier to prevent an overflow in case of many registers.
    append str "\\FloatBarrier\n"
    append str "\n\n"
    return $str
  }

  # the front table as it is used by single signal registers
  # note that this is currently unused and maybe removed in the near future!
  proc latex_create_fronttable {block register signal_list} {
    set str {}
    append str "\\begin\{tabularx\}\{0.7\\textwidth\}\{r l r l r l\}\n"
    foreach sig [join $signal_list] {
      set sigMode   [::sxl::parameter get $block.$register.$sig.mode]
      set sigRange  [::sxl::parameter get $block.$register.$sig.range]
      set sigNumrep [::sxl::parameter get $block.$register.$sig.numrep]

      append str "\t\\textsc\{Type:\} & $sigMode & \\textsc\{Range:\} & $sigRange & \\textsc\{Format:\} & $sigNumrep \\\\\n"
    }
    append str "\\end\{tabularx\}\n"
    return $str
  }

  proc latex_create_bytefield {block register signal_list} {
    set str {}
    append str "\\begin\{bytefield\}\[endianness=big,bitwidth=0.025\\textwidth,rightcurly=.,rightcurlyspace=0pt\]\{32\}\n"
    append str "\t\\bitheader\{31,0\}\\\\\n"

    foreach sigName [join $signal_list] {
      append str "\t\\bitbox\{32\}\{$sigName\} \\\\\[0.5ex\]\n"
      # this part only if there is a reset
      set sigReset [::sxl::parameter get $block.$register.$sigName.reset]
      if {$sigReset != ""} {
        append str "\t\\begin\{rightwordgroup\}\{Reset\}\n"
        append str "\t\t\\bitbox\{32\}\{$sigReset\}\n"
        append str "\t\\end\{rightwordgroup\}\n"
      }
    }
    append str "\\end\{bytefield\}\n"
    append str "\\regnewline\n"
    return $str
  }

  # only sets regfields and filler fields
  proc latex_create_regfield {block register signal_list} {
    set str {}
    set lastSigPos 31
    set hasReset 0
    foreach sigName [join $signal_list] {
      # get needed parameters
      set _ [lassign [sxl_parse_signal_pos $block $register $sigName] sigMsb sigLsb]
      set sigReset [::sxl::parameter get $block.$register.$sigName.reset]

      # add filler for missing bytefields
      if { $sigMsb != $lastSigPos } {
        set fillLen [expr $lastSigPos - $sigMsb ]
        set fillPos [expr $sigMsb + 1 ]
        append str "\t\{\\color\{gray\} \\regfieldb\{\}  \{$fillLen\}\{$fillPos\}\}%\n"
      }
      set lastSigPos [expr $sigLsb - 1]
      set convname "[::export_register_map_latex::convName $sigName]"
      set sigLen [expr $sigMsb - $sigLsb + 1]
      # draw the reset field only if a value is present
      if {$sigReset == ""} {
        append str "\t\\regfieldb\{$convname\}\{$sigLen\}\{$sigLsb\}\%\n"
      } else {
        set hasReset 1
        append str "\t\\regfield\{$convname\}\{$sigLen\}\{$sigLsb\}\{\{$sigReset\}\}\%\n"
      }
    }
    # if resets were present, we draw the Reset label
    if {$hasReset == 1} {
      append str "\t\\reglabel\{Reset\}"
    }
    # for better spacing we need to add a regnewline and vertical space
    append str "\\regnewline%\n"
    append str "\\vspace\{0.5 cm\}\n"
    return $str
  }

  proc latex_create_backtable {block register signal_list} {
    set str {}
    append str "\t\\begin\{tabularx\}\{\\textwidth\}\{c p\{0.4\\textwidth\} c c c c\}\n"
    append str "\t\t\\textsc\{Bits\} & \\textsc\{Name\} & \\textsc\{Unit\} & \\textsc\{Type\} & \\textsc\{Range\} & \\textsc\{Format\}\\\\\n"

    # steps in loop:
    # - add rule, first iteration adds toprule, then midrule
    # - add signal + enum + description
    set rule "toprule"
    foreach sigName [join $signal_list] {
      append str "\t\t\\$rule\n"
      set rule "midrule"
      # get needed parameters
      set _ [lassign [sxl_parse_signal_pos $block $register $sigName] sigMsb sigLsb]
      set sigMode   [::sxl::parameter get $block.$register.$sigName.mode]
      set sigRange  [::sxl::parameter get $block.$register.$sigName.range]
      set sigDesc   [::sxl::parameter get $block.$register.$sigName.desc]
      set sigType   [::sxl::parameter get $block.$register.$sigName.type]
      set sigNumrep [::sxl::parameter get $block.$register.$sigName.numrep]
      set sigUnit   [::sxl::parameter get $block.$register.$sigName.unit]

      # Single Bit
      set sigBits $sigLsb
      if { $sigMsb != $sigLsb} {
        # Multi Bits
        set sigBits $sigMsb:$sigLsb
      }
      set convname "[::export_register_map_latex::convName $sigName]"
      append str "\t\t$sigBits & \\textbf\{$convname\} & $sigUnit & $sigMode & $sigRange  & $sigNumrep \\\\\n"

      # add description row only if field is present
      set desc [latex_parse_desc $sigDesc]
      if {$desc != ""} {
        append str "\t\t& \\multicolumn\{5\}\{X\}\{\\small $desc\} \\\\\n"
      }

      # handle enums
      if { $sigType == "enum" && [info exists ::sxl::cfg::enums($block,$register,$sigName)]} {
        # handle all enums of a signal, sort by value
        set enumList {}
        foreach enum $::sxl::cfg::enums($block,$register,$sigName) {
          set enumName [escapeLatex [lindex [split $enum .] end]]
          set enumValue [::sxl::parameter get $block.$register.$sigName.$enum.value]
          set enumDesc [::sxl::parameter get $block.$register.$sigName.$enum.desc]
          lappend enumList [list $enumName $enumValue $enumDesc]
        }
        # sort by value
        set enumList [lsort -integer -index 1 $enumList]
        foreach {enumName enumValue enumDesc} [join $enumList] {
          append str "\t\t& \\multicolumn\{5\}\{X\}\{\\small ${enumValue}: \\emph\{${enumName}\} $enumDesc\} \\\\\n"
        }
      }
    }
    # we need to add bottom rule and close the env
    append str "\t\t\\bottomrule\n"
    append str "\t\\end\{tabularx\}\n"
    return $str
  }

  proc latex_write_reserved_register_subsection {register_list} {
    set str {}
    append str "\\subsection\{Reserved registers\}"
    append str "\\begin\{itemize\}"
    foreach reg $register_list {
      append str "\\item $reg"
    }
    append str "\\end\{itemize\}"
    return $str
  }

  # -----------------------------------------------------------------------------
  #   Block export to latex Register Map Format
  # -----------------------------------------------------------------------------
  proc writeBlock {sxlFile outFile blockName {isFactoryHack 0}} {
    set out_filename $outFile
    set begin_env latex_register_begin
    set end_env latex_register_end

    if {$isFactoryHack > 0} {
      set begin_env latex_section_begin
      set end_env latex_section_end
    }

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


    # block has no registers?
    if {![info exists ::sxl::cfg::regs($blockName)]} {
      error "bad thing is if the block has no registers"
      exit 2
    }

    # hack helper to print a list of reserved registers
    set reserved_list {}
    # print the registers
    set total_text {}
    foreach reg [::sxl::register list $blockName] {
      set regName [lindex [split $reg .] end]
      puts $regName

      # add Register (+ description)
      set frontTable {}
      set bytefields {}
      set backTable {}

      # incoming hacks for factory_settings
      # goals:
      # - register with state reserved are developer parameters and will not be shown
      # - register without signals froms a new section
      #
      # register has state==reserved?
      set state [::sxl::parameter get $blockName.$regName.state]
      if {$state == "reserved"} {
        puts "  Skipping, because it has state reserved!"
        lappend reserved_list [convName $regName]
        continue
      }
      # block has no signals?
      if {![info exists ::sxl::cfg::sigs($blockName,$regName)]} {
        if {[llength $reserved_list] > 0} {
          puts "  This list of registers will be appended to the reserved subsection:"
          foreach reg $reserved_list { puts "    $reg"}
          append total_text [latex_write_reserved_register_subsection $reserved_list]
          set reserved_list {}
        }
        puts "  Special hack for signal-less registers"
        set desc [::sxl::parameter get $blockName.$regName.desc]
        append total_text [latex_parse_desc $desc]
        continue
      }
      # handle all signals of a register, sort by signal position
      set sigList [get_sorted_signal_fields $blockName $regName]
      puts $sigList

      if {[llength $sigList] == 1} {
        # front table doesn't provide information about enumerations!
        #append frontTable [latex_create_fronttable $blockName $regName $sigList]

        # bytefield does include misleading information about register size
        # choose bytefield only if pos is 31:0 else choose regfield
        set _ [lassign [sxl_parse_signal_pos $blockName $regName [join $sigList]] sigMsb sigLsb]
        if { $sigMsb == 31 && $sigLsb == 0} {
          append bytefields [latex_create_bytefield $blockName $regName $sigList]
        } else {
          append bytefields [latex_create_regfield $blockName $regName $sigList]
        }
        append backTable [latex_create_backtable $blockName $regName $sigList]
      } else {
        append bytefields [latex_create_regfield $blockName $regName $sigList]
        append backTable [latex_create_backtable $blockName $regName $sigList]
      }

      set reg_text {}
      append reg_text [$begin_env $blockName $regName]
      append reg_text $frontTable
      append reg_text $bytefields
      append reg_text $backTable
      append reg_text [$end_env]
      append total_text $reg_text
    }
    # if the last section has reserved registers, they should be output as well
    if {[llength $reserved_list] > 0} {
      puts "  This list of registers will be appended to the reserved subsection:"
      foreach reg $reserved_list { puts "    $reg"}
      append total_text [latex_write_reserved_register_subsection $reserved_list]
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
