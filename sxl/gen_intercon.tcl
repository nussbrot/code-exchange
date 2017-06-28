# script to generate wb interconnects according to sxl files

set tpl_user  $::tcl_platform(user)
set tpl_year  [clock format [clock seconds] -format %Y]

# -----------------------------------------------------------------------------

package require sxl

proc convName {name} {
  return [string trimleft [string tolower [regsub -all {([A-Z])} $name {_\1}]] _]
}

proc str_len {margin str} {
  return [format %-[expr $::alignWidth + $margin]s $str]
}

proc init {} {
  uplevel 1 {
    # default parameters
    set intercon      $iconName
    set signal_groups 0
    set addr_hi       31
    set addr_lo       0
    set data_size     32
    set tga_bits      2
    set tgc_bits      3
    set tgd_bits      0
    set rename_tga    "bte"
    set rename_tgc    "cti"
    set rename_tgd    "tgd"
    set classic       "000"
    set endofburst    "111"
    set type          "sharedbus"
    set priority      0

    # keep track of implementation size
    set masters   0
    set slaves    0
    set o_rty     0
    set i_rty     0
    set o_err     0
    set i_err     0
    set o_tgc     0
    set i_tgc     0
    set o_tga     0
    set i_tga     0

    # format specific definitions
    set alignWidth 10
  }
}

proc master_init {} {
  uplevel 1 {
    incr masters
    set master($masters,wbm)        $master_name
    set master($masters,data_size)  $data_size
    set master($masters,type)       "rw"
    set master($masters,o_lock)     0
    set master($masters,i_err)      1
    set master($masters,i_rty)      1
    set master($masters,o_tga)      0
    set master($masters,o_tgd)      0
    set master($masters,o_tgc)      0
    set master($masters,priority)   1

    set strWidth [string length $master_name]
    if {$alignWidth < $strWidth} {
      set alignWidth $strWidth
    }
  }
}

proc slave_init {} {
  uplevel 1 {
    incr slaves
    set slave($slaves,wbs)        $slave_name
    set slave($slaves,data_size)  $data_size
    set slave($slaves,type)       "rw"
    set slave($slaves,i_sel)      1
    set slave($slaves,i_addr_hi)  31
    set slave($slaves,i_addr_lo)  2
    set slave($slaves,i_lock)     0
    set slave($slaves,o_err)      1
    set slave($slaves,o_rty)      1
    set slave($slaves,i_tga)      0
    set slave($slaves,i_tgc)      0
    set slave($slaves,i_tgd)      0
    set slave($slaves,addr)       0x00000000
    set slave($slaves,size)       0x00100000
    set slave($slaves,addr1)      0x00000000
    set slave($slaves,size1)      0xffffffff
    set slave($slaves,addr2)      0x00000000
    set slave($slaves,size2)      0xffffffff
    set slave($slaves,addr3)      0x00000000
    set slave($slaves,size3)      0xffffffff

    set strWidth [string length $slave_name]
    if {$alignWidth < $strWidth} {
      set alignWidth $strWidth
    }
  }
}

proc get_sxl_config {} {
  uplevel 1 {
    # intercon parameters
    foreach parName $::sxl::cfg::iconIdNames {
      if {[info exists ::sxl::cfg::pars($icon,$parName)]} {
        if {$parName != "mask"} {
          # retrieve all parameters from SXL database
          set $parName $::sxl::cfg::pars($icon,$parName)
        } else {
          # convert mask into addr_hi and addr_lo
          set mask $::sxl::cfg::pars($icon,$parName)
          set addr_hi 0
          set addr_lo 0
          while {$mask != 0} {
            if {$mask & 1} { break }
            incr addr_hi
            incr addr_lo
            set mask [expr $mask >> 1]
          }
          while {$mask != 0} {
            if {$mask & 0} { break }
            incr addr_hi
            set mask [expr $mask >> 1]
          }
          if {$addr_hi} {
            incr addr_hi -1
          }
        }
      }
    }

    # masters
    foreach mstName $::sxl::cfg::msts($icon) {
      set master_name [convName $mstName]
      master_init
      # master parameters
      foreach parName $::sxl::cfg::mstIdNames {
        if {[info exists ::sxl::cfg::pars($icon,$mstName,$parName)]} {
          set master($masters,$parName) $::sxl::cfg::pars($icon,$mstName,$parName)
        }
      }
      # parse all parameters for priority definitions
#      foreach {parName parData} [array get ::sxl::cfg::pars] {
#        if {[regexp {$icon,$mstName,(priority_[0-9a-zA-Z_]+)} $parName -> label]} {
#          set master($masters,$label) $parData
#        }
#      }
    }

    # set default priorities of all slaves
    for {set i 1} {$i <= $masters} {incr i} {
      foreach slvName $::sxl::cfg::slvs($icon) {
        set master($i,priority_[convName $slvName]) 1
      }
    }

    # slaves
    foreach slvName $::sxl::cfg::slvs($icon) {
      set slave_name [convName $slvName]
      slave_init
      # slave parameters
      foreach parName $::sxl::cfg::slvIdNames {
        if {[info exists ::sxl::cfg::pars($icon,$slvName,$parName)]} {
          if {$parName != "mask"} {
            # retrieve all parameters from SXL database
            set slave($slaves,$parName) $::sxl::cfg::pars($icon,$slvName,$parName)
          } else {
            # convert mask into i_addr_hi and i_addr_lo
            set mask $::sxl::cfg::pars($icon,$slvName,$parName)
            set i_addr_hi 0
            set i_addr_lo 0
            while {$mask != 0} {
              if {$mask & 1} { break }
              incr i_addr_hi
              incr i_addr_lo
              set mask [expr $mask >> 1]
            }
            while {$mask != 0} {
              if {$mask & 0} { break }
              incr i_addr_hi
              set mask [expr $mask >> 1]
            }
            if {$i_addr_hi} {
              incr i_addr_hi -1
            }

            set slave($slaves,i_addr_hi) $i_addr_hi
            set slave($slaves,i_addr_lo) $i_addr_lo
          }
        }
      }
    }
    
    # count i_rty and i_err signals of all masters
    foreach mstName $::sxl::cfg::msts($icon) {
      foreach par {i_rty i_err} {
        if {[sxl::parameter exists $icon.$mstName.$par]} {
          if {[sxl::parameter get $icon.$mstName.$par]} {
            incr $par
          }
        } else {
          incr $par
        }
      }
    }
    
    # count o_rty and o_err signals of all slaves
    foreach slvName $::sxl::cfg::slvs($icon) {
      foreach par {o_rty o_err} {
        if {[sxl::parameter exists $icon.$slvName.$par]} {
          if {[sxl::parameter get $icon.$slvName.$par]} {
            incr $par
          }
        } else {
          incr $par
        }
      }
    }
  }
}

proc gen_header_legal {} {
  uplevel 1 {
    puts $fid "-------------------------------------------------------------------------------
-- COPYRIGHT (c) SOLECTRIX GmbH, Germany, $tpl_year            All rights reserved
--
-- The copyright to the document(s) herein is the property of SOLECTRIX GmbH
-- The document(s) may be used AND/OR copied only with the written permission
-- from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
-- in the agreement/contract under which the document(s) have been supplied
-------------------------------------------------------------------------------"
  }
}

proc gen_header_notes {} {
  uplevel 1 {
    puts $fid "--*
--* \@short INTERCON
--*        Generated by TCL script [file tail [info script]]. Do not edit this file.
--* \@author $tpl_user
--*
-------------------------------------------------------------------------------
-- for defines see $sxl_file
--
-- Generated [clock format [clock seconds]]
--
-- Wishbone masters:"
    for {set i 1} {$i <= $masters} {incr i} {
      puts $fid "--   $master($i,wbm)"
    }
    puts $fid "--"
    puts $fid "-- Wishbone slaves:"
    for {set i 1} {$i <= $slaves} {incr i} {
      puts $fid "--   $slave($i,wbs)"
      if {$slave($i,size) != 0xffffffff} {
        puts $fid "--     baseaddr $slave($i,addr) - size $slave($i,size)"
      }
      if {$slave($i,size1) != 0xffffffff} {
        puts $fid "--     baseaddr $slave($i,addr1) - size $slave($i,size1)"
      }
      if {$slave($i,size2) != 0xffffffff} {
        puts $fid "--     baseaddr $slave($i,addr2) - size $slave($i,size2)"
      }
      if {$slave($i,size3) != 0xffffffff} {
        puts $fid "--     baseaddr $slave($i,addr3) - size $slave($i,size3)"
      }
    }
    puts $fid "--"
    if {$type == "sharedbus"} {
      puts $fid "-- Intercon type: SharedBus"
    } else {
      puts $fid "-- Intercon type: CrossBarSwitch"
    }
    puts $fid "--"
    puts $fid "-------------------------------------------------------------------------------"
  }
}

