#==============================================================================
set project     "glb_lib"
set fpga_lib    rtl_lib
set icon        WbiTest
set sxl_file    wbi_test.sxl
set vhdl_file   ../vhdl/wbi_test.vhd
#==============================================================================

source ../../../../tcl/sxl/sxl_helper.tcl

package require sxl
namespace import ::sxl::*

#==============================================================================
#  WB INTERCONNECT
#==============================================================================

add_icon $icon {
  type  sharedbus
  desc  "Wishbone Interconnect"
}

#==============================================================================
#  WB MASTERs
#==============================================================================

add_master $icon Wbm_1 {
  type  rw \
  desc  "WB Intercon Master Port 1"
}

add_master $icon Wbm_2 {
  type  rw \
  desc  "WB Intercon Master Port 2"
}

#==============================================================================
#  WB SLAVEs
#==============================================================================

add_slave $icon Wbs_1 {
  block Wbs_1
  type  rw
  addr  0x00000000
  size  0x00000100
  mask  0x000000FF
  desc  "WB Intercon Slave Port 1"
}
add_slave $icon Wbs_2 {
  block Wbs_2
  type  ro
  addr  0x00000200
  size  0x00000010
  mask  0x0000000F
  desc  "WB Intercon Slave Port 2"
}
add_slave $icon Wbs_3 {
  block Wbs_3
  type  rw
  addr  0x00100000
  size  0x00001000
  mask  0x000FFFFF
  desc  "WB Intercon Slave Port 3"
}

#==============================================================================

# create sxl file
sxl_file write $sxl_file

# export to VHDL
source ../../../../tcl/sxl/gen_intercon.tcl

exit
