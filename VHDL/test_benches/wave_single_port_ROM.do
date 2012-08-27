onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /single_port_rom_tb/tb_clk
add wave -noupdate -format Literal -radix unsigned /single_port_rom_tb/tb_addr_bus
add wave -noupdate -format Literal -radix hexadecimal /single_port_rom_tb/tb_data_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {63 ns} 0}
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
WaveRestoreZoom {250 ns} {750 ns}