proc gen_vhdl_pkg {} {
  uplevel 1 {
    puts $fid ""
    puts $fid "LIBRARY ieee;"
    puts $fid "USE ieee.std_logic_1164.ALL;"
    puts $fid ""
    puts $fid "PACKAGE wb_ic_pkg IS"

    if {$signal_groups} {
      for {set i 1} {$i <= $masters} {incr i} {
        # input record
        puts $fid "  TYPE $master($i,wbm)_wbm_i_type IS RECORD"
        if {$master($i,type) != "wo"} {
          puts $fid "    i_data : STD_LOGIC_VECTOR([expr $master($i,data_size)-1] DOWNTO 0);"
        }
        if {$master($i,i_err) == 1} {
          puts $fid "    i_err  : STD_LOGIC;"
        }
        if {$master($i,i_rty) == 1} {
          puts $fid "    i_rty  : STD_LOGIC;"
        }
        puts $fid "    i_ack  : STD_LOGIC;"
        puts $fid "  END RECORD;"
        # output record
        puts $fid "  TYPE $master($i,wbm)_wbm_o_type IS RECORD"
        if {$master($i,type) != "ro"} {
          puts $fid "    o_data : STD_LOGIC_VECTOR([expr $data_size-1] DOWNTO 0);"
          puts $fid "    o_we   : STD_LOGIC;"
        }
        if {$data_size == 8} {
          puts $fid "    o_sel  : STD_LOGIC;"
        } else {
          puts $fid "    o_sel  : STD_LOGIC_VECTOR([expr $data_size/8-1] DOWNTO 0);"
        }
        puts $fid "    o_addr : STD_LOGIC_VECTOR($addr_hi DOWNTO $addr_lo);"
        if {$master($i,o_lock) == 1} {
          puts $fid "    o_lock : STD_LOGIC;"
        }
        if {$master($i,o_tga) == 1} {
          puts $fid "    ${rename_tga}_o : STD_LOGIC_VECTOR([expr $tga_bits-1] DOWNTO 0);"
        }
        if {$master($i,o_tgc) == 1} {
          puts $fid "    ${rename_tgc}_o : STD_LOGIC_VECTOR([expr $tgc_bits-1] DOWNTO 0);"
        }
        puts $fid "    o_cyc  : STD_LOGIC;"
        puts $fid "    o_stb  : STD_LOGIC;"
        puts $fid "  END RECORD;\n"
      }
      puts $fid ""
      for {set i 1} {$i <= $slaves} {incr i} {
        # input record
        puts $fid "  TYPE $slave($i,wbs)_wbs_i_type IS RECORD"
        if {$slave($i,type) != "ro"} {
          puts $fid "    i_data : STD_LOGIC_VECTOR([expr $slave($i,data_size)-1] DOWNTO 0);"
          puts $fid "    i_we   : STD_LOGIC;"
        }
        if {$data_size == 8} {
          puts $fid "    i_sel  : STD_LOGIC;"
        } else {
          puts $fid "    i_sel  : STD_LOGIC_VECTOR([expr $data_size/8-1] DOWNTO 0);"
        }
        if {$slave($i,i_addr_hi) > 0} {
          puts $fid "    i_addr : STD_LOGIC_VECTOR($slave($i,i_addr_hi) DOWNTO $slave($i,i_addr_lo));"
        }
        if {$slave($i,i_tga) == 1} {
          puts $fid "   ${rename_tga}_i  : STD_LOGIC_VECTOR([expr $tga_bits-1] DOWNTO 0);"
        }
        if {$slave($i,i_tgc) == 1} {
          puts $fid "   ${rename_tgc}_i  : STD_LOGIC_VECTOR([expr $tgc_bits-1] DOWNTO 0);"
        }
        puts $fid "    i_cyc  : STD_LOGIC;"
        puts $fid "    i_stb  : STD_LOGIC;"
        puts $fid "  END RECORD;"
        # output record
        puts $fid "  TYPE $slave($i,wbs)_wbs_o_type IS RECORD"
        if {$slave($i,type) != "wo"} {
          puts $fid "    o_data : STD_LOGIC_VECTOR([expr $slave($i,data_size)-1] DOWNTO 0);"
        }
        if {$slave($i,o_rty) == 1} {
          puts $fid "    o_rty  : STD_LOGIC;"
        }
        if {$slave($i,o_err) == 1} {
          puts $fid "    o_err  : STD_LOGIC;"
        }
        puts $fid "    o_ack  : STD_LOGIC;"
        puts $fid "  END RECORD;"
      }
      puts $fid ""
    }

    # overload "AND" function
    puts $fid { \
  FUNCTION "AND" (
    l : STD_LOGIC_VECTOR;
    r : STD_LOGIC)
    RETURN STD_LOGIC_VECTOR;
END PACKAGE wb_ic_pkg;

PACKAGE BODY wb_ic_pkg IS
  FUNCTION "AND" (
    l : STD_LOGIC_VECTOR;
    r : STD_LOGIC)
    RETURN STD_LOGIC_VECTOR IS
    VARIABLE result : STD_LOGIC_VECTOR(l'RANGE);
  BEGIN  -- "AND"
    FOR i IN l'RANGE LOOP
      result(i) := l(i) AND r;
    END LOOP;  -- i
    RETURN result;
  END FUNCTION "AND";
END PACKAGE BODY wb_ic_pkg;}
  }
}

proc gen_traffic_ctrl {} {
  uplevel 1 {
    puts $fid {
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY wb_traffic_supervision IS
  GENERIC (
    g_priority      : INTEGER;
    g_tot_priority  : INTEGER);
  PORT (
    clk             : IN  STD_LOGIC;
    rst_n           : IN  STD_LOGIC := '1';
    i_bg            : IN  STD_LOGIC;       -- bus grant
    i_ce            : IN  STD_LOGIC;       -- clock enable
    o_traffic_limit : OUT STD_LOGIC);
END ENTITY wb_traffic_supervision;

ARCHITECTURE rtl OF wb_traffic_supervision IS
  SIGNAL s_shreg  : STD_LOGIC_VECTOR(g_tot_priority - 1 DOWNTO 0)
                    := (OTHERS => '0');
  SIGNAL s_cntr   : INTEGER RANGE 0 TO g_tot_priority;

BEGIN  -- rtl

  -- purpose: holds information of usage of latest cycles
  -- type   : sequential, no reset, rising clock edge
  sh_reg : PROCESS (clk)
  BEGIN  -- process shreg
    IF (clk'EVENT AND clk = '1') THEN
      IF (i_ce = '1') THEN
        s_shreg <= s_shreg(g_tot_priority - 2 DOWNTO 0) & i_bg;
      END IF;
    END IF;
  END PROCESS sh_reg;

  -- purpose: keeps track of used cycles
  -- type   : sequential, rising edge, mixed type reset
  counter : PROCESS (clk, rst_n)
  BEGIN  -- process counter
    IF (rst_n = '0') THEN
      s_cntr          <= 0;
      o_traffic_limit <= '0';
    ELSIF (clk'EVENT AND clk = '1') THEN
      IF (i_ce = '1') THEN
        IF ((i_bg = '1') AND (s_shreg(g_tot_priority - 1) /= '1')) THEN
          s_cntr <= s_cntr + 1;
          if (s_cntr = g_priority - 1) THEN
            o_traffic_limit <= '1';
          END IF;
        ELSIF ((i_bg = '0') AND (s_shreg(g_tot_priority - 1) = '1')) THEN
          s_cntr <= s_cntr - 1;
          IF (s_cntr = g_priority) THEN
            o_traffic_limit <= '0';
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS counter;

END ARCHITECTURE rtl;}
  }
}

proc gen_entity {} {
  uplevel 1 {
    set margin 9

    # library usage
    puts $fid ""
    puts $fid "LIBRARY ieee;"
    puts $fid "USE ieee.std_logic_1164.ALL;"
    puts $fid ""
    puts $fid "LIBRARY $fpga_lib;"
#    puts $fid "USE $fpga_lib.wb_ic_pkg.ALL;"

    # entity intercon
    puts $fid "\nENTITY ${intercon} IS\n  PORT ("
    # records
    if {$signal_groups} {
      # master port(s)
      puts $fid   "    -- wishbone master port(s)"
      for {set i 1} {$i <= $masters} {incr i} {
   	    puts $fid "    -- $master($i,wbm)"
        puts $fid "    [str_len $margin i_$master($i,wbm)_wbm_o] : IN  $master($i,wbm)_wbm_o_type;"
        puts $fid "    [str_len $margin o_$master($i,wbm)_wbm_i] : OUT $master($i,wbm)_wbm_i_type;"
      }
      # slave port(s)
      puts $fid   "    -- wishbone slave port(s)"
      for {set i 1} {$i <= $slaves} {incr i} {
        puts $fid "    -- $slave($i,wbs)"
        puts $fid "    [str_len $margin i_$slave($i,wbs)_wbs_o] : IN  $slave($i,wbs)_wbs_o_type;"
        puts $fid "    [str_len $margin o_$slave($i,wbs)_wbs_i] : OUT $slave($i,wbs)_wbs_i_type;"
      }
    # separate signals
    } else {
      # masters
      puts $fid     "    -- wishbone master port(s)"
      for {set i 1} {$i <= $masters} {incr i} {
        puts $fid   "    -- $master($i,wbm)"
        puts $fid   "    [str_len $margin i_$master($i,wbm)_o_cyc ] : IN  STD_LOGIC;"
        puts $fid   "    [str_len $margin i_$master($i,wbm)_o_stb ] : IN  STD_LOGIC;"
        if {$master($i,o_tga)} {
          puts $fid "    [str_len $margin i_$master($i,wbm)_o_${rename_tga}] : IN  STD_LOGIC_VECTOR([expr $tga_bits-1] DOWNTO 0);"
        }
        if {$master($i,o_tgc)} {
          puts $fid "    [str_len $margin i_$master($i,wbm)_o_${rename_tgc}] : IN  STD_LOGIC_VECTOR([expr $tgc_bits-1] DOWNTO 0);"
        }
        if {$master($i,type) != "ro"} {
          puts $fid "    [str_len $margin i_$master($i,wbm)_o_we  ] : IN  STD_LOGIC;"
        }
        if {$data_size >= 16} {
          puts $fid "    [str_len $margin i_$master($i,wbm)_o_sel ] : IN  STD_LOGIC_VECTOR([expr $data_size/8-1] DOWNTO 0);"
        }
        puts $fid   "    [str_len $margin i_$master($i,wbm)_o_addr] : IN  STD_LOGIC_VECTOR($addr_hi DOWNTO $addr_lo);"
        if {$master($i,type) != "ro"} {
          puts $fid "    [str_len $margin i_$master($i,wbm)_o_data] : IN  STD_LOGIC_VECTOR([expr $data_size-1] DOWNTO 0);"
        }
        if {$master($i,type) != "wo"} {
          puts $fid "    [str_len $margin o_$master($i,wbm)_i_data] : OUT STD_LOGIC_VECTOR([expr $data_size-1] DOWNTO 0);"
        }
        puts $fid   "    [str_len $margin o_$master($i,wbm)_i_ack ] : OUT STD_LOGIC;"
        if {$master($i,i_rty)} {
          puts $fid "    [str_len $margin o_$master($i,wbm)_i_rty ] : OUT STD_LOGIC;"
        }
        if {$master($i,i_err)} {
          puts $fid "    [str_len $margin o_$master($i,wbm)_i_err ] : OUT STD_LOGIC;"
        }
      }

      # slaves
      puts $fid     "    -- wishbone slave port(s)"
      for {set i 1} {$i <= $slaves} {incr i} {
        puts $fid   "    -- $slave($i,wbs)"
        puts $fid   "    [str_len $margin o_$slave($i,wbs)_i_cyc ] : OUT STD_LOGIC;"
        puts $fid   "    [str_len $margin o_$slave($i,wbs)_i_stb ] : OUT STD_LOGIC;"
        if {$slave($i,i_tga)} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_${rename_tga}] : OUT STD_LOGIC_VECTOR([expr $tga_bits-1] DOWNTO 0);"
        }
        if {$slave($i,i_tgc)} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_${rename_tgc}] : OUT STD_LOGIC_VECTOR([expr $tgc_bits-1] DOWNTO 0);"
        }
        if {$slave($i,type) != "ro"} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_we  ] : OUT STD_LOGIC;"
        }
        if {$data_size >= 16} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_sel ] : OUT STD_LOGIC_VECTOR([expr $data_size/8-1] DOWNTO 0);"
        }
        puts $fid   "    [str_len $margin o_$slave($i,wbs)_i_addr] : OUT STD_LOGIC_VECTOR($slave($i,i_addr_hi) DOWNTO $slave($i,i_addr_lo));"
        if {$slave($i,type) != "ro"} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_data] : OUT STD_LOGIC_VECTOR([expr $data_size-1] DOWNTO 0);"
        }
        if {$slave($i,type) != "wo"} {
          puts $fid "    [str_len $margin i_$slave($i,wbs)_o_data] : IN  STD_LOGIC_VECTOR([expr $data_size-1] DOWNTO 0);"
        }
        puts $fid   "    [str_len $margin i_$slave($i,wbs)_o_ack ] : IN  STD_LOGIC;"
        if {$slave($i,o_rty)} {
          puts $fid "    [str_len $margin i_$slave($i,wbs)_o_rty ] : IN  STD_LOGIC;"
        }
        if {$slave($i,o_err)} {
          puts $fid "    [str_len $margin i_$slave($i,wbs)_o_err ] : IN  STD_LOGIC;"
        }
      }
    }
    # clock and reset
    puts $fid "    -- clock and reset"
    puts $fid "    [str_len $margin clk  ] : IN  STD_LOGIC;"
    puts $fid "    [str_len $margin rst_n] : IN  STD_LOGIC := '1');"
    puts $fid "END ENTITY ${intercon};"

  }
}

