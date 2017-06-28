#==============================================================================
set project         "glb_lib"
set project_root    ../../../..

set block       WbsCfgI2cBridge

set sxl_file    ./wbs_cfg_i2c_bridge.sxl

set tpl_file    $project_root/sxl/tpl/wb_reg_no_rst.tpl.vhd
set header_tpl  $project_root/sxl/tpl/block_driver.tpl.h

set vhdl_file   ../vhdl/wbs_cfg_i2c_bridge.vhd
set header_file ../c/I2cBridgeReg.h

# -----------------------------------------------------------------------------
# bind exporters
source $project_root/tcl/sxl/sxl_helper.tcl
source $project_root/tcl/sxl/export_wbs.tcl
source $project_root/tcl/sxl/export_block_driver.tcl

package require sxl
namespace import ::sxl::*
namespace import ::sxl::export_wbs::*

#===============================================================================
#   Create Wishbone Slave
#===============================================================================

add_block $block  {size 0x00000080 desc "Wishbone I2C Bridge Configuration"}


#===============================================================================
#  REGISTERS
#===============================================================================

add_reg $block Config {addr 0x00 desc "I2C configuration register"}
add_reg $block Status {addr 0x04 desc "I2C status register"}


#===============================================================================
#  SIGNALS
#===============================================================================

add_sig  $block Config   DevAddr   {pos   6:0 mode rw reset 0x10 desc "I2C device address"}
add_sig  $block Config   ClkDiv    {pos 31:16 mode rw reset 0x20 desc "I2C clock divider: value = f(WB clk) / (4*f(400kHz))"}

add_sig  $block Status   Status                         {pos 31:0 mode ro type flag desc "Wishbone I2C bridge - status register"}
add_flag $block Status   Status   I2cCarrierIdle        {pos   31 desc "Live: I2C carrier is unoccupied/idle (1: idle)"}
add_flag $block Status   Status   I2cCoreIdle           {pos   30 desc "Live: I2C core idle (1: idle)"}
add_flag $block Status   Status   I2cCoreEn             {pos   29 desc "Live: I2C core enabled (1: enabled)"}
add_flag $block Status   Status   TrxAccType            {pos   24 desc "Last access type (0: read; 1: write)"}
add_flag $block Status   Status   TrxErrNackRepDevAdr   {pos   14 desc "1: NACK error RX repeated device address"}
add_flag $block Status   Status   TrxErrNackDatLsb      {pos   13 desc "1: NACK error register data least significant Byte"}
add_flag $block Status   Status   TrxErrNackDatMsb      {pos   12 desc "1: NACK error register data most significant Byte"}
add_flag $block Status   Status   TrxErrNackAdrLsb      {pos   11 desc "1: NACK error register address least significant Byte"}
add_flag $block Status   Status   TrxErrNackAdrMsb      {pos   10 desc "1: NACK error register address most significant Byte"}
add_flag $block Status   Status   TrxErrNackDevAdr      {pos    9 desc "1: NACK error device address"}
add_flag $block Status   Status   TrxErrArbRepDevAdr    {pos    8 desc "1: Arbitration error RX repeated device address"}
add_flag $block Status   Status   TrxErrArbRestart      {pos    7 desc "1: Arbitration error RX restart"}
add_flag $block Status   Status   TrxErrArbDatLsb       {pos    6 desc "1: Arbitration error register data least significant Byte"}
add_flag $block Status   Status   TrxErrArbDatMsb       {pos    5 desc "1: Arbitration error register data most significant Byte"}
add_flag $block Status   Status   TrxErrArbAdrLsb       {pos    4 desc "1: Arbitration error register address least significant Byte"}
add_flag $block Status   Status   TrxErrArbAdrMsb       {pos    3 desc "1: Arbitration error register address most significant Byte"}
add_flag $block Status   Status   TrxErrArbDevAdr       {pos    2 desc "1: Arbitration error device address"}
add_flag $block Status   Status   TrxErrArbStart        {pos    1 desc "1: Arbitration error I2C start"}
add_flag $block Status   Status   TrxErrAdr             {pos    0 desc "1: Arbitration error address alignment / Byte select error"}

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

# read template file to variable ::tpl_text
readWbsTplFile  $tpl_file

# translate template file and save VHDL
exportWbsVhdl   $block $vhdl_file

# -----------------------------------------------------------------------------
#   Export to C
# -----------------------------------------------------------------------------

::export_block_driver::createBlockDriver $header_tpl $block $header_file

exit
