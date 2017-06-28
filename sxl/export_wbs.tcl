#
# export SXL to Wishbone Slave VHDL module
#

package require sxl

namespace eval ::sxl::export_wbs {
  variable tpl_text       {}
  variable tpl_script     [file tail [info script]]
  variable tpl_user       $::tcl_platform(user)
  variable tpl_date       [clock format [clock seconds] -format %d.%m.%Y]
  variable tpl_year       [clock format [clock seconds] -format %Y]
  variable tpl_month      [string trimleft [clock format [clock seconds] -format %m] 0]
  variable tpl_day        [string trimleft [clock format [clock seconds] -format %d] 0]
  variable tpl_project    {}
  variable tpl_block      {}
  variable tpl_file       {}
  variable tpl_module     {}
  variable tpl_wbsize     32
  variable tpl_library    {}
  variable tpl_procedures {-- Write access to 32bit register
  PROCEDURE set_reg (
    i_wr_data     : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_wr_en       : IN    STD_LOGIC_VECTOR(3 DOWNTO 0);
    i_wr_mask     : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s_reg  : INOUT STD_LOGIC_VECTOR) IS
  BEGIN
    FOR i IN s_reg'RANGE LOOP
      IF (i_wr_mask(i) = '1' AND i_wr_en(i/8) = '1') THEN
        s_reg(i) <= i_wr_data(i);
      END IF;
    END LOOP;
  END PROCEDURE set_reg;

  -- Write access to single bit register.
  -- Since the index is lost, we rely on the mask to set the correct value.
  PROCEDURE set_reg (
    i_wr_data     : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_wr_en       : IN    STD_LOGIC_VECTOR(3 DOWNTO 0);
    i_wr_mask     : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s_reg  : INOUT STD_LOGIC) IS
  BEGIN
    FOR i IN i_wr_mask'RANGE LOOP
      IF (i_wr_mask(i) = '1' AND i_wr_en(i/8) = '1') THEN
        s_reg <= i_wr_data(i);
      END IF;
    END LOOP;
  END PROCEDURE set_reg;

  -- Write access to single trigger signal
  PROCEDURE set_trg (
    i_wr_data          : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_wr_en            : IN    STD_LOGIC_VECTOR(3 DOWNTO 0);
    CONSTANT c_wr_mask : IN    NATURAL RANGE 0 TO 31;
    SIGNAL   s_flag    : INOUT STD_LOGIC) IS
  BEGIN
    IF (i_wr_en(c_wr_mask/8) = '1' AND i_wr_data(c_wr_mask) = '1') THEN
      s_flag <= '1';
    ELSE
      s_flag <= '0';
    END IF;
  END PROCEDURE set_trg;

  -- Write access to trigger signal vector
  PROCEDURE set_trg (
    i_wr_data          : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_wr_en            : IN    STD_LOGIC_VECTOR(3 DOWNTO 0);
    CONSTANT c_wr_mask : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL   s_flag    : INOUT STD_LOGIC_VECTOR) IS
  BEGIN
    FOR i IN 0 TO 31 LOOP
      IF (c_wr_mask(i) = '1') THEN
        IF (i_wr_en(i/8) = '1' AND i_wr_data(i) = '1') THEN
          s_flag(i) <= '1';
        ELSE
          s_flag(i) <= '0';
        END IF;
      END IF;
    END LOOP;
  END PROCEDURE set_trg;

  -- Drive Trigger On Write signal
  PROCEDURE set_twr (
    i_wr_en       : IN  STD_LOGIC;
    SIGNAL s_flag : OUT STD_LOGIC) IS
  BEGIN  -- PROCEDURE set_twr
    IF (i_wr_en = '1') THEN
      s_flag <= '1';
    ELSE
      s_flag <= '0';
    END IF;
  END PROCEDURE set_twr;

  -- Drive Trigger On Read signal
  PROCEDURE set_trd (
    i_rd_en       : IN  STD_LOGIC;
    SIGNAL s_flag : OUT STD_LOGIC) IS
  BEGIN  -- PROCEDURE set_trd
    IF (i_rd_en = '1') THEN
      s_flag <= '1';
    ELSE
      s_flag <= '0';
    END IF;
  END PROCEDURE set_trd;

  -- helper to cast integer to slv
  FUNCTION f_reset_cast(number : NATURAL; len : POSITIVE)
      RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN STD_LOGIC_VECTOR(to_unsigned(number, len));
  END FUNCTION f_reset_cast;
  }

  proc error {msg} {
    tk_messageBox -message "ERROR !\n$msg" -icon error -title "SXL Export to VHDL"
    exit
  }

  proc convName {name} {
    return [string trimleft [string tolower [regsub -all {([A-Z])} $name {_\1}]] _]
  }

  proc readWbsTplFile {filename} {
    variable tpl_text
    variable tpl_file

    if {![file exists $filename]} {
      error "<readWbsTplFile>: File '$filename' not found!"
    }
    set fid [open $filename r]
    set tpl_text [read $fid]
    set tpl_file $filename
  }