proc gen_sig_dec {fid name {bit_hi 0} {bit_lo 0}} {
  if {$bit_hi > 0} {
    puts $fid "  SIGNAL s_$name : STD_LOGIC_VECTOR([expr $bit_hi-1] DOWNTO $bit_lo);"
  } else {
    puts $fid "  SIGNAL s_$name : STD_LOGIC;"
  }
}

proc gen_sig_remap {} {
  uplevel 1 {
    # masters
    for {set i 1} {$i <= $masters} {incr i} {
      gen_sig_dec $fid "$master($i,wbm)_o_cyc "
      gen_sig_dec $fid "$master($i,wbm)_o_stb "
      if {$master($i,o_tga) == 1} {
        gen_sig_dec $fid $master($i,wbm)_${rename_tga}_o $tga_bits 0
      }
      if {$master($i,o_tgc) == 1} {
        gen_sig_dec $fid $master($i,wbm)_${rename_tgc}_o $tgc_bits 0
      }
      if {$master($i,o_tgd) == 1} {
        gen_sig_dec $fid $master($i,wbm)_${rename_tgd}_o $tgd_bits 0
      }
      gen_sig_dec $fid "$master($i,wbm)_o_addr" [expr $addr_hi+1] $addr_lo
      if {$data_size > 8} {
        gen_sig_dec $fid "$master($i,wbm)_o_sel " [expr $data_size/8] 0
      }
      if {$master($i,type) != "ro"} {
        gen_sig_dec $fid "$master($i,wbm)_o_we  "
        gen_sig_dec $fid "$master($i,wbm)_o_data" $data_size 0
      }
      if {$master($i,type) != "wo"} {
        gen_sig_dec $fid "$master($i,wbm)_i_data" $data_size 0
      }
      gen_sig_dec $fid "$master($i,wbm)_i_ack "
      if {$master($i,i_rty) == 1} {
        gen_sig_dec $fid "$master($i,wbm)_i_rty "
      }
      if {$master($i,i_err) == 1} {
        gen_sig_dec $fid "$master($i,wbm)_i_err "
      }
    }

    # slaves
    for {set i 1} {$i <= $slaves} {incr i} {
      gen_sig_dec $fid "$slave($i,wbs)_i_cyc "
      gen_sig_dec $fid "$slave($i,wbs)_i_stb "
      if {$slave($i,i_tga) == 1} {
        gen_sig_dec $fid $slave($i,wbs)_${rename_tga}_i $tga_bits 0
      }
      if {$slave($i,i_tgc) == 1} {
        gen_sig_dec $fid $slave($i,wbs)_${rename_tgc}_i $tgc_bits 0
      }
      if {$slave($i,i_tgd) == 1} {
        gen_sig_dec $fid $slave($i,wbs)_${rename_tgd}_i $tgd_bits 0
      }
      gen_sig_dec $fid "$slave($i,wbs)_i_addr" [expr $slave($i,i_addr_hi)+1] $slave($i,i_addr_lo)
      if {$data_size > 8} {
        gen_sig_dec $fid "$slave($i,wbs)_i_sel " [expr $data_size/8] 0
      }
      if {$slave($i,type) != "ro"} {
        gen_sig_dec $fid "$slave($i,wbs)_i_we  "
        gen_sig_dec $fid "$slave($i,wbs)_i_data" $data_size 0
      }
      if {$slave($i,type) != "wo"} {
        gen_sig_dec $fid $slave($i,wbs)_o_data $data_size 0
      }
      gen_sig_dec $fid "$slave($i,wbs)_o_ack "
      if {$slave($i,o_rty) == 1} {
        gen_sig_dec $fid "$slave($i,wbs)_o_rty "
      }
      if {$slave($i,o_err) == 1} {
        gen_sig_dec $fid "$slave($i,wbs)_o_err "
      }
    }
  }
}

proc gen_global_signals {} {
  uplevel 1 {
    set margin 7

    if {$masters == 1} {
      # bus grant
      puts $fid "  SIGNAL [str_len $margin s_$master(1,wbm)_bg] : STD_LOGIC; -- bus grant"
      # slave select for generation of i_stb to slaves
      for {set i 1} {$i <= $slaves} {incr i} {
        puts $fid "  SIGNAL [str_len $margin s_$slave($i,wbs)_ss] : STD_LOGIC; -- slave select"
      }
    } elseif {$type == "sharedbus"} {
      # shared bus
      # bus grant
      for {set i 1} {$i <= $masters} {incr i} {
        puts $fid "  SIGNAL [str_len $margin s_$master($i,wbm)_bg] : STD_LOGIC; -- bus grant"
      }
      # slave select for generation of i_stb to slaves
      for {set i 1} {$i <= $slaves} {incr i} {
        puts $fid "  SIGNAL [str_len $margin s_$slave($i,wbs)_ss] : STD_LOGIC; -- slave select"
      }
    } else {
      # crossbarswitch
      for {set i 1} {$i <= $masters} {incr i} {
        for {set j 1} {$j <= $slaves} {incr j} {
          if {$master($i,priority_$slave($j,wbs)) != 0} {
            puts $fid "  SIGNAL [str_len $margin s_$master($i,wbm)_$slave($j,wbs)_ss] : STD_LOGIC; -- slave select"
            puts $fid "  SIGNAL [str_len $margin s_$master($i,wbm)_$slave($j,wbs)_bg] : STD_LOGIC; -- bus grant"
          }
        }
      }
    }
  }
}

