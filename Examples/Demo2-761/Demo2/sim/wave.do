onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /testbench_demo2/lclk
add wave -noupdate -format Literal /testbench_demo2/clk_counter
add wave -noupdate -format Literal -radix decimal /testbench_demo2/a
add wave -noupdate -format Literal -radix decimal /testbench_demo2/b
add wave -noupdate -format Literal -radix decimal /testbench_demo2/c
add wave -noupdate -format Logic /testbench_demo2/wnr
add wave -noupdate -format Logic /testbench_demo2/nready
add wave -noupdate -format Literal /testbench_demo2/instance_lbemulator/process_step
add wave -noupdate -divider data_producer
add wave -noupdate -format Literal -radix decimal /testbench_demo2/instance_top_level/meb_dti
add wave -noupdate -color Coral -format Logic -itemcolor Coral /testbench_demo2/instance_top_level/meb_wr
add wave -noupdate -format Literal -radix decimal /testbench_demo2/instance_top_level/meb_rdusedw
add wave -noupdate -format Logic /testbench_demo2/instance_top_level/instance_lb_int/meb_rdempty
add wave -noupdate -divider V1495
add wave -noupdate -format Logic /testbench_demo2/nlbres
add wave -noupdate -color Yellow -format Logic -itemcolor Yellow /testbench_demo2/instance_top_level/nready
add wave -noupdate -format Logic /testbench_demo2/nblast
add wave -noupdate -format Literal -radix hexadecimal /testbench_demo2/instance_top_level/lad
add wave -noupdate -format Literal /testbench_demo2/instance_lbemulator/process_step
add wave -noupdate -format Literal -radix decimal /testbench_demo2/instance_top_level/output_c
add wave -noupdate -format Literal -radix decimal /testbench_demo2/instance_top_level/meb_dti
add wave -noupdate -format Logic /testbench_demo2/lclk
add wave -noupdate -format Logic /testbench_demo2/instance_top_level/meb_clr
add wave -noupdate -format Logic /testbench_demo2/instance_top_level/meb_rd
add wave -noupdate -color Coral -format Logic -itemcolor Coral /testbench_demo2/instance_top_level/meb_wr
add wave -noupdate -format Literal -radix decimal /testbench_demo2/instance_top_level/meb_dto
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3273839 ps} 0} {{Cursor 2} {2490000 ps} 0} {{Cursor 3} {0 ps} 0}
configure wave -namecolwidth 106
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 1
update
WaveRestoreZoom {1355932 ps} {2739240 ps}
