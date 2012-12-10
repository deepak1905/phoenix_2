echo ""
echo "Compiling fft processor core"
echo ""

vcom addr_gen_unit.vhd cmult1_v2_3_struct.vhdl control_unit.vhd fft_core_top_level.vhd fft_processor_core.vhd interconnect.vhd mux_2_to_1.vhd reg_n_bit.vhd r2_v6_struct.vhdl single_port_RAM.vhd single_port_ROM.vhd

echo ""
echo "fft processor core compilation done...!"