proc gen_arbiter {} {
  uplevel 1 {
    set margin 7

    # out: wbm_bg (bus grant)
    if {$masters == 1} {
      puts $fid "  s_$master(1,wbm)_bg <= '1';"
    # sharedbus
    } elseif {$type == "sharedbus"} {
      puts $fid   ""
      puts $fid   "  arbiter_sharedbus : BLOCK"
      for {set i 1} {$i <= $masters} {incr i} {
        puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bg_1] : STD_LOGIC;"
        puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bb_1] : STD_LOGIC;"
        puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bg_2] : STD_LOGIC;"
        puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bb_2] : STD_LOGIC;"
        puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bg_q] : STD_LOGIC;"
      }
      for {set i 1} {$i <= $masters} {incr i} {
        puts $fid "    SIGNAL s_$master($i,wbm)_traffic_ctrl_limit : STD_LOGIC;"
      }
      puts $fid   "    SIGNAL [str_len $margin s_ack ] : STD_LOGIC;"
      puts $fid   "    SIGNAL [str_len $margin s_ce  ] : STD_LOGIC;"
      puts $fid   "    SIGNAL [str_len $margin s_idle] : STD_LOGIC;"
      puts $fid   "  BEGIN -- arbiter"
      puts -nonewline $fid   "    s_ack <= i_$slave(1,wbs)_o_ack"
      for {set i 2} {$i <= $slaves} {incr i} {
        puts -nonewline $fid " OR i_$slave($i,wbs)_o_ack"
      }
      puts $fid ";"
      # instantiate wb_traffic_supervision(s)
      set priority 0
      for {set i 1} {$i <= $masters} {incr i} {
        incr priority $master($i,priority)
      }
      if {$priority == 2} {
        incr priority
      }
      for {set i 1} {$i <= $masters} {incr i} {
        puts $fid ""
        puts $fid "    wb_traffic_supervision_$i : ENTITY $fpga_lib.wb_traffic_supervision"
        puts $fid "      GENERIC MAP ("
        puts $fid "        g_priority     => $master($i,priority),"
        puts $fid "        g_tot_priority => [expr $priority-1])"
        puts $fid "      PORT MAP ("
        puts $fid "        i_bg            => s_$master($i,wbm)_bg,"
        puts $fid "        i_ce            => s_ce,"
        puts $fid "        o_traffic_limit => s_$master($i,wbm)_traffic_ctrl_limit,"
        puts $fid "        clk             => clk,"
        puts $fid "        rst_n           => rst_n);"
      }
      # _bg_q
      # bg eq 1 => set
      # end of cycle => rst_n
      for {set i 1} {$i <= $masters} {incr i} {
        puts $fid ""
        puts $fid "    PROCESS (clk, rst_n)"
        puts $fid "    BEGIN"
        puts $fid "      IF (rst_n = '0') THEN"
        puts $fid "        s_$master($i,wbm)_bg_q <= '0';"
        puts $fid "      ELSIF (clk'EVENT AND clk = '1') THEN"
        puts $fid "        IF (s_$master($i,wbm)_bg_q = '0') THEN"
        puts $fid "          s_$master($i,wbm)_bg_q <= s_$master($i,wbm)_bg;"
        puts -nonewline $fid \
                  "        ELSIF (s_ack = '1'"
        if {$master($i,o_tgc)} {
          puts -nonewline $fid " AND (i_$master($i,wbm)_o_${rename_tgc} = \"$classic\" OR i_$master($i,wbm)_o_${rename_tgc} = \"$endofburst\")"
        }
        puts $fid ") THEN"
        puts $fid "          s_$master($i,wbm)_bg_q <= '0';"
        puts $fid "        ELSIF (i_$master($i,wbm)_o_cyc = '0') THEN"
        puts $fid "          s_$master($i,wbm)_bg_q <= '0';"
        puts $fid "        END IF;"
        puts $fid "      END IF;"
        puts $fid "    END PROCESS;"
      }
      # _bg
      puts -nonewline $fid "\n    s_idle <= '1' WHEN (s_$master(1,wbm)_bg_q = '0'"
      for {set i 2} {$i <= $masters} {incr i} {
        puts -nonewline $fid " AND s_$master($i,wbm)_bg_q = '0'"
      }
      puts $fid   ") ELSE '0';"
      puts $fid   "    s_$master(1,wbm)_bg_1 <= '1' WHEN (s_idle = '1' AND i_$master(1,wbm)_o_cyc = '1' AND s_$master(1,wbm)_traffic_ctrl_limit = '0') ELSE '0';"
      puts $fid   "    s_$master(1,wbm)_bb_1 <= '1' WHEN (s_$master(1,wbm)_bg_1 = '1') ELSE '0';"
      for {set i 2} {$i <= $masters} {incr i} {
        puts $fid "    s_$master($i,wbm)_bg_1 <= '1' WHEN (s_idle = '1' AND i_$master($i,wbm)_o_cyc = '1' AND s_$master($i,wbm)_traffic_ctrl_limit = '0' AND s_$master([expr $i-1],wbm)_bb_1 = '0') ELSE '0';"
        puts $fid "    s_$master($i,wbm)_bb_1 <= '1' WHEN (s_$master($i,wbm)_bg_1 = '1' OR s_$master([expr $i-1],wbm)_bb_1 = '1') ELSE '0';"
      }
      puts $fid   "    s_$master(1,wbm)_bg_2 <= '1' WHEN (s_idle = '1' AND s_$master($masters,wbm)_bb_1 = '0' AND i_$master(1,wbm)_o_cyc = '1') ELSE '0';"
      puts $fid   "    s_$master(1,wbm)_bb_2 <= '1' WHEN (s_$master(1,wbm)_bg_2 = '1' OR s_$master($masters,wbm)_bb_1 = '1') ELSE '0';"
      for {set i 2} {$i <= $masters} {incr i} {
        puts $fid "    s_$master($i,wbm)_bg_2 <= '1' WHEN (s_idle = '1' AND s_$master([expr $i-1],wbm)_bb_2 = '0' AND i_$master($i,wbm)_o_cyc = '1') ELSE '0';"
        puts $fid "    s_$master($i,wbm)_bb_2 <= '1' WHEN (s_$master($i,wbm)_bg_2 = '1' OR s_$master([expr $i-1],wbm)_bb_2 = '1') ELSE '0';"
      }
      for {set i 1} {$i <= $masters} {incr i} {
        puts $fid "    s_$master($i,wbm)_bg   <= s_$master($i,wbm)_bg_q OR s_$master($i,wbm)_bg_1 OR s_$master($i,wbm)_bg_2;"
      }
      # ce
      puts -nonewline $fid   "    s_ce <= i_$master(1,wbm)_o_cyc"
      for {set i 2} {$i <= $masters} {incr i} {
        puts -nonewline $fid " OR i_$master($i,wbm)_o_cyc"
      }
      puts $fid " WHEN (s_idle = '1') ELSE '0';"
      # thats it
      puts $fid "  END BLOCK arbiter_sharedbus;"

    # interconnect crossbarswitch
    } else {
      for {set j 1} {$j <= $slaves} {incr j} {
        # single master ?
        set tmp 0
        for {set i 1} {$i <= $masters} {incr i} {
          if {$master($i,priority_$slave($j,wbs)) != 0} {
            set only_master $i
            incr tmp
          }
        }
        if {$tmp == 1} {
          puts $fid "s_$master($only_master,wbm)_$slave($j,wbs)_bg <= s_$master($only_master,wbm)_$slave($j,wbs)_ss AND i_$master($only_master,wbm)_o_cyc;"
        } else {
          puts $fid ""
          puts $fid "  arbiter_$slave($j,wbs) : BLOCK"
          for {set i 1} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bg           ] : STD_LOGIC;"
              puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bg_1         ] : STD_LOGIC;"
              puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bb_1         ] : STD_LOGIC;"
              puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bg_2         ] : STD_LOGIC;"
              puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bb_2         ] : STD_LOGIC;"
              puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_bg_q         ] : STD_LOGIC;"
              puts $fid "    SIGNAL [str_len $margin s_$master($i,wbm)_traffic_limit] : STD_LOGIC;"
            }
          }
          puts $fid     "    SIGNAL [str_len $margin s_ack ] : STD_LOGIC;"
          puts $fid     "    SIGNAL [str_len $margin s_ce  ] : STD_LOGIC;"
          puts $fid     "    SIGNAL [str_len $margin s_idle] : STD_LOGIC;"
          puts $fid     "  BEGIN"
          puts $fid     "    s_ack <= i_$slave($j,wbs)_o_ack;"
          # instantiate wb_traffic_supervision(s)
          # calc tot priority per slave
          set priority 0
          for {set i 1} {$i <= $masters} {incr i} {
            incr priority $master($i,priority_$slave($j,wbs))
          }
          if {$priority == 2} {
            incr priority
          }
          for {set i 1} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts $fid ""
              puts $fid "    wb_traffic_supervision_$i : ENTITY $fpga_lib.wb_traffic_supervision"
              puts $fid "      GENERIC MAP ("
              puts $fid "        g_priority      => $master($i,priority_$slave($j,wbs)),"
              puts $fid "        g_tot_priority  => [expr $priority-1])"
              puts $fid "      PORT MAP ("
              puts $fid "        i_bg            => s_$master($i,wbm)_$slave($j,wbs)_bg,"
              puts $fid "        i_ce            => s_ce,"
              puts $fid "        o_traffic_limit => s_$master($i,wbm)_traffic_limit,"
              puts $fid "        clk             => clk,"
              puts $fid "        rst_n           => rst_n);"
            }
          }
          # _bg_q
          # bg eq 1 => set
          # end of cycle => rst_n
          for {set i 1} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts $fid ""
              puts $fid "    PROCESS (clk, rst_n)"
              puts $fid "    BEGIN"
              puts $fid "      IF (rst_n = '0') THEN"
              puts $fid "        s_$master($i,wbm)_bg_q <= '0';"
              puts $fid "      ELSIF (clk'EVENT AND clk = '1') THEN"
              puts $fid "        IF (s_$master($i,wbm)_bg_q = '0') THEN"
              puts $fid "          s_$master($i,wbm)_bg_q <= s_$master($i,wbm)_bg;"
              puts -nonewline $fid \
                        "        ELSIF (s_ack = '1'"
              if {$master($i,o_tgc)} {
                puts -nonewline $fid " AND (i_$master($i,wbm)_o_${rename_tgc} = \"$classic\" OR i_$master($i,wbm)_o_${rename_tgc} = \"$endofburst\")"
              }
              puts $fid ") THEN"
              puts $fid "          s_$master($i,wbm)_bg_q <= '0';"
              puts $fid "        ELSIF (i_$master($i,wbm)_o_cyc = '0') THEN"
              puts $fid "          s_$master($i,wbm)_bg_q <= '0';"
              puts $fid "        END IF;"
              puts $fid "      END IF;"
              puts $fid "    END PROCESS;"
            }
          }

          # _bg
          for {set tmp 1} {$tmp < $masters} {incr tmp} {
            if {$master($tmp,priority_$slave($j,wbs)) != 0} { break }
          }
#          set tmp 1
#          while {$master($tmp,priority_$slave($j,wbs)) == 0} {
#            incr tmp
#          }

          puts $fid     ""
          puts -nonewline $fid   "    s_idle <= '1' WHEN (s_$master($tmp,wbm)_bg_q = '0'"
          for {set i [expr $tmp + 1]} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts -nonewline $fid " AND s_$master($i,wbm)_bg_q = '0'"
            }
          }
          puts $fid     ") ELSE '0';"
          puts $fid     "    s_$master($tmp,wbm)_bg_1 <= '1' WHEN (s_idle = '1' AND i_$master($tmp,wbm)_o_cyc = '1' AND s_$master($tmp,wbm)_$slave($j,wbs)_ss = '1' AND s_$master($tmp,wbm)_traffic_limit = '0') ELSE '0';"
          puts $fid     "    s_$master($tmp,wbm)_bb_1 <= '1' WHEN (s_$master($tmp,wbm)_bg_1 = '1') ELSE '0';"

          set tmp1 $tmp
          for {set i [expr $tmp + 1]} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts $fid "    s_$master($i,wbm)_bg_1 <= '1' WHEN (s_idle = '1' AND s_$master($tmp1,wbm)_bb_1 = '0' AND i_$master($i,wbm)_o_cyc = '1' AND s_$master($i,wbm)_$slave($j,wbs)_ss = '1' AND s_$master($i,wbm)_traffic_limit = '0') ELSE '0';"
              puts $fid "    s_$master($i,wbm)_bb_1 <= '1' WHEN (s_$master($tmp1,wbm)_bb_1 = '1' OR s_$master($i,wbm)_bg_1 = '1') ELSE '0';"
              set tmp1 $i
            }
          }
          puts $fid     "    s_$master($tmp,wbm)_bg_2 <= '1' WHEN (s_idle = '1' AND s_$master($tmp1,wbm)_bb_1 = '0' AND i_$master($tmp,wbm)_o_cyc = '1' AND s_$master($tmp,wbm)_$slave($j,wbs)_ss = '1') ELSE '0';"
          puts $fid     "    s_$master($tmp,wbm)_bb_2 <= '1' WHEN (s_$master($tmp1,wbm)_bb_1 = '1' OR s_$master($tmp,wbm)_bg_2 = '1') ELSE '0';"

          set tmp1 $tmp
          for {set i [expr $tmp + 1]} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts $fid "    s_$master($i,wbm)_bg_2 <= '1' WHEN (s_idle = '1' AND s_$master($tmp1,wbm)_bb_2 = '0' AND i_$master($i,wbm)_o_cyc = '1' AND s_$master($i,wbm)_$slave($j,wbs)_ss = '1') ELSE '0';"
              puts $fid "    s_$master($i,wbm)_bb_2 <= '1' WHEN (s_$master($tmp1,wbm)_bb_2 = '1' OR s_$master($i,wbm)_bg_2 = '1') ELSE '0';"
              set tmp1 $i
            }
          }
          for {set i 1} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts $fid "    s_$master($i,wbm)_bg <= s_$master($i,wbm)_bg_q OR s_$master($i,wbm)_bg_1 OR s_$master($i,wbm)_bg_2;"
            }
          }
          # ce
          for {set tmp 1} {$tmp < $masters} {incr tmp} {
            if {$master($tmp,priority_$slave($j,wbs)) != 0} { break }
          }
