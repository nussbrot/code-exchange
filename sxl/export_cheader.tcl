#
# Generate a C Header
# for low level drivers
#

package require sxl
package provide export_cheader 1.0

source [file dirname [info script]]/sxl_helper.tcl
source [file dirname [info script]]/export_block_driver.tcl

namespace eval export_cheader {
  variable debug 0

  # -----------------------------------------------------------------------------
  #   Helpers
  # -----------------------------------------------------------------------------
  proc convNameUpper {name} {
    return [string trimleft [string toupper $name]]
  }

  proc convBitMaskToHex {nbits} {
    set mask [expr 2**$nbits - 1]
    return 0x[format %08X $mask]
  }

  # -----------------------------------------------------------------------------
  #   Process file
  # -----------------------------------------------------------------------------
  proc translate {sxlFile hFile parameter } {
    # variable debug

    #if {$debug} {
    #  set dbgId [open debug.txt w]
    #}

    #create directory
    file mkdir [lindex  [split $hFile /] 0]
    set baseAddressesHfile [open $hFile w]

    # parse paramters
    set tplFile ""
    set mstName ""
    set i 0
    while {$i < [llength ${parameter}]} {
      set argument [lindex ${parameter} $i]
      switch -glob -- ${argument} {
        -t  {
              incr i
              set tplFile [lindex ${parameter} $i]
            }
        -d  {
              incr i
              set defName [lindex ${parameter} $i]
            }
        -m  {
              incr i
              set mstName [lindex ${parameter} $i]
            }
        *   {puts stderr "\n--> ERROR: don't know option \"${argument}\"\n"; pUsage; return}
        default { break }
      }
      incr i
    }

    # open tpl File
    # read template
    if {![file exists $tplFile]} {
      error "File '$tplFile' not found!"
    }
    set tplHFile [open $tplFile r]
    set tpl_text [read $tplHFile]
        # replace standard keywords
    set stdIncludeGuard "BASE_ADDRESSES_CMS1_MCCU04"
    set tpl_text [string map "%TPL_HEADER_GUARD%      $stdIncludeGuard"            $tpl_text]
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
    set devname [::sxl::cfg::getDeviceInfo "name"]
    if { $devname == "" } {
      set devname "FPGA"
    }
    set devname_up [string toupper $devname]

    # Sort Slaves
    set slaveList {}
    set slaveList [get_sxl_slavelist [string tolower $mstName]]
    set slaveList [lsort -integer -index 1 $slaveList]

    #if {$debug} {
    #  puts $dbgId "\n:slaveList:"
    #  puts $dbgId [join $slaveList \n]
    #}

    set blockNameList {}
    set slaveListInterconBlockNameCounter -1
    set moduleList ""
    # every block
    foreach {slaveName slaveAddr} [join $slaveList] {
      #if {$debug} {
      #  puts $dbgId "\n:Process $slaveName $slaveAddr:"
      #}

      set blockName [::sxl::parameter get $slaveName.block]
      lappend blockNameList [list $blockName $slaveAddr]

      if {$blockName != ""} {
          set splitedSlaveName [lindex [split $slaveName .] 1]
          append moduleList "#define [format %-40s [convNameUpper $splitedSlaveName]_BASE] (0x[format %08X $slaveAddr]U | SOFTCORE_WISHBONE_OFFSET)\n"
      }

      #puts $dbgId $blockName

      #get icons
      set iconName [::sxl::parameter get $slaveName.icon]
      if {$iconName == ""} {
        export_block_driver::registerSlave $slaveName $slaveAddr
      } else {
        incr slaveListInterconBlockNameCounter 1
      }
      set slaveListIntercon {}
      set slaveListIntercon [get_sxl_slavelist [string tolower $iconName]]

      set slaveListInterconBlockNameArray {}

      foreach {slaveListInterconName slaveListInterconeAddr} [join $slaveListIntercon] {
          #we have to check if we instantiate the same intercon twice
          #puts $dbgId $slaveListInterconName
          export_block_driver::registerSlave $slaveListInterconName [expr {$slaveAddr + $slaveListInterconeAddr}]
          set slaveListInterconBlockName [::sxl::parameter get $slaveListInterconName.block]
          #puts $dbgId [list $slaveListInterconBlockName [expr {$slaveAddr + $slaveListInterconeAddr}]]

          if { [lsearch  $blockNameList $slaveListInterconBlockName ] } {

            lappend slaveListInterconBlockNameArray slaveListInterconBlockName
            #puts $dbgId [list "found" $slaveListInterconBlockName]
            set concatSlaveListInterconBlockName [concat $slaveListInterconBlockName"_"$slaveListInterconBlockNameCounter]
            regsub -all "\"" $concatSlaveListInterconBlockName "" concatSlaveListInterconBlockName
            #puts $dbgId $concatSlaveListInterconBlockName
          }
          append moduleList "#define [format %-40s [convNameUpper $concatSlaveListInterconBlockName]_BASE] (0x[format %08X [expr {$slaveAddr + $slaveListInterconeAddr}]]U | SOFTCORE_WISHBONE_OFFSET)\n"
      }
    }

    #replace template variables
    regsub -all "%TPL_HEADER_GUARD%" $tpl_text "$stdIncludeGuard" tpl_text
    regsub -all "%TPL_MODULE_ADDRESSES%" $tpl_text "$moduleList" tpl_text
    puts $baseAddressesHfile $tpl_text

    #if {$debug} {
    #  close $dbgId
    #}
    return 0
  }
}
