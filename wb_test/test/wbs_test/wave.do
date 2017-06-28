onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider -height 50 TB_Signals
add wave -noupdate -radix hexadecimal /tb_wbs_test/*
add wave -noupdate -divider -height 50 DUT


add wave -noupdate -radix hexadecimal /tb_wbs_test/gen_dut_std/dut/*
add wave -position 82 -radix decimal  /tb_wbs_test/gen_dut_std/dut/i_wb_data
add wave -position 84 -radix decimal  /tb_wbs_test/gen_dut_std/dut/o_wb_data

add wave -noupdate -radix hexadecimal /tb_wbs_test/gen_dut_notify/dut/*
add wave -position 82 -radix decimal /tb_wbs_test/gen_dut_notify/dut/i_wb_data
add wave -position 84 -radix decimal /tb_wbs_test/gen_dut_notify/dut/o_wb_data


TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {516615 ps} 0} {{Cursor 2} {526615 ps} 0} {{Cursor 3} {543279 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {480791 ps} {572439 ps}