#          set tmp 1
#          while {$master($tmp,priority_$slave($j,wbs)) == 0} {
#            incr tmp
#          }

          puts -nonewline $fid     "    s_ce <= (i_$master($tmp,wbm)_o_cyc AND s_$master($tmp,wbm)_$slave($j,wbs)_ss)"
          for {set i [expr $tmp+1]} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts -nonewline $fid " OR (i_$master($i,wbm)_o_cyc AND s_$master($i,wbm)_$slave($j,wbs)_ss)"
            }
          }

          puts $fid " WHEN (s_idle = '1') ELSE '0';"
          # global bg
          for {set i 1} {$i <= $masters} {incr i} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts $fid "    s_$master($i,wbm)_$slave($j,wbs)_bg <= s_$master($i,wbm)_bg;"
            }
          }
          puts $fid     "  END BLOCK arbiter_$slave($j,wbs);"
        }
      }
    }

  }
}

proc gen_addr_decoder {} {
  uplevel 1 {
    set margin 9

    for {set i 1} {$i <= $slaves} {incr i} {
      if {$slave($i,size) == 0} {
        error "Size shall not be zero (Slave $i)!"
      }
    }

    puts $fid ""
    puts $fid "  decoder : BLOCK"
    if {$type == "sharedbus"} {
      puts $fid "    SIGNAL s_addr : STD_LOGIC_VECTOR($addr_hi DOWNTO $addr_lo);"
      puts $fid "  BEGIN"
      # addr
      puts -nonewline $fid "    s_addr <= (i_$master(1,wbm)_o_addr AND s_$master(1,wbm)_bg)"
      if {$masters > 1} {
        for {set i 2} {$i <= $masters} {incr i} {
          puts -nonewline $fid " OR (i_$master($i,wbm)_o_addr AND s_$master($i,wbm)_bg)"
        }
      }
      puts $fid ";"

      # slave select
      if {$slaves == 1} {
        puts $fid "    s_$slave(1,wbs)_ss     <= '1';"
        puts $fid "    o_$slave(1,wbs)_i_addr <= s_addr($slave(1,i_addr_hi) DOWNTO $slave(1,i_addr_lo));"
      } else {
        for {set i 1} {$i <= $slaves} {incr i} {
          puts $fid "    s_$slave($i,wbs)_ss <="
          puts -nonewline $fid "      '1' WHEN (s_addr($addr_hi DOWNTO [expr int(log($slave($i,size))/log(2.0))]) = \""
          for {set j $addr_hi} {$j >= int(log($slave($i,size))/log(2.0))} {incr j -1} {
            if {$slave($i,addr) >= [expr 1<<$j]} {
              incr slave($i,addr) [expr -(1<<$j)]
              puts -nonewline $fid "1"
            } else {
              puts -nonewline $fid "0"
            }
          }
          puts -nonewline $fid "\""
          # 1
          if {$slave($i,size1) != 0xffffffff} {
            puts $fid ") ELSE"
            puts -nonewline $fid "      '1' WHEN (s_addr($addr_hi DOWNTO [expr int(log($slave($i,size1))/log(2.0))]) = \""
            for {set j $addr_hi} {$j >= int(log($slave($i,size1))/log(2.0))} {incr j -1} {
              if {$slave($i,addr1) >= [expr 1<<$j]} {
                incr slave($i,addr1) [expr -(1<<$j)]
                puts -nonewline $fid "1"
              } else {
                puts -nonewline $fid "0"
              }
            }
            puts -nonewline $fid "\""
          }
          # 2
          if {$slave($i,size2) != 0xffffffff} {
            puts $fid ") ELSE"
            puts -nonewline $fid "      '1' WHEN (s_addr($addr_hi DOWNTO [expr int(log($slave($i,size2))/log(2.0))]) = \""
            for {set j $addr_hi} {$j >= int(log($slave($i,size2))/log(2.0))} {incr j -1} {
              if {$slave($i,addr2) >= [expr 1<<$j]} {
                incr slave($i,addr2) [expr -(1<<$j)]
                puts -nonewline $fid "1"
              } else {
                puts -nonewline $fid "0"
              }
            }
            puts -nonewline $fid "\""
          }
          # 3
          if {$slave($i,size3) != 0xffffffff} {
            puts $fid ") ELSE"
            puts -nonewline $fid "      '1' WHEN (s_addr($addr_hi DOWNTO [expr int(log($slave($i,size3))/log(2.0))]) = \""
            for {set j $addr_hi} {$j >= int(log($slave($i,size3))/log(2.0))} {incr j -1} {
              if {$slave($i,addr3) >= [expr 1<<$j]} {
                incr slave($i,addr3) [expr -(1<<$j)]
                puts -nonewline $fid "1"
              } else {
                puts -nonewline $fid "0"
              }
            }
            puts -nonewline $fid "\""
          }
          puts $fid ") ELSE '0';"
          # addr to slaves
        }
        puts $fid ""
        for {set i 1} {$i <= $slaves} {incr i} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_addr] <= s_addr($slave($i,i_addr_hi) DOWNTO $slave($i,i_addr_lo));"
        }
      }

    } else {
      # crossbar switch
      puts $fid "  BEGIN"
      # master_slave_ss

      for {set i 1} {$i <= $masters} {incr i} {
        for {set j 1} {$j <= $slaves} {incr j} {
          if {$master($i,priority_$slave($j,wbs)) != 0} {
            puts $fid "    s_$master($i,wbm)_$slave($j,wbs)_ss <="
            puts -nonewline $fid "      '1' WHEN (i_$master($i,wbm)_o_addr($addr_hi DOWNTO [expr int(log($slave($j,size))/log(2.0))]) = \""
            set tmp $slave($j,addr)
            for {set k $addr_hi} {$k >= int(log($slave($j,size))/log(2.0))} {incr k -1} {
              if {$tmp >= 1<<$k} {
                incr tmp [expr -(1<<$k)]
                puts -nonewline $fid "1"
              } else {
                puts -nonewline $fid "0"
              }
            }
            puts -nonewline $fid "\""
            # 1
            if {$slave($j,size1) != 0xffffffff} {
              puts $fid ") ELSE"
              puts -nonewline $fid "      '1' WHEN (i_$master($i,wbm)_o_addr($addr_hi DOWNTO [expr int(log($slave($j,size1))/log(2.0))]) = \""
              set tmp $slave($j,addr1)
              for {set k $addr_hi} {$k >= int(log($slave($j,size1))/log(2.0))} {incr k -1} {
                if {$tmp >= 1<<$k} {
                  incr tmp [expr -(1<<$k)]
                  puts -nonewline $fid "1"
                } else {
                  puts -nonewline $fid "0"
                }
              }
              puts -nonewline $fid "\""
            }
            # 2
            if {$slave($j,size2) != 0xffffffff} {
              puts $fid ") ELSE"
              puts -nonewline $fid "      '1' WHEN (i_$master($i,wbm)_o_addr($addr_hi DOWNTO [expr int(log($slave($j,size2))/log(2.0))]) = \""
              set tmp $slave($j,addr2)
              for {set k $addr_hi} {$k >= int(log($slave($j,size2))/log(2.0))} {incr k -1} {
                if {$tmp >= 1<<$k} {
                  incr tmp [expr -(1<<$k)]
                  puts -nonewline $fid "1"
                } else {
                  puts -nonewline $fid "0"
                }
              }
              puts -nonewline $fid "\""
            }
            # 3
            if {$slave($j,size3) != 0xffffffff} {
              puts $fid ") ELSE"
              puts -nonewline $fid "      '1' WHEN (i_$master($i,wbm)_o_addr($addr_hi DOWNTO [expr int(log($slave($j,size3))/log(2.0))]) = \""
              set tmp $slave($j,addr3)
              for {set k $addr_hi} {$k >= int(log($slave($j,size3))/log(2.0))} {incr k -1} {
                if {$tmp >= 1<<$k} {
                  incr tmp [expr -(1<<$k)]
                  puts -nonewline $fid "1"
                } else {
                  puts -nonewline $fid "0"
                }
              }
              puts -nonewline $fid "\""
            }
            #
            puts $fid ") ELSE '0';"
          }
        }
      }

      # _o_addr
      set maargin 3

      for {set i 1} {$i <= $slaves} {incr i} {
        # mux ?
        set tmp 0
        for {set l 1} {$l <= $masters} {incr l} {
          if {$master($l,priority_$slave($i,wbs)) != 0} {
            incr tmp
          }
        }
        if {$tmp == 1} {
          for {set k 1} {$k < $masters} {incr k} {
            if {$master($k,priority_$slave($i,wbs)) != 0} { break }
          }
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_addr] <= i_$master($k,wbm)_o_addr($slave($i,i_addr_hi) DOWNTO $slave($i,i_addr_lo));"
        } else {
          for {set k 1} {$k < $masters} {incr k} {
            if {$master($k,priority_$slave($i,wbs)) != 0} { break }
          }
          puts -nonewline $fid "    [str_len $margin o_$slave($i,wbs)_i_addr] <= (i_$master($k,wbm)_o_addr($slave($i,i_addr_hi) DOWNTO $slave($i,i_addr_lo)) AND s_$master($k,wbm)_$slave($i,wbs)_bg)"
          for {set j [expr $k+1]} {$j <= $masters} {incr j} {
            if {$master($j,priority_$slave($i,wbs)) != 0} {
              puts -nonewline $fid " OR (i_$master($j,wbm)_o_addr($slave($i,i_addr_hi) DOWNTO $slave($i,i_addr_lo)) AND s_$master($j,wbm)_$slave($i,wbs)_bg)"
            }
          }
          puts $fid ";"
        }
      }
    }
    puts $fid "  END BLOCK decoder;\n"
  }
}