  proc setTplParameter {par data} {
    variable tpl_user
    variable tpl_date
    variable tpl_year
    variable tpl_month
    variable tpl_day
    variable tpl_project
    variable tpl_block
    variable tpl_file
    variable tpl_module
    variable tpl_wbsize
    variable tpl_library

    if {[info exists $par]} {
      set $par $data
    } else {
      error "<setTplParameter>: Parameter $par does not exist!"
    }
  }

  proc configure {project block template} {
    set blockSize [::sxl::parameter get $block.size]
    if {$blockSize == ""} {
      error "Module size not set in SXL file (parameter block.size)!\nTranslation aborted."
    }
    if {[catch {expr int(log($blockSize)/log(2))} wbsize]} {
      error "Invalid size value '$blockSize'!"
    }
    setTplParameter tpl_project $project
    setTplParameter tpl_wbsize  $wbsize
    setTplParameter tpl_block   $block

    readWbsTplFile $template
  }

  proc exportWbsVhdl {block filename} {
    variable tpl_script
    variable tpl_user
    variable tpl_date
    variable tpl_year
    variable tpl_month
    variable tpl_date
    variable tpl_day
    variable tpl_project
    variable tpl_file
    variable tpl_module
    variable tpl_wbsize
    variable tpl_library
    variable tpl_procedures
    variable tpl_text

    set tpl_module [basename [file tail $filename]]
    # check for export block
    if {![::sxl::block exists $block]} {
      error "<translateTplFile>: Block '$block' does not exist!"
    }

    set tpl_vhdlfile [file tail $filename]

    # replace standard keywords
    set tpl_text [string map [list %TPL_SCRIPT%     $tpl_script]      $tpl_text]
    set tpl_text [string map [list %TPL_USER%       $tpl_user]        $tpl_text]
    set tpl_text [string map [list %TPL_DATE%       $tpl_date]        $tpl_text]
    set tpl_text [string map [list %TPL_MONTH%      $tpl_month]       $tpl_text]
    set tpl_text [string map [list %TPL_YEAR%       $tpl_year]        $tpl_text]
    set tpl_text [string map [list %TPL_DAY%        $tpl_day]         $tpl_text]
    set tpl_text [string map [list %TPL_PROJECT%    $tpl_project]     $tpl_text]
    set tpl_text [string map [list %TPL_TPLFILE%    $tpl_file]        $tpl_text]
    set tpl_text [string map [list %TPL_VHDLFILE%   $tpl_vhdlfile]    $tpl_text]
    set tpl_text [string map [list %TPL_MODULE%     $tpl_module]      $tpl_text]
    set tpl_text [string map [list %TPL_WBSIZE%     $tpl_wbsize]      $tpl_text]
    set tpl_text [string map [list %TPL_LIBRARY%    $tpl_library]     $tpl_text]
    set tpl_text [string map [list %TPL_PROCEDURES% $tpl_procedures]  $tpl_text]

    ####################
    # port declaration #
    ####################
    if {[regexp -line {^(.*)%TPL_PORTS%.*} $tpl_text -> tpl_tap]} {
      set tpl_ports {}

      # add regular ports
      foreach reg [::sxl::register list $block] {
        foreach sig [::sxl::signal list $reg] {
          lassign [split $sig .] b r name
          # port list
          set mode [::sxl::parameter get $sig.mode]
          set pos  [split [::sxl::parameter get $sig.pos] :]
          if {$pos == ""} {
            error "Error! Signal $sig does not carry 'pos' information!"
          } elseif {[llength $pos] == 2} {
            foreach {msb lsb} $pos {}
            incr msb -$lsb
            set type "STD_LOGIC_VECTOR($msb DOWNTO 0)"
          } else {
            set type "STD_LOGIC"
          }
          switch $mode {
            ro {lappend tpl_ports "[format %-25s i_[convName $name]] : IN  $type;"}
            rw {lappend tpl_ports "[format %-25s o_[convName $name]] : OUT $type;"}
            wo {lappend tpl_ports "[format %-25s o_[convName $name]] : OUT $type;"}
            t  {lappend tpl_ports "[format %-25s o_[convName $name]] : OUT $type;"}
            c  {lappend tpl_ports "[format %-25s o_[convName $name]] : OUT $type;"}
          }
        }
        # consider notifier signal(s)
        lassign [split $reg .] b regName
        switch [::sxl::parameter get $reg.notify] {
          ro {lappend tpl_ports "[format %-25s o_[convName $regName]_trd] : OUT STD_LOGIC;"}
          wo {lappend tpl_ports "[format %-25s o_[convName $regName]_twr] : OUT STD_LOGIC;"}
          rw {lappend tpl_ports "[format %-25s o_[convName $regName]_trd] : OUT STD_LOGIC;"
              lappend tpl_ports "[format %-25s o_[convName $regName]_twr] : OUT STD_LOGIC;"}
        }
      }

      # insert text
      set tpl_text [string map "%TPL_PORTS% [list [string trimright [join $tpl_ports \n$tpl_tap] ";"]]" $tpl_text]
    }

    ########################
    # constant declaration #
    ########################
    if {[regexp -line {^(.*)%TPL_CONSTANTS%.*} $tpl_text -> tpl_tap]} {
      set tpl_constants {}
      set has_read_notifier "FALSE"

      foreach reg [::sxl::register list $block] {
        switch [::sxl::parameter get $reg.notify] {
          ro { set has_read_notifier "TRUE" }
          rw { set has_read_notifier "TRUE" }
        }
        lassign [split $reg .] b name
        set addr [::sxl::parameter get $reg.addr]
        lappend tpl_constants "CONSTANT [format %-28s c_addr_[convName $name]] : INTEGER := 16#[format %04X $addr]#;"
      }
      # We add a boolean constant to tell the template if notifier signals are present.
      # The implementation is free to do whatever it wants with this information.
      lappend tpl_constants "CONSTANT [format %-28s c_has_read_notifies] : BOOLEAN := $has_read_notifier;"

      # insert text
      set tpl_text [string map "%TPL_CONSTANTS% [list [join $tpl_constants \n$tpl_tap]]" $tpl_text]
    }

    ########################
    # register declaration #
    ########################
    if {[regexp -line {^(.*)%TPL_REGISTERS%.*} $tpl_text -> tpl_tap]} {
      set tpl_registers {}

      foreach reg [::sxl::register list $block] {
        lassign [split $reg .] b regName
        set regState [::sxl::parameter get $reg.state]
        if {$regState == "constant"} {
          set regReset [::sxl::parameter get $reg.reset]
          if {$regReset == ""} {
            set reset "(OTHERS => '0')"
          } else {
            set reset $regReset
          }
          lappend tpl_registers "SIGNAL [format %-30s s_reg_[convName $regName]] : STD_LOGIC_VECTOR(31 DOWNTO 0)\
                                  := $reset;"
        } else {
          set reset 0

          # collect all reset statements of a register
          foreach sig [::sxl::signal list $reg] {
            lassign [split $sig .] b r sigName
            set sigReset [::sxl::parameter get $sig.reset]
            if {$sigReset != ""} {
              set pos [split [::sxl::parameter get $sig.pos] :]
              if {[llength $pos] == 2} {
                foreach {msb lsb} $pos {}
                set reset [expr $reset | ($sigReset << $lsb)]
              } else {
                set reset [expr $reset | ($sigReset << $pos)]
              }
            }
          }
          lappend tpl_registers "SIGNAL [format %-30s s_reg_[convName $regName]] : STD_LOGIC_VECTOR(31 DOWNTO 0)\
                                  := x\"[format %08X $reset]\";"
        }

      }
      lappend tpl_registers {}

      # add register declarations
      # - which registers are added depends on mode
      # - currently wo and t will generate signal declarations
      foreach sig [::sxl::signal list $block] {
        switch [::sxl::parameter get $sig.mode] {
          "wo" { set prefix wo }
          "t"  { set prefix trg }
          default { puts "register declaration: I will skip $sig."; continue }
        }
        set name [lindex [split $sig "."] 2]
        set pos  [split [::sxl::parameter get $sig.pos] :]
        if {[llength $pos] == 2} {
          foreach {msb lsb} $pos {}
          set type "STD_LOGIC_VECTOR($msb DOWNTO $lsb)"
          set bits [expr $msb - $lsb + 1]
        } else {
          set type "STD_LOGIC"
          set bits 1
        }
        set sigReset [::sxl::parameter get $sig.reset]
        if {$sigReset == ""} {
          set sigReset 0
        }
        # handle default values
        if {$bits > 1} {
          if {$sigReset == 0} {
            set default_value {(OTHERS => '0')}
          } else {
            set default_value {(OTHERS => '1')}
          }
        } else {
            set default_value "'[expr $sigReset & 1]'"
        }
        set signal_declaration "SIGNAL [format %-30s s_${prefix}_[convName $name]] : ${type}\
                := $default_value;"
        lappend tpl_registers $signal_declaration
      }

      # insert text
      set tpl_text [string map "%TPL_REGISTERS% [list [join $tpl_registers \n$tpl_tap]]" $tpl_text]
    }

    ###############################
    # register signal declaration #
    ###############################
    if {[regexp -line {^(.*)%TPL_REGISTER_SIGNALS%.*} $tpl_text -> tpl_tap]} {
      set tpl_register_signals {}

      # add signal declarations
      # - which registers are added depends on mode
      # - currently wo, t, c and rw will generate signal declarations
      foreach sig [::sxl::signal list $block] {
        switch [::sxl::parameter get $sig.mode] {
          "wo" { set prefix wo }
          "t"  { set prefix trg }
          "rw" { set prefix rw }
          "c"  { set prefix const }
          default { puts "I will skip $sig."; continue }
        }
        set name [lindex [split $sig "."] 2]
        set pos  [split [::sxl::parameter get $sig.pos] :]
        if {[llength $pos] == 2} {
          foreach {msb lsb} $pos {}
          set type "STD_LOGIC_VECTOR($msb DOWNTO $lsb)"
          set bits [expr $msb - $lsb + 1]
        } else {
          set type "STD_LOGIC"
          set bits 1
        }
        set sigReset [::sxl::parameter get $sig.reset]
        if {$sigReset == ""} {
          set sigReset 0
        }
        # handle default values
        if {$bits > 1} {
          set default_value "f_reset_cast($sigReset, $bits)"
        } else {
            set default_value "'[expr $sigReset & 1]'"
        }
        set signal_declaration "SIGNAL [format %-30s s_${prefix}_[convName $name]] : ${type}\
                := $default_value;"
        lappend tpl_register_signals $signal_declaration
      }

      # insert text
      set tpl_text [string map "%TPL_REGISTER_SIGNALS% [list [join $tpl_register_signals \n$tpl_tap]]" $tpl_text]
    }

    ##################
    # register reset #
    ##################
    if {[regexp -line {^(.*)%TPL_REG_RESET%.*} $tpl_text -> tpl_tap]} {
      set tpl_reg_reset {}

      # add regular reset expressions
      foreach reg [::sxl::register list $block] {
        lassign [split $reg .] b regName
        set reset 0
        # collect all reset statements of a register
        foreach sig [::sxl::signal list $reg] {
          lassign [split $sig .] b r sigName
          set sigReset [::sxl::parameter get $sig.reset]
          if {$sigReset != ""} {
            set pos [split [::sxl::parameter get $sig.pos] :]
            if {[llength $pos] == 2} {
              foreach {msb lsb} $pos {}
              set reset [expr $reset | ($sigReset << $lsb)]
            } else {
              set reset [expr $reset | ($sigReset << $pos)]
            }
          }
        }
        lappend tpl_reg_reset "[format %-30s s_reg_[convName $regName]] <= x\"[format %08X $reset]\";"

        # consider notifier signal(s)
        switch [::sxl::parameter get $reg.notify] {
          ro {lappend tpl_reg_reset "[format %-30s o_[convName $regName]_trd] <= '0';"}
          wo {lappend tpl_reg_reset "[format %-30s o_[convName $regName]_twr] <= '0';"}
          rw {lappend tpl_reg_reset "[format %-30s o_[convName $regName]_trd] <= '0';"
              lappend tpl_reg_reset "[format %-30s o_[convName $regName]_twr] <= '0';"}
        }
      }

      # add trigger reset expressions
      foreach sig [::sxl::signal list $block] {
        if {[::sxl::parameter get $sig.mode] == "t"} {
          set name [lindex [split $sig "."] 2]
          set pos  [split [::sxl::parameter get $sig.pos] :]
          if {[llength $pos] == 2} {
            lappend tpl_reg_reset "[format %-30s s_trg_[convName $name]] <= (OTHERS => '0');"
          } else {
            lappend tpl_reg_reset "[format %-30s s_trg_[convName $name]] <= '0';"
          }
        }
      }

      # insert text
      set tpl_text [string map "%TPL_REG_RESET% [list [join $tpl_reg_reset \n$tpl_tap]]" $tpl_text]
    }

    #####################
    # register defaults #
    #####################
    if {[regexp -line {^(.*)%TPL_REG_DEFAULT%.*} $tpl_text -> tpl_tap]} {
      set tpl_reg_default {}
      # add trigger default expressions
      foreach sig [::sxl::signal list $block] {
        if {[::sxl::parameter get $sig.mode] == "t"} {
          set name [lindex [split $sig "."] 2]
          set pos  [split [::sxl::parameter get $sig.pos] :]
          if {[llength $pos] == 2} {
            lappend tpl_reg_default "[format %-30s s_trg_[convName $name]] <= (OTHERS => '0');"
          } else {
            lappend tpl_reg_default "[format %-30s s_trg_[convName $name]] <= '0';"
          }
        }
      }
      foreach reg [::sxl::register list $block] {
        lassign [split $reg .] b regName
        # consider notifier signal(s)
        switch [::sxl::parameter get $reg.notify] {
          ro {lappend tpl_reg_default "[format %-30s o_[convName $regName]_trd] <= '0';"}
          wo {lappend tpl_reg_default "[format %-30s o_[convName $regName]_twr] <= '0';"}
          rw {lappend tpl_reg_default "[format %-30s o_[convName $regName]_trd] <= '0';"
              lappend tpl_reg_default "[format %-30s o_[convName $regName]_twr] <= '0';"}
        }
      }
      # insert text
      set tpl_text [string map "%TPL_REG_DEFAULT% [list [join $tpl_reg_default \n$tpl_tap]]" $tpl_text]
    }

    ##################
    # register write #
    ##################
    # Either match TPL_REG_WR or TPL_SIG_WR. What was matched is in tpl_match and will be used
    # to generate different register sets.
    if {[regexp -line {^(.*)(%TPL_REG_WR%|%TPL_SIG_WR%).*} $tpl_text -> tpl_tap tpl_match]} {
      set tpl_reg_wr {}
      set reg_list {}

      foreach reg [::sxl::register list $block] {
        set regState [::sxl::parameter get $reg.state]
        set regName  [lindex [split $reg .] 1]
        set regCmdList {}
        if {$regState != "constant"} {
          # handle RW signals
          set mask 0
          foreach sig [::sxl::signal list $reg] {
            set mode [::sxl::parameter get $sig.mode]
            switch $mode {
              rw {
                set sigName [lindex [split $sig "."] 2]
                set pos  [split [::sxl::parameter get $sig.pos] :]
                foreach {msb lsb} $pos {}
                if {$lsb == ""} {
                  set lsb $msb
                }
                set sigMask [expr ((2**($msb-$lsb+1)-1) << $lsb)]
                set mask [expr $mask | $sigMask ]
                lappend regCmdList "set_reg(s_int_data, s_int_we, x\"[format %08X $sigMask]\", s_rw_[convName $sigName])"
              }
            }
          }
          # Only actually add register/signals if there are rw signals defined.
          if {[llength $regCmdList] != 0} {
            set mask "x\"[format %08X $mask]\""
            set addr [format %-24s c_addr_[convName $regName]]
            # TPL_REG_WR uses the register directly and a consolidated mask.
            # TPL_SIG_WR uses the rw signals instead of the register, each with its own mask.
            switch $tpl_match {
              "%TPL_REG_WR%" {
                lappend tpl_reg_wr "WHEN $addr => set_reg(s_int_data, s_int_we, $mask, s_reg_[convName $regName]);"
              }
              "%TPL_SIG_WR%" {
                set firstCmd [lindex $regCmdList 0]
                lappend tpl_reg_wr "WHEN [format %-24s c_addr_[convName $regName]] => $firstCmd;"
                foreach signal [lreplace $regCmdList 0 0] {
                  lappend tpl_reg_wr "[format %-32s " "] $signal;"
                }
              }
            }
            lappend reg_list $regName
          }

          # handle Trigger/Write-Only signals
          foreach sig [::sxl::signal list $reg] {
            set mode [::sxl::parameter get $sig.mode]
            switch $mode {
              wo {
                set sigName [lindex [split $sig "."] 2]
                set pos  [split [::sxl::parameter get $sig.pos] :]
                foreach {msb lsb} $pos {}
                if {$lsb == ""} {
                  set lsb $msb
                }
                set mask "x\"[format %08X [expr (2**($msb-$lsb+1)-1) << $lsb]]\""
                set cmd "set_reg(s_int_data, s_int_we, $mask, s_wo_[convName $sigName])"
                if {[lsearch $reg_list $regName] < 0} {
                  lappend tpl_reg_wr "WHEN [format %-24s c_addr_[convName $regName]] => $cmd;"
                  lappend reg_list $regName
                } else {
                  lappend tpl_reg_wr "[format %-32s " "] $cmd;"
                }
              }
              t {
                set sigName [lindex [split $sig "."] 2]
                set pos  [split [::sxl::parameter get $sig.pos] :]
                foreach {msb lsb} $pos {}
                if {$lsb == ""} {
                  # This is a single bit signal, it uses the bit position as mask input.
                  set mask $msb
                } else {
                  # This is a multi bit signal, it uses a 32bit mask.
                  set mask "x\"[format %08X [expr (2**($msb-$lsb+1)-1) << $lsb]]\""
                }
                # The function is overloaded to accept both kinds (see above) as mask input.
                set cmd "set_trg(s_int_data, s_int_we, $mask, s_trg_[convName $sigName])"
                if {[lsearch $reg_list $regName] < 0} {
                  lappend tpl_reg_wr "WHEN [format %-24s c_addr_[convName $regName]] => $cmd;"
                  lappend reg_list $regName
                } else {
                  lappend tpl_reg_wr "[format %-32s " "] $cmd;"
                }
              }
            }
          }

          # consider notifier signal(s)
          set notify [::sxl::parameter get $reg.notify]
          set cmd_read  "set_trd(s_int_trd, o_[convName $regName]_trd)"
          set cmd_write "set_twr(s_int_twr, o_[convName $regName]_twr)"
          set cmd {}
          switch $notify {
            ro {lappend cmd $cmd_read}
            wo {lappend cmd $cmd_write}
            rw {lappend cmd $cmd_read $cmd_write}
            default {
              if { $notify != "" } {
                error "register write: I don't know how to handle 'notify $notify'"
              }
            }
          }

          if {[llength $cmd] > 0} {
            # Search if this register already has some assignments to decide whether
            # the WHEN statement is already present or not.
            if {[lsearch $reg_list $regName] < 0} {
              lappend tpl_reg_wr "WHEN [format %-24s c_addr_[convName $regName]] => [lindex $cmd 0];"
              lappend reg_list $regName
            } else {
              lappend tpl_reg_wr "[format %-32s " "] [lindex $cmd 0];"
            }
          }
          # A second command is present
          if {[llength $cmd] > 1} {
            lappend tpl_reg_wr "[format %-32s " "] [lindex $cmd 1];"
          }
        }
      }

      # insert text
      set tpl_text [string map "$tpl_match [list [join $tpl_reg_wr "\n$tpl_tap"]]" $tpl_text]
    }

    ###########################
    # register read read_only #
    ###########################
    if {[regexp -line {^(.*)%TPL_REG_RD%.*} $tpl_text -> tpl_tap]} {
      set tpl_reg_rd {}

      # only ro registers will be read. rw registers are handled by TPL_REG_WR
      # this loop generates a variable for each register which will be assigned all belonging signals in slices
      foreach reg [::sxl::register list $block] {
        set regState [::sxl::parameter get $reg.state]
        if {$regState != "constant"} {
          lassign [split $reg .] b regName
          foreach sig [::sxl::signal list $reg] {
            lassign [split $sig .] b reg name
            switch [::sxl::parameter get $sig.mode] {
              "ro" { set assign "i_[convName $name]" }
              default { puts "register read ro: I will skip $sig."; continue }
            }
            set pos  [split [::sxl::parameter get $sig.pos] :]
            if {[llength $pos] == 2} {
              foreach {msb lsb} $pos {}
              set slice "($msb DOWNTO $lsb)"
            } else {
              set slice "($pos)"
            }
            set target "s_reg_[convName $regName]$slice"
            lappend tpl_reg_rd "[format %-39s $target] <= $assign;"
          }
        }
      }
      # insert text
      set tpl_text [string map "%TPL_REG_RD% [list [join $tpl_reg_rd \n$tpl_tap]]" $tpl_text]
    }

    ###########################
    # register read variables #
    ###########################
    if {[regexp -line {^(.*)%TPL_VAR_RD%.*} $tpl_text -> tpl_tap]} {
      set tpl_var_rd {}

      # c, ro and rw registers can be read
      # this loop generates a variable for each register which will be assigned all belonging signals in slices
      foreach reg [::sxl::register list $block] {
        set regState [::sxl::parameter get $reg.state]
        if {$regState != "constant"} {
          lassign [split $reg .] b regName
          foreach sig [::sxl::signal list $reg] {
            lassign [split $sig .] b reg name
            switch [::sxl::parameter get $sig.mode] {
              "ro" { set assign "i_[convName $name]" }
              "rw" { set assign "s_rw_[convName $name]" }
              "c"  { set assign "s_const_[convName $name]" }
              default { puts "register read: I will skip $sig."; continue }
            }
            set pos  [split [::sxl::parameter get $sig.pos] :]
            if {[llength $pos] == 2} {
              foreach {msb lsb} $pos {}
              set slice "($msb DOWNTO $lsb)"
            } else {
              set slice "($pos)"
            }
            set target "v_tmp_[convName $regName]$slice"
            lappend tpl_var_rd "[format %-39s $target] := $assign;"
          }
        }
      }
      # insert text
      set tpl_text [string map "%TPL_VAR_RD% [list [join $tpl_var_rd \n$tpl_tap]]" $tpl_text]
    }

    #########################
    # register read signals #
    #########################
    if {[regexp -line {^(.*)%TPL_SIG_RD%.*} $tpl_text -> tpl_tap]} {
      set tpl_sig_rd {}

      # ro and rw registers can be read
      # this loop generates a signal for each register which will be assigned all belonging signals in slices
      foreach reg [::sxl::register list $block] {
        set regState [::sxl::parameter get $reg.state]
        if {$regState != "constant"} {
          lassign [split $reg .] b regName
          foreach sig [::sxl::signal list $reg] {
            lassign [split $sig .] b reg name
            switch [::sxl::parameter get $sig.mode] {
              "ro" { set assign "i_[convName $name]" }
              "rw" { set assign "s_rw_[convName $name]" }
              default { puts "register read: I will skip $sig."; continue }
            }
            set pos  [split [::sxl::parameter get $sig.pos] :]
            if {[llength $pos] == 2} {
              foreach {msb lsb} $pos {}
              set slice "($msb DOWNTO $lsb)"
            } else {
              set slice "($pos)"
            }
            set target "s_reg_[convName $regName]$slice"
            lappend tpl_sig_rd "[format %-39s $target] <= $assign;"
          }
        }
      }
      # insert text
      set tpl_text [string map "%TPL_SIG_RD% [list [join $tpl_sig_rd \n$tpl_tap]]" $tpl_text]
    }

    ####################
    # sensitivity list #
    ####################
    if {[regexp -line {^(.*)%TPL_SENS_LIST%.*} $tpl_text -> tpl_tap]} {
      set tpl_sens_list {}

      # ro and rw signals must be in the sensitivity list of a combinatorial process
      foreach reg [::sxl::register list $block] {
        set regState [::sxl::parameter get $reg.state]
        if {$regState != "constant"} {
          lassign [split $reg .] b regName
          foreach sig [::sxl::signal list $reg] {
            lassign [split $sig .] b reg name
            switch [::sxl::parameter get $sig.mode] {
              "ro" { set assign "i_[convName $name]" }
              "rw" { set assign "s_rw_[convName $name]" }
              default { puts "sensitivity list: I will skip $sig."; continue }
            }
            lappend tpl_sens_list $assign
          }
        }
      }
      # insert text
      set tpl_text [string map "%TPL_SENS_LIST% [list [join $tpl_sens_list {, }]]" $tpl_text]
    }

    #########################
    # variable declarations #
    #########################
    if {[regexp -line {^(.*)%TPL_VAR_DEC%.*} $tpl_text -> tpl_tap]} {
      set tpl_var_dec {}

      # c, ro and rw registers can be read
      # this loop declares a variable for each register which has belonging signals of mode rw or ro
      foreach reg [::sxl::register list $block] {
        set regState [::sxl::parameter get $reg.state]
        if {$regState != "constant"} {
          lassign [split $reg .] b regName
          set hasRelevantSignals 0
          foreach sig [::sxl::signal list $reg] {
            switch [::sxl::parameter get $sig.mode] {
              "ro" { set hasRelevantSignals 1; break }
              "rw" { set hasRelevantSignals 1; break }
              "c"  { set hasRelevantSignals 1; break }
            }
          }
          if { $hasRelevantSignals != 0 } {
            lappend tpl_var_dec "VARIABLE [format %-30s "v_tmp_[convName $regName]"] : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');"
          }
        }
      }
      # insert text
      set tpl_text [string map "%TPL_VAR_DEC% [list [join $tpl_var_dec \n$tpl_tap]]" $tpl_text]
    }

    #########################
    # signal declarations #
    #########################
    if {[regexp -line {^(.*)%TPL_SIG_DEC%.*} $tpl_text -> tpl_tap]} {
      set tpl_sig_dec {}

      # ro and rw registers can be read
      # this loop declares a variable for each register which has belonging signals of mode rw or ro
      foreach reg [::sxl::register list $block] {
        set regState [::sxl::parameter get $reg.state]
        if {$regState != "constant"} {
          lassign [split $reg .] b regName
          set hasRelevantSignals 0
          foreach sig [::sxl::signal list $reg] {
            switch [::sxl::parameter get $sig.mode] {
              "ro" { set hasRelevantSignals 1; break }
              "rw" { set hasRelevantSignals 1; break }
            }
          }
          if { $hasRelevantSignals != 0 } {
            lappend tpl_sig_dec "SIGNAL [format %-30s "s_reg_[convName $regName]"] : STD_LOGIC_VECTOR(31 DOWNTO 0);"
          }
        }
      }
      # insert text
      set tpl_text [string map "%TPL_SIG_DEC% [list [join $tpl_sig_dec \n$tpl_tap]]" $tpl_text]
    }

    #######################################
    # Process out mux with case statement #
    #######################################
    if {[regexp -line {^(.*)%TPL_CASE_OUT%.*} $tpl_text -> tpl_tap]} {
      set tpl_case_out {}
      foreach reg [::sxl::register list $block] {
        lassign [split $reg .] b regName
        set regState [::sxl::parameter get $reg.state]
        if {$regState == "constant"} {
          lappend tpl_case_out "[format %-25s s_reg_[convName $regName]] AND x\"FFFFFFFF\" WHEN c_addr_[convName $regName],"
        } else {
          set mask 0
          foreach sig [::sxl::signal list $reg] {
            set mode [::sxl::parameter get $sig.mode]
            if {$mode == "ro" || $mode == "c" || $mode == "rw"} {
              set pos  [split [::sxl::parameter get $sig.pos] :]
              foreach {msb lsb} $pos {}
              if {$lsb == ""} {
                set lsb $msb
              }
              set mask [expr $mask | ((2**($msb-$lsb+1)-1) << $lsb)]
            }
          }
          if {$mask != 0} {
            set addr "c_addr_[convName $regName]"
            set var  "v_tmp_[convName $regName]"
            set mask "x\"[format %08X $mask]\""
            lappend tpl_case_out "WHEN $addr => set($var, $mask);"
          }
        }
      }
      # insert text
      set tpl_text [string map "%TPL_CASE_OUT% [list [join $tpl_case_out \n$tpl_tap]]" $tpl_text]
    }
    #################
    # Wishbone read #
    #################
    if {[regexp -line {^(.*)%TPL_REG_DATA_OUT%.*} $tpl_text -> tpl_tap]} {
      set tpl_reg_data_out {}
      foreach reg [::sxl::register list $block] {
        lassign [split $reg .] b regName
        set regState [::sxl::parameter get $reg.state]
        if {$regState == "constant"} {
          lappend tpl_reg_data_out "[format %-25s s_reg_[convName $regName]] AND x\"FFFFFFFF\" WHEN c_addr_[convName $regName],"
        } else {
          set mask 0
          foreach sig [::sxl::signal list $reg] {
            set mode [::sxl::parameter get $sig.mode]
            if {$mode == "ro" || $mode == "c" || $mode == "rw"} {
              set pos  [split [::sxl::parameter get $sig.pos] :]
              foreach {msb lsb} $pos {}
              if {$lsb == ""} {
                set lsb $msb
              }
              set mask [expr $mask | ((2**($msb-$lsb+1)-1) << $lsb)]
            }
          }
          if {$mask != 0} {
            set addr [::sxl::parameter get $reg.addr]
            lappend tpl_reg_data_out "[format %-25s s_reg_[convName $regName]] AND x\"[format %08X $mask]\" WHEN c_addr_[convName $regName],"
          }
        }
      }
      # insert text
      set tpl_text [string map "%TPL_REG_DATA_OUT% [list [join $tpl_reg_data_out \n$tpl_tap]]" $tpl_text]
    }

    ######################
    # output assignments #
    ######################
    # - TPL_PORT_REG_OUT will map rw registers like: o_signalName <= s_reg_regName(0)
    # - TPL_PORT_SIG_OUT will map rw registers like: o_signalName <= s_rw_signalName
    if {[regexp -line {^(.*)%(TPL_PORT_REG_OUT|TPL_PORT_SIG_OUT)%.*} $tpl_text -> tpl_tap tpl_match]} {
      set tpl_port_out {}

      # add regular output mappings
      foreach sig [::sxl::signal list $block] {
        lassign [split $sig .] b reg signal
        # normalize names
        set reg [convName $reg]
        set signal [convName $signal]

        set mode [::sxl::parameter get $sig.mode]
        set pos  [split [::sxl::parameter get $sig.pos] :]
        if {[llength $pos] == 2} {
          foreach {msb lsb} $pos {}
          set range "($msb DOWNTO $lsb)"
        } else {
          set range ""
        }
        set port [format %-25s o_$signal]
        set name $signal
        # set prefix to empty string, only if the switch sets prefix we will generate an output
        set prefix ""
        switch $mode {
          rw {
            # rw mode differs in the two templates TPL_PORT_REG_OUT and TPL_PORT_SIG_OUT
            if { $tpl_match == "TPL_PORT_REG_OUT" } {
              set name $reg
              set prefix "s_reg_"
              # we must also check if a single index is needed
              if {[llength $pos] == 1} {
                set range "($pos)"
              }
            } else {
              set prefix "s_rw_"
            }
          }
          c  {
            # c mode differs in the two templates TPL_PORT_REG_OUT and TPL_PORT_SIG_OUT
            if { $tpl_match == "TPL_PORT_REG_OUT" } {
              set name $reg
              set prefix "s_reg_"
              # we must also check if a single index is needed
              if {[llength $pos] == 1} {
                set range "($pos)"
              }
            } else {
              set prefix "s_const_"
            }
          }
          wo {set prefix "s_wo_"}
          t {set prefix "s_trg_"}
        }
        # write statement if the prefix is set
        if {$prefix != ""} {
          lappend tpl_port_out "$port <= $prefix$name$range;"
        }
      }
      # insert text
      set tpl_text [string map "%$tpl_match% [list [join $tpl_port_out \n$tpl_tap]]" $tpl_text]
    }

    ######################
    # address validation #
    ######################
    if {[regexp -line {^(.*)%TPL_ADDR_VALIDATION%.*} $tpl_text -> tpl_tap]} {
      set tpl_addr_validation {}
      puts "\n ### Address validation"
      puts   " * check signal count of registers (only registers with signals are used for validation)"
      foreach reg [::sxl::register list $block] {
        lassign [split $reg .] b regName
        set regSigCnt [llength [::sxl::signal list $reg]]
        set regNotify [::sxl::parameter get $reg.notify]
        # add register only in case there are signals or its of type 'notify'
        if { ($regSigCnt > 0) || ($regNotify != "") } {
          puts " - $regName: $regSigCnt -> add"
          lappend tpl_addr_validation "\'1\' WHEN c_addr_[convName $regName],"
        } else {
          puts " - $regName: $regSigCnt -> skip"
        }
      }
      # insert text
      set tpl_text [string map "%TPL_ADDR_VALIDATION% [list [join $tpl_addr_validation \n$tpl_tap]]" $tpl_text]
    }

    ###################
    # write vhdl file #
    ###################
    if {[catch "open $filename w" fid]} {
      error "<exportWbsVhdl>: Could not write to file $filename!"
    } else {
      puts -nonewline $fid $tpl_text
      close $fid
    }
  }

  proc write {filename} {
    variable tpl_block
    exportWbsVhdl $tpl_block $filename
  }

  namespace export convName readWbsTplFile setTplParameter exportWbsVhdl configure write
}
