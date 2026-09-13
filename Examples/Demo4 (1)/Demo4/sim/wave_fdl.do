onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /testbench_demo4/lclk
add wave -noupdate -format Literal /testbench_demo4/clk_counter
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/ext_areset
add wave -noupdate -format Literal -radix decimal /testbench_demo4/instance_top_level/instance_gdgen/delay_fdl
add wave -noupdate -format Literal -radix decimal /testbench_demo4/instance_top_level/instance_gdgen/gate_fdl
add wave -noupdate -color Gold -format Logic -itemcolor Gold /testbench_demo4/instance_top_level/instance_gdgen/start_gdl
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/nstart(2)
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/pulse(2)
add wave -noupdate -format Literal -radix decimal /testbench_demo4/instance_top_level/instance_gdgen/cclcnt
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/input_a_fdl
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/input_b_fdl
add wave -noupdate -color {Medium Blue} -format Logic -itemcolor {Medium Blue} /testbench_demo4/instance_top_level/instance_gdgen/out_fgdl
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/ares_fld_1
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/ares_fld_2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {703000 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {650526 ps} {923795 ps}