proc gen_muxshb {} {
  uplevel 1 {
    set margin 9

    puts $fid   "  mux : BLOCK"
    puts $fid   "    SIGNAL s_cyc      : STD_LOGIC;"
    puts $fid   "    SIGNAL s_stb      : STD_LOGIC;"
    if {$o_tga > 0 && $i_tga > 0} {
      puts $fid "    SIGNAL s_tga      : STD_LOGIC_VECTOR([expr $tga_bits-1] DOWNTO 0);"
    }
    if {$o_tgc > 0 && $i_tgc > 0} {
      puts $fid "    SIGNAL s_tgc      : STD_LOGIC_VECTOR([expr $tgc_bits-1] DOWNTO 0);"
    }
    if {$data_size >= 16} {
      puts $fid "    SIGNAL s_sel      : STD_LOGIC_VECTOR([expr $data_size/8-1] DOWNTO 0);"
    }
    puts $fid   "    SIGNAL s_we       : STD_LOGIC;"
    puts $fid   "    SIGNAL s_data_m2s : STD_LOGIC_VECTOR([expr $data_size-1] DOWNTO 0);"
    puts $fid   "    SIGNAL s_data_s2m : STD_LOGIC_VECTOR([expr $data_size-1] DOWNTO 0);"
    puts $fid   "    SIGNAL s_ack      : STD_LOGIC;"
    if {$i_rty > 0 && $o_rty > 1} {
      puts $fid "    SIGNAL s_rty      : STD_LOGIC;"
    }
    if {$i_err > 0 && $o_err > 1} {
      puts $fid "    SIGNAL s_err      : STD_LOGIC;"
    }
    puts $fid   "  BEGIN"

    ###########################################################################
    # cyc
    puts            $fid "    -- cyc"
    puts -nonewline $fid "    s_cyc <= (i_$master(1,wbm)_o_cyc AND s_$master(1,wbm)_bg)"
    if {$masters > 1} {
      for {set i 2} {$i <= $masters} {incr i} {
        puts -nonewline $fid " OR (i_$master($i,wbm)_o_cyc AND s_$master($i,wbm)_bg)"
      }
    }
    puts $fid ";"
    for {set i 1} {$i <= $slaves} {incr i} {
      puts $fid "    [str_len $margin o_$slave($i,wbs)_i_cyc] <= s_cyc AND s_$slave($i,wbs)_ss;"
    }

    ###########################################################################
    # stb
    puts            $fid "    -- stb"
    puts -nonewline $fid "    s_stb <= (i_$master(1,wbm)_o_stb AND s_$master(1,wbm)_bg)"
    if {$masters > 1} {
      for {set i 2} {$i <= $masters} {incr i} {
        puts -nonewline $fid " OR (i_$master($i,wbm)_o_stb AND s_$master($i,wbm)_bg)"
      }
    }
    puts $fid ";"
    for {set i 1} {$i <= $slaves} {incr i} {
      puts $fid "    [str_len $margin o_$slave($i,wbs)_i_stb] <= s_stb AND s_$slave($i,wbs)_ss;"
    }

    ###########################################################################
    # tga
    if {$o_tga == 0 && $i_tga > 0} {
      puts $fid "    -- ${rename_tga}"
      for {set i 1} {$i <= $slaves} {incr i} {
        if {$slave($i,i_tga) == 1} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_${rename_tga}] <= (OTHERS => '0');"
        }
      }
    } elseif {$o_tga > 0 && $i_tga > 0} {
      puts $fid "    -- ${rename_tga}"
      for {set i 1} {$i < $masters} {incr i} {
        if {$master($i,o_tgc) == 1} { break }
      }
      puts -nonewline $fid "    tga <= (i_$master($i,wbm)_o_${rename_tga} AND s_$master($i,wbm)_bg)"
      for {set j [expr $i+1]} {$j <= $masters} {incr j} {
        if {$master($j,o_tga) == 1} {
          puts -nonewline $fid " OR (i_$master($j,wbm)_o_${rename_tga} AND s_$master($j,wbm)_bg)"
        }
      }
      puts $fid ";"
      for {set i 1} {$i <= $slaves} {incr i} {
        if {$slave($i,i_tga) == 1} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_${rename_tga}] <= s_tga;"
        }
      }
    }
    
    ###########################################################################
    # tgc
    if {$o_tgc == 0 && $i_tgc > 0} {
      puts $fid "    -- ${rename_tgc}"
      for {set i 1} {$i <= $slaves} {incr i} {
        if {$slave($i,i_tgc) == 1} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_${rename_tgc}] <= \"$classic\";"
        }
      }
    } elseif {$o_tgc > 0 && $i_tgc > 0} {
      puts $fid "    -- ${rename_tgc}"
      for {set i 1} {$i < $masters} {incr i} {
        if {$master($i,o_tgc) == 1} { break }
      }
      puts -nonewline $fid "    s_tgc <= (i_$master($i,wbm)_o_${rename_tgc} AND s_$master($i,wbm)_bg)"
      for {set j [expr $i+1]} {$j <= $masters} {incr j} {
        if {$master($j,o_tgc) == 1} {
          puts -nonewline $fid " OR (i_$master($j,wbm)_o_${rename_tgc} AND s_$master($j,wbm)_bg)"
        }
      }
      puts $fid ";"
      for {set i 1} {$i <= $slaves} {incr i} {
        if {$slave($i,i_tgc) == 1} {
          puts $fid "    [str_len $margin o_$slave($i,wbs)_i_${rename_tgc}] <= s_tgc;"
        }
      }
    }

    ###########################################################################
    # sel
    if {$data_size >= 16} {
      puts            $fid "    -- sel"
      puts -nonewline $fid "    s_sel <= (i_$master(1,wbm)_o_sel AND s_$master(1,wbm)_bg)"
      if {$masters > 1} {
        for {set i 2} {$i <= $masters} {incr i} {
          puts -nonewline $fid " OR (i_$master($i,wbm)_o_sel AND s_$master($i,wbm)_bg)"
        }
      }
      puts $fid ";"
      for {set i 1} {$i <= $slaves} {incr i} {
        puts $fid "    [str_len $margin o_$slave($i,wbs)_i_sel] <= s_sel;"
      }
    }

    ###########################################################################
    # we
    puts            $fid "    -- we"
    for {set i 1} {$i < $masters} {incr i} {
      if {$master($i,type) != "ro"} { break }
    }
    puts -nonewline $fid "    s_we <= (i_$master($i,wbm)_o_we AND s_$master($i,wbm)_bg)"
    if {$i < $masters} {
      for {set j [expr $i+1]} {$j <= $masters} {incr j} {
        if {$master($j,type) != "ro"} {
          puts -nonewline $fid " OR (i_$master($j,wbm)_o_we AND s_$master($j,wbm)_bg)"
        }
      }
    }
    puts $fid ";"
    for {set i 1} {$i <= $slaves} {incr i} {
      if {$slave($i,type) != "ro"} {
        puts $fid "    [str_len $margin o_$slave($i,wbs)_i_we] <= s_we;"
      }
    }

    ###########################################################################
    # data m2s
    puts $fid "    -- data m2s"
    for {set i 1} {$i < $masters} {incr i} {
      if {$master($i,type) != "ro"} { break }
    }
    puts -nonewline $fid "    s_data_m2s <= (i_$master($i,wbm)_o_data AND s_$master($i,wbm)_bg)"
    if {$i < $masters} {
      for {set j [expr $i+1]} {$j <= $masters} {incr j} {
        puts -nonewline $fid " OR (i_$master($j,wbm)_o_data AND s_$master($j,wbm)_bg)"
      }
    }
    puts $fid ";"
    for {set i 1} {$i <= $slaves} {incr i} {
      if {$slave($i,type) != "ro"} {
        puts $fid "    [str_len $margin o_$slave($i,wbs)_i_data] <= s_data_m2s;"
      }

    }

    ###########################################################################
    # data s2m
    puts $fid "    -- data s2m"
    for {set i 1} {$i < $slaves} {incr i} {
      if {$slave($i,type) != "wo"} { break }
    }
    puts -nonewline $fid "    s_data_s2m <= (i_$slave($i,wbs)_o_data AND s_$slave($i,wbs)_ss)"
    if {$i < $slaves} {
      for {set j [expr $i+1]} {$j <= $slaves} {incr j} {
        puts -nonewline $fid " OR (i_$slave($j,wbs)_o_data AND s_$slave($j,wbs)_ss)"
      }
    }
    puts $fid ";"
    for {set i 1} {$i <= $masters} {incr i} {
      if {$master($i,type) != "wo"} {
        puts $fid "    [str_len $margin o_$master($i,wbm)_i_data] <= s_data_s2m;"
      }
    }

    ###########################################################################
    # ack
    puts            $fid "    -- ack"
    puts -nonewline $fid "    s_ack <= i_$slave(1,wbs)_o_ack"
    for {set i 2} {$i <= $slaves} {incr i} {
      puts -nonewline $fid " OR i_$slave($i,wbs)_o_ack"
    }
    puts $fid ";"
    for {set i 1} {$i <= $masters} {incr i} {
      puts $fid "    [str_len $margin o_$master($i,wbm)_i_ack] <= s_ack AND s_$master($i,wbm)_bg;"
    }

    ###########################################################################
    # rty
    if {$o_rty == 0 && $i_rty > 0} {
      puts $fid "    -- rty"
      for {set i 1} {$i <= $masters} {incr i} {
        if {$master($i,i_rty)} {
          puts $fid "    [str_len $margin o_$master($i,wbm)_i_rty] <= '0';"
        }
      }
    } elseif {$o_rty == 1 && $i_rty > 0} {
      puts $fid "    -- rty"
      for {set i 1} {$i < $slaves} {incr i} {
        if {$slave($i,o_rty) == 1} { break }
      }
      for {set j 1} {$j <= $masters} {incr j} {
        if {$master($j,i_rty) == 1} {
          puts $fid "    [str_len $margin o_$master($j,wbm)_i_rty] <= i_$slave($i,wbs)_o_rty;"
        }
      }
    } elseif {$o_rty > 1 && $i_rty > 0} {
      puts $fid "    -- rty"
      for {set i 1} {$i < $slaves} {incr i} {
        if {$slave($i,o_rty) == 1} { break }
      }
      puts -nonewline $fid "    s_rty <= i_$slave($i,wbs)_o_rty"
      for {set j [expr $i+1]} {$j <= $slaves} {incr j} {
        if {$slave($j,o_rty) == 1} {
          puts -nonewline $fid " OR i_$slave($j,wbs)_o_rty"
        }
      }
      puts $fid ";"
      for {set i 1} {$i <= $masters} {incr i} {
        if {$master($i,i_rty) == 1} {
          puts $fid "    [str_len $margin o_$master($i,wbm)_i_rty] <= s_rty AND s_$master($i,wbm)_bg;"
        }
      }
    }

    ###########################################################################
    # err
    if {$o_err == 0 && $i_err > 0} {
      puts $fid "    -- err"
      for {set i 1} {$i <= $masters} {incr i} {
        if {$master($i,i_err) == 1} {
          puts $fid "    [str_len $margin o_$master($i,wbm)_i_err] <= '0';"
        }
      }
    } elseif {$o_err == 1 && $i_err > 0} {
      puts $fid "    -- err"
      for {set i 1} {$i < $slaves} {incr i} {
        if {$slave($i,o_err) == 1} { break }
      }
      for {set j 1} {$j <= $masters} {incr j} {
        if {$master($j,i_err) == 1} {
          puts $fid "    [str_len $margin o_$master($j,wbm)_i_err] <= i_$slave($i,wbs)_o_err;"
        }
      }
    } elseif {$o_err > 1 && $i_err > 0} {
      puts $fid "    -- err"
      for {set i 1} {$i < $slaves} {incr i} {
        if {$slave($i,o_err) == 1} { break }
      }
      puts -nonewline $fid "    s_err <= i_$slave($i,wbs)_o_err"
      for {set j [expr $i+1]} {$j <= $slaves} {incr j} {
        if {$slave($j,o_err) == 1} {
          puts -nonewline $fid " OR i_$slave($j,wbs)_o_err"
        }
      }
      puts $fid ";"
      for {set i 1} {$i <= $masters} {incr i} {
        if {$master($i,i_err) == 1} {
          puts $fid "    [str_len $margin o_$master($i,wbm)_i_err] <= s_err AND s_$master($i,wbm)_bg;"
        }
      }
    }

    # end block
    ###########################################################################

    puts $fid "  END BLOCK mux;"
    puts $fid ""
  }
}

