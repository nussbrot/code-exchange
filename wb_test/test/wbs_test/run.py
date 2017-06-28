###############################################################################
## VUnit specific stuff that you generally don't need to touch
# Make vunit python module importable
from os.path import join, dirname
import os
import sys
import random

path_to_vunit = join(dirname(__file__), '..', '..', '..','..', 'vunit_lib', 'vunit')
sys.path.append(path_to_vunit)
#  -------

from vunit import VUnit

def add_config_for_tb(tb, dic):
    """
    Adds a configuration for the given testbench from the given dict
    """
    config_list = []
    for key in dic:
        config_list.append(str(key) + "=" + str(dic[key]))

    tb.add_config(name=str(config_list), generics=dic)

# path to glb_lib root dir
root = join(dirname(__file__), "..", "..", "..", "..")
# path to local testbench dir
test_path = join(dirname(__file__), "tb")


ui = VUnit.from_argv()
ui.add_array_util()
ui.add_osvvm()
# disable IEEE Warnings
ui.disable_ieee_warnings()
###############################################################################

###############################################################################
## Add Library for the Testbench
tb_lib = ui.add_library("tb_lib")
tb_lib.add_source_files(join(test_path, "tb_wbs_test.vhd"))
###############################################################################

###############################################################################
## Add needed modules from vendor_lib
#vendor_lib = ui.add_library("vendor_lib")
#vendor_lib.add_source_files(join(root, "vendor_lib", "altera", "dev_sync", "src", "vhdl", "*.vhd"))
#vendor_lib.add_source_files(join(root, "vendor_lib", "altera", "dev_mem", "src", "vhdl", "*.vhd"))
###############################################################################

###############################################################################
## Add needed modules from fun_lib
fun_lib = ui.add_library("fun_lib")
fun_lib.add_source_files(join(root, "fun_lib", "math", "src", "vhdl", "*.vhd"))
###############################################################################

###############################################################################
## Add needed modules from rtl_lib
rtl_lib = ui.add_library("rtl_lib")
###############################################################################

###############################################################################
## Add needed modules from sim_lib
sim_lib = ui.add_library("sim_lib")
sim_lib.add_source_files(join(root, "sim_lib", "list", "src", "vhdl", "*.vhd"))
sim_lib.add_source_files(join(root, "sim_lib", "array", "src", "vhdl", "*.vhd"))
sim_lib.add_source_files(join(root, "sim_lib", "wbs_drv_pkg", "src", "vhdl", "*.vhd"))
sim_lib.add_source_files(join(root, "sim_lib", "sim_pkg", "src", "vhdl", "*.vhd"))
sim_lib.add_source_files(join(root, "sim_lib", "text_io", "src", "vhdl", "text_io_func_pkg.vhd"))
# "removed" 'altera_mif_parser_pkg', because of
# Questa/Modelsim has encountered an unexpected internal error: ../../src/vcom/genexpr.c(11050).
# WORKARROUND: must be compiled once with it, then rerun without it...
#sim_lib.add_source_files(join(root, "sim_lib", "text_io", "src", "vhdl", "altera_mif_parser_pkg.vhd"))
###############################################################################

###############################################################################
## Add DUT
tb_lib.add_source_files(join(root, "rtl_lib", "wb_test", "src", "vhdl", "wbs_test.vhd"))
tb_lib.add_source_files(join(root, "rtl_lib", "wb_test", "src", "vhdl", "wbs_test_notify.vhd"))
###############################################################################

###############################################################################
## Add Testbench
tb = tb_lib.entity("tb_wbs_test")
###############################################################################

###############################################################################
## Add TestCases

print("################################################################################")
#for outreg in (0, 1):
#    for bytes in (1, 2, 4):
#        for enableReg in ("FALSE", "TRUE"):
#            width = bytes*8
#            depth = 7
#
#            add_config_for_tb(tb, dict(g_data_bits = width, g_addr_bits = depth, g_tdp_outreg=outreg, g_enable_reg=enableReg))
add_config_for_tb(tb, dict(g_addr_bits = 8, g_use_notify_wbs = "FALSE"))
add_config_for_tb(tb, dict(g_addr_bits = 8, g_use_notify_wbs = "TRUE" ))

###############################################################################
## Start VUnit
ui.set_sim_option('modelsim.vsim_flags.gui', ['-do wave.do'])
ui.main()
###############################################################################
