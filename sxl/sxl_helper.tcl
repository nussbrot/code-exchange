# helper functions

# should behave the same as the unix program basename
proc basename {path} {
    return [file rootname [file tail $path]]
}

# should return a camel cased name
proc to_camel_case {name} {
    set unsc "_"
    
    # returns -1 if unsc is not in name
    # returns the index of the first found unsc otherwise
    set idx [string first $unsc $name]
    while { $idx < [string length $name] && $idx >= 0 } {
        set next [expr {$idx+1}]
        set new [string toupper [string index $name $next]]
        set name [string replace $name $idx $next $new]
        
        set idx [string first $unsc $name]
    }
    # always uppercase first char
    return [string toupper $name 0 0]
}

# SXL helper functions
proc error {msg} {
  # redirect error messages of SXL lib to this proc
  if {[catch "package present Tk"]} {
    puts stderr "ERROR !\n$msg"
  } else {
    tk_messageBox -message "ERROR !\n$msg" -icon error -title [file tail [info script]]
    exit
  }
}
  
proc add_block {block {pars {}}} {
  ::sxl::block add $block
  foreach {parName parData} $pars {
    ::sxl::parameter set $block.$parName $parData
  }
}
  
proc add_reg {block regName {pars {}}} {
  ::sxl::register add $block.$regName
  foreach {parName parData} $pars {
    ::sxl::parameter set $block.$regName.$parName $parData
  }
}
  
proc add_sig {block regName sigName {pars {}}} {
  ::sxl::signal add $block.$regName.$sigName
  foreach {parName parData} $pars {
    ::sxl::parameter set $block.$regName.$sigName.$parName $parData
  }
}
  
proc add_enum {block regName sigName enumName {pars {}}} {
  ::sxl::enum add $block.$regName.$sigName.$enumName
  foreach {parName parData} $pars {
    ::sxl::parameter set $block.$regName.$sigName.$enumName.$parName $parData
  }
}
  
proc add_flag {block regName sigName flagPos {pars {}}} {
  ::sxl::flag add $block.$regName.$sigName.$flagPos
  foreach {parName parData} $pars {
    ::sxl::parameter set $block.$regName.$sigName.$flagPos.$parName $parData
  }
}
  
proc add_icon {icon {pars {}}} {
  ::sxl::icon add $icon
  foreach {parName parData} $pars {
    ::sxl::parameter set $icon.$parName $parData
  }
}
  
proc add_master {icon mstName {pars {}}} {
  ::sxl::master add $icon.$mstName
  foreach {parName parData} $pars {
    ::sxl::parameter set $icon.$mstName.$parName $parData
  }
}
  
proc add_slave {icon slvName {pars {}}} {
  ::sxl::slave add $icon.$slvName
  foreach {parName parData} $pars {
    ::sxl::parameter set $icon.$slvName.$parName $parData
  }
}

# -----------------------------------------------------------------------------
#   Parsing Helpers (for exporters)
# -----------------------------------------------------------------------------
proc listSlaves {root addrBase slaveList} {
  set slaves [::sxl::slave list $root]
  foreach slave $slaves {
    foreach {dummy slvName} [split $slave .] { break }
    set mask  [::sxl::parameter get $slave.mask]
    set addr  [::sxl::parameter get $slave.addr]
    set size  [::sxl::parameter get $slave.size]
    set addr0 [expr $addrBase | $addr]
    
    # masters
    set icon 0
    foreach master [::sxl::master list] {
      foreach {mstRoot mstName} [split $master .] { break }
      if {$mstName == $slvName} {
        set slaveList [listSlaves $mstRoot $addr0 $slaveList]
        set icon 1
      }
    }
    if {!$icon} {
      #lappend slaveList [list $slave $addr0 $bar]
      lappend slaveList [list $slave $addr0]
    }
  }
  return $slaveList
}

proc get_sxl_slavelist { devmaster } {
  # Find Master of all masters, usually PCI
  set superMaster ""
  foreach icon [::sxl::icon list] {
    set masters [::sxl::master list $icon]
    foreach master $masters {
      set actMaster [string tolower [lindex [split $master .] end]]
      if { $devmaster == $actMaster } {
        set superMaster $icon
      }
    }
  }
  if { $superMaster == "" } {
    puts "no root Interconnect ($devmaster) found"
    return ""
  }
  set slaveList [listSlaves $superMaster 0 {}]
  return $slaveList
}
