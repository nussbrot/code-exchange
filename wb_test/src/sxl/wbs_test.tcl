#==============================================================================
set project         "glb_lib"
set project_root    ../../../..

set block       WbsTest
set block_not   WbsTestNotify

set sxl_file    ./wbs_test.sxl
set sxl_file_not    ./wbs_test_notify.sxl

#==============================================================================

# bind VHDL exporter
source $project_root/tcl/sxl/sxl_helper.tcl
source $project_root/tcl/sxl/export_wbs.tcl

package require sxl
namespace import ::sxl::*
namespace import ::sxl::export_wbs::*

#===============================================================================
#   Create Wishbone Slave
#===============================================================================

add_block $block {size 0x00000100 desc "Wishbone Slave Test"}


#===============================================================================
#  REGISTERS
#===============================================================================

add_reg  $block ReadWrite   {addr 0x0000}
add_reg  $block ReadOnly    {addr 0x0004}
add_reg  $block WriteOnly   {addr 0x0008}
add_reg  $block Trigger     {addr 0x000C}
add_reg  $block Enum        {addr 0x0010}
add_reg  $block NotifyRw    {addr 0x0014 notify rw}
add_reg  $block NotifyRo    {addr 0x0018 notify ro}
add_reg  $block NotifyWo    {addr 0x001C notify wo}

add_reg  $block Const       {addr 0x0020}

#===============================================================================
#  SIGNALS
#===============================================================================

add_sig   $block ReadWrite   RwSlice0               {pos 31:16 mode rw}
add_sig   $block ReadWrite   RwSlice1               {pos 15:8  mode rw}
add_sig   $block ReadWrite   RwBit                  {pos 3     mode rw}
add_sig   $block ReadOnly    RoSlice0               {pos 31:16 mode ro}
add_sig   $block ReadOnly    RoSlice1               {pos 15:8  mode ro}
add_sig   $block ReadOnly    RoBit                  {pos 3     mode ro}
add_sig   $block WriteOnly   WoSlice0               {pos 31:16 mode wo}
add_sig   $block WriteOnly   WoSlice1               {pos 15:8  mode wo}
add_sig   $block WriteOnly   WoBit                  {pos 3     mode wo}
add_sig   $block Trigger     TrSlice0               {pos 31:16 mode t}
add_sig   $block Trigger     TrSlice1               {pos 15:8  mode t}
add_sig   $block Trigger     TrBit                  {pos 3     mode t}
add_sig   $block Enum        EnBit            {pos 31 type enum mode rw reset 1}
add_enum  $block Enum        EnBit  "One"     {value 1}
add_enum  $block Enum        EnBit  "Zero"    {value 0}
add_sig   $block Enum        EnSlice          {pos    13:12 type enum mode rw reset 2}
add_enum  $block Enum        EnSlice  "A"     {value 1}
add_enum  $block Enum        EnSlice  "B"     {value 2}
add_enum  $block Enum        EnSlice  "C"     {value 0}
add_sig   $block NotifyRw    NoRwRwBit                 {pos 31    mode rw}
add_sig   $block NotifyRw    NoRwRwSlice               {pos 30:24 mode rw reset 111}
add_sig   $block NotifyRw    NoRwRoBit                 {pos 23    mode ro}
add_sig   $block NotifyRw    NoRwRoSlice               {pos 22:16 mode ro reset 111}
add_sig   $block NotifyRw    NoRwWoBit                 {pos 15    mode wo}
add_sig   $block NotifyRw    NoRwWoSlice               {pos 14:8  mode wo reset 111}
add_sig   $block NotifyRw    NoRwTrBit                 {pos 7     mode t}
add_sig   $block NotifyRw    NoRwTrSlice               {pos 6:0   mode t reset 111}
add_sig   $block NotifyRo    NoRoRwBit                 {pos 31    mode rw}
add_sig   $block NotifyRo    NoRoRwSlice               {pos 30:24 mode rw reset 111}
add_sig   $block NotifyRo    NoRoRoBit                 {pos 23    mode ro}
add_sig   $block NotifyRo    NoRoRoSlice               {pos 22:16 mode ro reset 111}
add_sig   $block NotifyRo    NoRoWoBit                 {pos 15    mode wo}
add_sig   $block NotifyRo    NoRoWoSlice               {pos 14:8  mode wo reset 111}
add_sig   $block NotifyRo    NoRoTrBit                 {pos 7     mode t}
add_sig   $block NotifyRo    NoRoTrSlice               {pos 6:0   mode t reset 111}
add_sig   $block NotifyWo    NoWoRwBit                 {pos 31    mode rw}
add_sig   $block NotifyWo    NoWoRwSlice               {pos 30:24 mode rw reset 111}
add_sig   $block NotifyWo    NoWoRoBit                 {pos 23    mode ro}
add_sig   $block NotifyWo    NoWoRoSlice               {pos 22:16 mode ro reset 111}
add_sig   $block NotifyWo    NoWoWoBit                 {pos 15    mode wo}
add_sig   $block NotifyWo    NoWoWoSlice               {pos 14:8  mode wo reset 111}
add_sig   $block NotifyWo    NoWoTrBit                 {pos 7     mode t}
add_sig   $block NotifyWo    NoWoTrSlice               {pos 6:0   mode t reset 111}

add_sig   $block Const       ConstBit0                 {pos 7     mode c reset 1}
add_sig   $block Const       ConstBit1                 {pos 6     mode c reset 0}
add_sig   $block Const       ConstSlice0               {pos 31:24 mode c reset 113}
add_sig   $block Const       ConstSlice1               {pos 13:9  mode c reset 17}



# -----------------------------------------------------------------------------
#   Export to SXL
# -----------------------------------------------------------------------------

sxl_file write $sxl_file

# -----------------------------------------------------------------------------
#   Export to VHDL
# -----------------------------------------------------------------------------

set blockSize [parameter get $block.size]
set module    [::sxl::export_wbs::convName $block]
if {$blockSize == ""} {
  error "Module size not set in SXL file (parameter block.size)!\nTranslation aborted."
}
if {[catch {expr int(log($blockSize)/log(2))} wbsize]} {
  error "Invalid size value '$blockSize'!"
}

setTplParameter tpl_project $project
setTplParameter tpl_module  $module
setTplParameter tpl_wbsize  $wbsize

# no reset template
set tpl_file    $project_root/sxl/tpl/wb_reg_no_rst.tpl.vhd
set vhdl_file   ../vhdl/wbs_test.vhd
# read template file to variable ::tpl_text
readWbsTplFile  $tpl_file
# translate template file and save VHDL
exportWbsVhdl   $block $vhdl_file

# faster notify template
set tpl_file    $project_root/sxl/tpl/wb_reg_no_rst_notify.tpl.vhd
set vhdl_file   ../vhdl/wbs_test_notify.vhd
# read template file to variable ::tpl_text
readWbsTplFile  $tpl_file
# translate template file and save VHDL
exportWbsVhdl   $block $vhdl_file

#  read the VHDL file and exchange WbsTest with WbsTestNotify
set fp [open "$vhdl_file" r]
set file_data [read $fp]
close $fp

set fp [open "$vhdl_file" w]
set data [split $file_data "\n"]
foreach line $data {
    # don't change comments
    if { [string first "--" $line] >= 0 } {
        puts $fp $line
    } else {
    # replace wbs_test in all other lines
        puts $fp [string map {"wbs_test" "wbs_test_notify"} $line]
    }
}
close $fp


exit
