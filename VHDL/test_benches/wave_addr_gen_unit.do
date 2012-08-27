onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /addr_gen_unit_tb/tb_clk
add wave -noupdate -format Logic /addr_gen_unit_tb/tb_rst
add wave -noupdate -format Logic /addr_gen_unit_tb/tb_start
add wave -noupdate -divider U0_8_PT_FFT
add wave -noupdate -format Literal /addr_gen_unit_tb/tb_n_0
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_count0_0
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_count1_0
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_store0_0
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_store1_0
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_coef0addr_0
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_coef1addr_0
add wave -noupdate -format Logic /addr_gen_unit_tb/tb_done_0
add wave -noupdate -divider U1_16_PT_FFT
add wave -noupdate -format Literal /addr_gen_unit_tb/tb_n_1
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_count0_1
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_count1_1
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_store0_1
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_store1_1
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_coef0addr_1
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_coef1addr_1
add wave -noupdate -format Logic /addr_gen_unit_tb/tb_done_1
add wave -noupdate -divider U2_32_PT_FFT
add wave -noupdate -format Literal /addr_gen_unit_tb/tb_n_2
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_count0_2
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_count1_2
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_store0_2
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_store1_2
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_coef0addr_2
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_coef1addr_2
add wave -noupdate -format Logic /addr_gen_unit_tb/tb_done_2
add wave -noupdate -divider U3_64_PT_FFT
add wave -noupdate -format Literal /addr_gen_unit_tb/tb_n_3
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_count0_3
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_count1_3
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_store0_3
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_store1_3
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_coef0addr_3
add wave -noupdate -format Literal -radix hexadecimal /addr_gen_unit_tb/tb_coef1addr_3
add wave -noupdate -format Logic /addr_gen_unit_tb/tb_done_3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {94 ns} 0}
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
WaveRestoreZoom {0 ns} {250 ns}