proc gen_muxcbs {} {
  uplevel 1 {
    set margin 7
    ###########################################################################
    # cyc
    puts $fid "  -- cyc"
    for {set i 1} {$i <= $slaves} {incr i} {
      for {set tmp 1} {$tmp < $masters} {incr tmp} {
        if {$master($tmp,priority_$slave($i,wbs)) != 0} { break }
      }
      puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_cyc] <= (i_$master($tmp,wbm)_o_cyc AND s_$master($tmp,wbm)_$slave($i,wbs)_bg)"
      for {set j [expr $tmp+1]} {$j <= $masters} {incr j} {
        if {$master($j,priority_$slave($i,wbs)) != 0} {
          puts -nonewline $fid " OR (i_$master($j,wbm)_o_cyc AND s_$master($j,wbm)_$slave($i,wbs)_bg)"
        }
      }
      puts $fid ";"
    }

    ###########################################################################
    # stb
    puts $fid "  -- stb"
    for {set i 1} {$i <= $slaves} {incr i} {
      for {set tmp 1} {$tmp < $masters} {incr tmp} {
        if {$master($tmp,priority_$slave($i,wbs)) != 0} { break }
      }
      puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_stb] <= (i_$master($tmp,wbm)_o_stb AND s_$master($tmp,wbm)_$slave($i,wbs)_bg)"
      for {set j [expr $tmp+1]} {$j <= $masters} {incr j} {
        if {$master($j,priority_$slave($i,wbs)) != 0} {
          puts -nonewline $fid " OR (i_$master($j,wbm)_o_stb AND s_$master($j,wbm)_$slave($i,wbs)_bg)"
        }
      }
      puts $fid ";"
    }

    ###########################################################################
    # tga
    for {set i 1} {$i <= $slaves} {incr i} {
      if {$slave($i,i_tga) == 1} {
        puts $fid "  -- i_tga"
        set tmp 0
        for {set j 1} {$j <= $masters} {incr j} {
          if {$master($j,priority_$slave($i,wbs)) != 0} {
            incr tmp
          }
        }
        if {$tmp == 1} {
          for {set tmp 1} {$tmp < $masters} {incr tmp} {
            if {$master($tmp,priority_$slave($i,wbs)) != 0} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_${rename_tga}] <= i_$master($tmp,wbs)_o_${rename_tga}"
        } else {
          for {set tmp 1} {$tmp < $masters} {incr tmp} {
            if {$master($tmp,priority_$slave($i,wbs)) != 0} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_${rename_tga}] <= (i_$master($tmp,wbs)_o_${rename_tga} AND s_$master($tmp,wbs)_$slave($i,wbs)_bg)"
          for {set j [expr $tmp + 1]} {$j <= $masters} {incr j} {
            if {$master($j,priority_$slave($i,wbs)) != 0} {
              if {$master($j,o_tga) == 1} {
                puts -nonewline $fid " OR (i_$master($j,wbm)_o_${rename_tga} AND s_$master($j,wbs)_$slave($i,wbs)_bg)"
              }
            }
          }
        }
        puts $fid ";"
      }
    }

    ###########################################################################
    # tgc
    for {set i 1} {$i <= $slaves} {incr i} {
      if {$slave($i,i_tgc) == 1} {
        puts $fid "  -- i_tgc"
        set tmp 0
        for {set j 1} {$j <= $masters} {incr j} {
          if {$master($j,priority_$slave($i,wbs)) != 0} {
            incr tmp
          }
        }
        if {$tmp == 1} {
          for {set tmp 1} {$tmp < $masters} {incr tmp} {
            if {$master($tmp,priority_$slave($i,wbs)) != 0} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_${rename_tgc}] <= i_$master($tmp,wbs)_o_${rename_tgc}"
        } else {
          for {set tmp 1} {$tmp < $masters} {incr tmp} {
            if {$master($tmp,priority_$slave($i,wbs)) != 0} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_${rename_tgc}] <= (i_$master($tmp,wbs)_o_${rename_tgc} AND s_$master($tmp,wbs)_$slave($i,wbs)_bg)"
          for {set j [expr $tmp + 1]} {$j <= $masters} {incr j} {
            if {$master($j,priority_$slave($i,wbs)) != 0} {
              if {$master($j,o_tgc) == 1} {
                puts -nonewline $fid " OR (i_$master($j,wbm)_o_${rename_tgc} AND s_$master($j,wbm)_$slave($i,wbs)_bg)"
              } else {
                if {$classic != "000"} {
                  # TODO: correct?? NO WAY!
                  puts -nonewline $fid " OR \"$classic\""
                }
              }

            }
          }
        }
        puts $fid ";"
      }
    }

    ###########################################################################
    # sel
    puts $fid "  -- sel"
    for {set i 1} {$i <= $slaves} {incr i} {
      if {$data_size >= 16} {
        for {set tmp 1} {$tmp < $masters} {incr tmp} {
          if {$master($tmp,priority_$slave($i,wbs)) != 0} { break }
        }
        puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_sel] <= (i_$master($tmp,wbm)_o_sel AND s_$master($tmp,wbm)_$slave($i,wbs)_bg)"
        for {set j [expr $tmp+1]} {$j <= $masters} {incr j} {
          if {$master($j,priority_$slave($i,wbs)) != 0} {
            puts -nonewline $fid " OR (i_$master($j,wbm)_o_sel AND s_$master($j,wbm)_$slave($i,wbs)_bg)"
          }
        }
        puts $fid ";"
      }
    }

    ###########################################################################
    # we
    puts $fid "  -- we"
    for {set i 1} {$i <= $slaves} {incr i} {
      if {$slave($i,type) != "ro"} {
        for {set tmp 1} {$tmp < $masters} {incr tmp} {
          if {$master($tmp,priority_$slave($i,wbs)) != 0 && $master($tmp,type) != "ro"} { break }
        }
        puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_we] <= (i_$master($tmp,wbm)_o_we AND s_$master($tmp,wbm)_$slave($i,wbs)_bg)"
        for {set j [expr $tmp+1]} {$j <= $masters} {incr j} {
          if {$master($j,priority_$slave($i,wbs)) != 0 && $master($j,type) != "ro"} {
            puts -nonewline $fid " OR (i_$master($j,wbm)_o_we AND s_$master($j,wbm)_$slave($i,wbs)_bg)"
          }
        }
        puts $fid ";"
      }
    }

    ###########################################################################
    # data m2s
    puts $fid "  -- data m2s"
    for {set i 1} {$i <= $slaves} {incr i} {
      if {$slave($i,type) != "ro"} {
        set tmp 0
        for {set j 1} {$j <= $masters} {incr j} {
          if {$master($j,priority_$slave($i,wbs)) != 0 && $master($j,type) != "ro"} {
            incr tmp
          }
        }
        if {$tmp == 1} {
          for {set j 1} {$j < $masters} {incr j} {
            if {$master($j,priority_$slave($i,wbs)) != 0 && $master($j,type) != "ro"} { break }
          }
          puts $fid "  [str_len $margin o_$slave($i,wbs)_i_data] <= i_$master($j,wbm)_o_data;"
        } elseif {$tmp >= 1} {
          for {set tmp 1} {$tmp < $masters} {incr tmp} {
            if {$master($tmp,priority_$slave($i,wbs)) != 0 && $master($tmp,type) != "ro"} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$slave($i,wbs)_i_data] <= (i_$master($tmp,wbm)_o_data AND s_$master($tmp,wbm)_$slave($i,wbs)_bg)"
          for {set j [expr $tmp+1]} {$j <= $masters} {incr j} {
            if {$master($j,priority_$slave($i,wbs)) != 0 && $master($j,type) != "ro"} {
              puts -nonewline $fid " OR (i_$master($j,wbm)_o_data AND s_$master($j,wbm)_$slave($i,wbs)_bg)"
            }
          }
          puts $fid ";"
        }
      }
    }

    ###########################################################################
    # data s2m
    puts $fid "  -- data s2m"
    for {set i 1} {$i <= $masters} {incr i} {
      if {$master($i,type) != "wo"} {
        set tmp 0
        for {set j 1} {$j <= $slaves} {incr j} {
          if {$master($i,priority_$slave($j,wbs)) != 0} {
            incr tmp
          }
        }
        if {$tmp == 1} {
          for {set tmp 1} {$tmp < $slaves} {incr tmp} {
            if {$master($i,priority_$slave($tmp,wbs)) != 0} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$master($i,wbm)_i_data] <= i_$slave($tmp,wbs)_o_data"
        } else {
          for {set tmp 1} {$tmp < $slaves} {incr tmp} {
            if {$master($i,priority_$slave($tmp,wbs)) != 0} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$master($i,wbm)_i_data] <= (i_$slave($tmp,wbs)_o_data AND s_$master($i,wbm)_$slave($tmp,wbs)_bg)"
          for {set j [expr $tmp+1]} {$j <= $slaves} {incr j} {
            if {$master($i,priority_$slave($j,wbs)) != 0 && $master($i,type) != "wo"} {
              puts -nonewline $fid " OR (i_$slave($j,wbs)_o_data AND s_$master($i,wbm)_$slave($j,wbs)_bg)"
            }
          }
        }
        puts $fid ";"
      }
    }

    ###########################################################################
    # ack
    puts $fid "  -- ack"
    for {set i 1} {$i <= $masters} {incr i} {
      for {set tmp 1} {$tmp < $slaves} {incr tmp} {
        if {$master($i,priority_$slave($tmp,wbs)) != 0} { break }
      }
      puts -nonewline $fid "  [str_len $margin o_$master($i,wbm)_i_ack] <= (i_$slave($tmp,wbs)_o_ack AND s_$master($i,wbm)_$slave($tmp,wbs)_bg)"
      for {set j [expr $tmp+1]} {$j <= $slaves} {incr j} {
        if {$master($i,priority_$slave($tmp,wbs)) != 0} {
          puts -nonewline $fid " OR (i_$slave($j,wbs)_o_ack AND s_$master($i,wbm)_$slave($j,wbs)_bg)"
        }
      }
      puts $fid ";"
    }

    ###########################################################################
    # rty
    puts $fid "  -- rty"
    for {set i 1} {$i <= $masters} {incr i} {
      if {$master($i,i_rty) == 1} {
        set o_rty 0
        for {set j 1} {$j <= $slaves} {incr j} {
          if {$slave($j,o_rty) == 1 && $master($i,priority_$slave($j,wbs)) != 0} {
            incr o_rty
          }
        }
        if {$o_rty == 0} {
          puts $fid "  [str_len $margin o_$master($i,wbm)_i_rty] <= '0';"
        } else {
          for {set tmp 1} {$tmp < $masters} {incr tmp} {
            if {$master($i,priority_$slave($tmp,wbs)) != 0} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$master($i,wbm)_i_rty] <= (i_$slave($tmp,wbs)_o_rty AND s_$master($i,wbm)_$slave($tmp,wbs)_bg)"
          for {set j [expr $tmp+1]} {$j <= $slaves} {incr j} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts -nonewline $fid " OR (i_$slave($j,wbs)_o_rty AND s_$master($i,wbm)_$slave($j,wbs)_bg)"
            }
          }
          puts $fid ";"
        }
      }
    }

    ###########################################################################
    # err
    puts $fid "  -- err"
    for {set i 1} {$i <= $masters} {incr i} {
      if {$master($i,i_err) == 1} {
        set o_err 0
        for {set j 1} {$j <= $slaves} {incr j} {
          if {$slave($j,o_err) == 1 && $master($i,priority_$slave($j,wbs)) != 0} {
            incr o_err
          }
        }
        if {$o_err == 0} {
          puts $fid "  [str_len $margin o_$master($i,wbm)_i_err] <= '0';"
        } else {
          for {set tmp 1} {$tmp < $slaves} {incr tmp} {
            if {$master($i,priority_$slave($tmp,wbs)) != 0} { break }
          }
          puts -nonewline $fid "  [str_len $margin o_$master($i,wbm)_i_err] <= (i_$slave($tmp,wbs)_o_err AND s_$master($i,wbm)_$slave($tmp,wbs)_bg)"
          for {set j [expr $tmp+1]} {$j <= $slaves} {incr j} {
            if {$master($i,priority_$slave($j,wbs)) != 0} {
              puts -nonewline $fid " OR (i_$slave($j,wbs)_o_err AND s_$master($i,wbm)_$slave($j,wbs)_bg)"
            }
          }
          puts $fid ";"
        }
      }
    }

    # end
    ###########################################################################

    puts $fid ""
  }
}

