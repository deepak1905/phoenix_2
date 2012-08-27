onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider U0
add wave -noupdate -format Logic /control_unit_tb/tb_clk
add wave -noupdate -format Logic /control_unit_tb/tb_rst
add wave -noupdate -format Logic /control_unit_tb/tb_start
add wave -noupdate -format Literal /control_unit_tb/tb_n
add wave -noupdate -format Logic /control_unit_tb/tb_seta_rw
add wave -noupdate -format Logic /control_unit_tb/tb_setb_rw
add wave -noupdate -format Literal /control_unit_tb/u0/next_state
add wave -noupdate -format Literal /control_unit_tb/u0/current_state
add wave -noupdate -format Logic /control_unit_tb/tb_done
add wave -noupdate -divider U1
add wave -noupdate -format Literal /control_unit_tb/tb_n_1
add wave -noupdate -format Logic /control_unit_tb/tb_seta_rw_1
add wave -noupdate -format Logic /control_unit_tb/tb_setb_rw_1
add wave -noupdate -format Literal /control_unit_tb/u1/next_state
add wave -noupdate -format Literal /control_unit_tb/u1/current_state
add wave -noupdate -format Logic /control_unit_tb/tb_done_1
add wave -noupdate -divider U2
add wave -noupdate -format Literal /control_unit_tb/tb_n_2
add wave -noupdate -format Logic /control_unit_tb/tb_seta_rw_2
add wave -noupdate -format Logic /control_unit_tb/tb_setb_rw_2
add wave -noupdate -format Literal /control_unit_tb/u2/next_state
add wave -noupdate -format Literal /control_unit_tb/u2/current_state
add wave -noupdate -format Logic /control_unit_tb/tb_done_2
add wave -noupdate -divider U3
add wave -noupdate -format Logic /control_unit_tb/tb_seta_rw_3
add wave -noupdate -format Logic /control_unit_tb/tb_setb_rw_3
add wave -noupdate -format Literal /control_unit_tb/u3/next_state
add wave -noupdate -format Literal /control_unit_tb/u3/current_state
add wave -noupdate -format Logic /control_unit_tb/tb_done_3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {120 ns} 0}
configure wave -namecolwidth 138
configure wave -valuecolwidth 87
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
WaveRestoreZoom {0 ns} {552 ns}
