onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /single_port_ram_tb/tb_clk
add wave -noupdate -format Logic /single_port_ram_tb/tb_rw
add wave -noupdate -format Literal /single_port_ram_tb/tb_addr_bus
add wave -noupdate -format Literal -radix hexadecimal /single_port_ram_tb/tb_data_in
add wave -noupdate -format Literal -radix hexadecimal /single_port_ram_tb/tb_data_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {59 ns} 0}
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
