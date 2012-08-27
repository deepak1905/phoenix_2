onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /interconnect_tb/tb_clk
add wave -noupdate -format Logic /interconnect_tb/tb_rst
add wave -noupdate -format Logic /interconnect_tb/tb_rw_2
add wave -noupdate -format Literal /interconnect_tb/tb_count0_i_2
add wave -noupdate -format Literal /interconnect_tb/tb_count1_i_2
add wave -noupdate -format Literal /interconnect_tb/tb_store0_i_2
add wave -noupdate -format Literal /interconnect_tb/tb_store1_i_2
add wave -noupdate -format Literal /interconnect_tb/tb_bfy0_add_2
add wave -noupdate -format Literal /interconnect_tb/tb_bfy0_sub_2
add wave -noupdate -format Literal /interconnect_tb/tb_bfy1_add_2
add wave -noupdate -format Literal /interconnect_tb/tb_bfy1_sub_2
add wave -noupdate -format Literal /interconnect_tb/tb_operand0_addr_2
add wave -noupdate -format Literal /interconnect_tb/tb_operand1_addr_2
add wave -noupdate -format Literal /interconnect_tb/tb_operand2_addr_2
add wave -noupdate -format Literal /interconnect_tb/tb_operand3_addr_2
add wave -noupdate -format Literal /interconnect_tb/tb_operand0_out_bfy_2
add wave -noupdate -format Literal /interconnect_tb/tb_operand1_out_bfy_2
add wave -noupdate -format Literal /interconnect_tb/tb_operand2_out_bfy_2
add wave -noupdate -format Literal /interconnect_tb/tb_operand3_out_bfy_2
add wave -noupdate -format Literal /interconnect_tb/validate_operand0_addr_2
add wave -noupdate -format Literal /interconnect_tb/validate_operand1_addr_2
add wave -noupdate -format Literal /interconnect_tb/validate_operand2_addr_2
add wave -noupdate -format Literal /interconnect_tb/validate_operand3_addr_2
add wave -noupdate -format Literal /interconnect_tb/validate_operand0_out_bfy_2
add wave -noupdate -format Literal /interconnect_tb/validate_operand1_out_bfy_2
add wave -noupdate -format Literal /interconnect_tb/validate_operand2_out_bfy_2
add wave -noupdate -format Literal /interconnect_tb/validate_operand3_out_bfy_2
add wave -noupdate -divider U1
add wave -noupdate -format Logic /interconnect_tb/u1/clk
add wave -noupdate -format Logic /interconnect_tb/u1/rst
add wave -noupdate -format Logic /interconnect_tb/u1/rw
add wave -noupdate -format Literal /interconnect_tb/u1/n_width
add wave -noupdate -format Literal /interconnect_tb/u1/count0_i
add wave -noupdate -format Literal /interconnect_tb/u1/count1_i
add wave -noupdate -format Literal /interconnect_tb/u1/store0_i
add wave -noupdate -format Literal /interconnect_tb/u1/store1_i
add wave -noupdate -format Literal /interconnect_tb/u1/operand0_out_bfy
add wave -noupdate -format Literal /interconnect_tb/u1/operand1_out_bfy
add wave -noupdate -format Literal /interconnect_tb/u1/operand2_out_bfy
add wave -noupdate -format Literal /interconnect_tb/u1/operand3_out_bfy
add wave -noupdate -format Literal /interconnect_tb/u1/operand0_addr
add wave -noupdate -format Literal /interconnect_tb/u1/operand1_addr
add wave -noupdate -format Literal /interconnect_tb/u1/operand2_addr
add wave -noupdate -format Literal /interconnect_tb/u1/operand3_addr
add wave -noupdate -format Literal /interconnect_tb/u1/bfy1_sub
add wave -noupdate -format Literal /interconnect_tb/u1/bfy1_add
add wave -noupdate -format Literal /interconnect_tb/u1/bfy0_sub
add wave -noupdate -format Literal /interconnect_tb/u1/bfy0_add
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {100 ns} 0}
configure wave -namecolwidth 234
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
WaveRestoreZoom {0 ns} {200 ns}
