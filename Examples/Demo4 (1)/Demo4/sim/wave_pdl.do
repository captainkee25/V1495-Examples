onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /testbench_demo4/lclk
add wave -noupdate -format Literal /testbench_demo4/clk_counter
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/ext_areset
add wave -noupdate -color Gold -format Logic -itemcolor Gold /testbench_demo4/instance_top_level/instance_gdgen/start_gdl
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/pulse(0)
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/pulse(1)
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/start(0)
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/start(1)
add wave -noupdate -color Blue -format Logic -itemcolor Blue /testbench_demo4/instance_top_level/instance_gdgen/out_pgdl
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/wr_dly_cmd(0)
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/wr_dly(0)
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/wr_dly_cmd(1)
add wave -noupdate -format Logic -height 15 /testbench_demo4/instance_top_level/instance_gdgen/wr_dly(1)
add wave -noupdate -format Literal -radix hexadecimal /testbench_demo4/instance_top_level/instance_gdgen/ddly
add wave -noupdate -format Literal -radix decimal /testbench_demo4/instance_top_level/instance_gdgen/delay_pdl
add wave -noupdate -format Literal -radix decimal /testbench_demo4/instance_top_level/instance_gdgen/gate_pdl
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/ares_pld_1
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/ares_pld_2
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/out1_pdl
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/out2_pdl
add wave -noupdate -format Logic /testbench_demo4/instance_top_level/instance_gdgen/out3_pdl
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {647722 ps} 0}
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
WaveRestoreZoom {626819 ps} {903427 ps}
