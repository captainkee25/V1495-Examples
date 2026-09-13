onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /testbench_demo3/lclk
add wave -noupdate -format Literal /testbench_demo3/clk_counter
add wave -noupdate -divider -height 25 {Local Bus}
add wave -noupdate -format Logic /testbench_demo3/instance_lbemulator/nlbres
add wave -noupdate -format Logic /testbench_demo3/instance_lbemulator/nads
add wave -noupdate -format Logic /testbench_demo3/instance_lbemulator/nready
add wave -noupdate -format Literal /testbench_demo3/instance_lbemulator/lad
add wave -noupdate -format Literal /testbench_demo3/instance_lbemulator/process_step
add wave -noupdate -format Logic /testbench_demo3/instance_lbemulator/nblast
add wave -noupdate -divider -height 25 {Dac Interface F}
add wave -noupdate -format Literal -radix decimal /testbench_demo3/instance_top_level/instance_dac_int_f/dac_data
add wave -noupdate -format Literal -radix decimal /testbench_demo3/instance_top_level/instance_dac_int_f/dac_ch
add wave -noupdate -format Logic /testbench_demo3/instance_top_level/instance_dac_int_f/dac_wr
add wave -noupdate -format Logic /testbench_demo3/instance_top_level/instance_dac_int_f/nldacin
add wave -noupdate -format Logic /testbench_demo3/instance_top_level/instance_dac_int_f/dac_tst
add wave -noupdate -format Literal /testbench_demo3/instance_top_level/instance_dac_int_f/statespi
add wave -noupdate -format Literal /testbench_demo3/instance_top_level/instance_dac_int_f/statedacctrl
add wave -noupdate -format Literal -radix decimal /testbench_demo3/instance_top_level/instance_dac_int_f/spi_cntdata
add wave -noupdate -format Literal -radix decimal /testbench_demo3/instance_top_level/instance_dac_int_f/spi_data
add wave -noupdate -format Logic /testbench_demo3/instance_top_level/instance_dac_int_f/wrspi
add wave -noupdate -format Literal -radix decimal /testbench_demo3/instance_top_level/instance_dac_int_f/value
add wave -noupdate -format Logic /testbench_demo3/instance_top_level/instance_dac_int_f/ncsdac
add wave -noupdate -format Logic /testbench_demo3/instance_top_level/instance_dac_int_f/sck
add wave -noupdate -format Logic /testbench_demo3/instance_top_level/instance_dac_int_f/nldac
add wave -noupdate -format Logic /testbench_demo3/instance_top_level/instance_dac_int_f/sdi
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13931613 ps} 0}
configure wave -namecolwidth 146
configure wave -valuecolwidth 120
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
configure wave -timelineunits ps
update
WaveRestoreZoom {14136460 ps} {18073960 ps}