proc gen_remap {} {
  uplevel 1 {
    for {set i 1} {$i <= $masters} {incr i} {
      if {$master($i,type) != "wo"} {
        puts $fid "  o_$master($i,wbm)_wbm_i.i_data <= s_$master($i,wbm)_i_data;"
      }
      puts $fid   "  o_$master($i,wbm)_wbm_i.i_ack  <= s_$master($i,wbm)_i_ack;"
      if {$master($i,i_err) == 1} {
        puts $fid "  o_$master($i,wbm)_wbm_i.i_err  <= s_$master($i,wbm)_i_err;"
      }
      if {$master($i,i_rty) == 1} {
        puts $fid "  o_$master($i,wbm)_wbm_i.i_rty  <= s_$master($i,wbm)_i_rty;"
      }
      if {$master($i,type) != "ro"} {
        puts $fid "  s_$master($i,wbm)_o_data <= i_$master($i,wbm)_wbm_o.o_data;"
        puts $fid "  s_$master($i,wbm)_o_we   <= i_$master($i,wbm)_wbm_o.o_we;"
      }
      puts $fid   "  s_$master($i,wbm)_o_sel  <= i_$master($i,wbm)_wbm_o.o_sel;"
      puts $fid   "  s_$master($i,wbm)_o_addr <= i_$master($i,wbm)_wbm_o.o_addr;"
      if {$master($i,o_tgc) == 1} {
        puts $fid "  s_$master($i,wbm)_o_${rename_tgc}  <= i_$master($i,wbm)_wbm_o.${rename_tgc}_o;"
      }
      if {$master($i,o_tga) == 1} {
        puts $fid "  s_$master($i,wbm)_o_${rename_tga}  <= i_$master($i,wbm)_wbm_o.${rename_tga}_o;"
      }
      puts $fid   "  s_$master($i,wbm)_o_cyc  <= i_$master($i,wbm)_wbm_o.o_cyc;"
      puts $fid   "  s_$master($i,wbm)_o_stb  <= i_$master($i,wbm)_wbm_o.o_stb;"
    }
    for {set i 1} {$i <= $slaves} {incr i} {
      if {$slave($i,type) != "wo"} {
        puts $fid "  s_$slave($i,wbs)_o_data <= i_$slave($i,wbs)_wbs_o.o_data;"
      }
      puts $fid   "  s_$slave($i,wbs)_o_ack  <= i_$slave($i,wbs)_wbs_o.o_ack;"
      if {$slave($i,o_err) == 1} {
        puts $fid "  s_$slave($i,wbs)_o_err  <= i_$slave($i,wbs)_wbs_o.o_err;"
      }
      if {$slave($i,o_rty) == 1} {
        puts $fid "  s_$slave($i,wbs)_o_rty  <= i_$slave($i,wbs)_wbs_o.o_rty;"
      }
      if {$slave($i,type) != "ro"} {
        puts $fid "  o_$slave($i,wbs)_wbs_i.i_data <= s_$slave($i,wbs)_i_data;"
        puts $fid "  o_$slave($i,wbs)_wbs_i.i_we   <= s_$slave($i,wbs)_i_we;"
      }
      puts $fid   "  o_$slave($i,wbs)_wbs_i.i_sel  <= s_$slave($i,wbs)_i_sel;"
      puts $fid   "  o_$slave($i,wbs)_wbs_i.i_addr <= s_$slave($i,wbs)_i_addr;"
      if {$slave($i,i_tgc) == 1} {
        puts $fid "  o_$slave($i,wbs)_wbs_i.${rename_tgc}_i  <= s_$slave($i,wbs)_i_${rename_tgc};"
      }
      if {$slave($i,i_tga) == 1} {
        puts $fid "  o_$slave($i,wbs)_wbs_i.${rename_tga}_i  <= s_$slave($i,wbs)_i_${rename_tga};"
      }
      puts $fid   "  o_$slave($i,wbs)_wbs_i.i_cyc  <= s_$slave($i,wbs)_i_cyc;"
      puts $fid   "  o_$slave($i,wbs)_wbs_i.i_stb  <= s_$slave($i,wbs)_i_stb;"
    };
  }
}

# -----------------------------------------------------------------------------

set iconName [convName $icon]

init
get_sxl_config

# generate traffic supervision
if {$masters > 1} {
  set file_name [file join [file dirname $vhdl_file] wb_traffic_supervision.vhd]
  if {[catch {open $file_name w} fid]} {
    error "Could not open '$file_name' for output!"
  }
  gen_header_legal
  gen_traffic_ctrl
  close $fid
}

# generate intercon
if {[catch {open $vhdl_file w} fid]} {
  error "Could not open '$vhdl_file' for output!"
}
gen_header_legal
gen_header_notes
gen_entity

puts $fid ""
puts $fid "-------------------------------------------------------------------------------"
puts $fid ""
puts $fid "ARCHITECTURE rtl OF $intercon IS\n"
puts $fid "  FUNCTION \"AND\" ("
puts $fid "    le : STD_LOGIC_VECTOR;"
puts $fid "    ri : STD_LOGIC)"
puts $fid "    RETURN STD_LOGIC_VECTOR IS"
puts $fid "    VARIABLE v_result : STD_LOGIC_VECTOR(le'RANGE);"
puts $fid "  BEGIN"
puts $fid "    FOR i IN le'RANGE LOOP"
puts $fid "      v_result(i) := le(i) AND ri;"
puts $fid "    END LOOP;"
puts $fid "    RETURN v_result;"
puts $fid "  END FUNCTION \"AND\";\n"

if {$signal_groups} {
  gen_sig_remap
}
gen_global_signals

puts $fid ""
puts $fid "BEGIN  -- rtl"

gen_arbiter
gen_addr_decoder
if {$type == "sharedbus"} {
  gen_muxshb
} else {
  gen_muxcbs
}

if {$signal_groups} {
  gen_remap
}

puts $fid "END ARCHITECTURE rtl;"
close $fid

# done
