-------------------------------------------------------------------------------
-- Title      : FFT processor core
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : fft_processor_core.vhd
-- Author     : Deepak Revanna  <deepak.revanna@tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/12/05
-- Platform   : Altera stratix II FPGA
-------------------------------------------------------------------------------
-- Description: The core of fft computation involving butterfly unit, control
--              unit, address generation unit, interconnect
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/09/05  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity fft_core is
  
  generic (
    N_WIDTH      : integer := 7;                                    --ADDR_WIDTH+3
    ADDR_WIDTH   : integer := 4;                                    --Log(N/m) for N point and m memory banks
    DATA_WIDTH   : integer := 32);
  
  port (
    clk          : in  std_logic;                                   --Input clock signal
    rst          : in  std_logic;                                   --Asynchronous reset signal
    N            : in  std_logic_vector(N_WIDTH-1 downto 0);        --Number of FFT points
    f_start      : in  std_logic;                                   --Signal to initiate FFT computation    
    f_done       : out std_logic;                                   --Signal indicating the completion of FFT computation

    f_RW_A       : out std_logic;                                   --RW signal for memory banks setA
    f_Enable_A   : out std_logic;                                   --Enable signal for memory banks setA
    
    --memory bank RAM0 data/address and control signal
    f_addr_0     : out std_logic_vector(ADDR_WIDTH-1 downto 0);     --Address bus    
    f_data_in_0  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from RAM0
    f_data_out_0 : out std_logic_vector(DATA_WIDTH-1 downto 0);     --Output data to RAM0

    f_addr_1     : out std_logic_vector(ADDR_WIDTH-1 downto 0);     --Address bus    
    f_data_in_1  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from RAM1
    f_data_out_1 : out std_logic_vector(DATA_WIDTH-1 downto 0);     --Output data to RAM1

    f_addr_2     : out std_logic_vector(ADDR_WIDTH-1 downto 0);     --Address bus    
    f_data_in_2  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from RAM2
    f_data_out_2 : out std_logic_vector(DATA_WIDTH-1 downto 0);     --Output data to RAM2

    f_addr_3     : out std_logic_vector(ADDR_WIDTH-1 downto 0);     --Address bus    
    f_data_in_3  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from RAM3
    f_data_out_3 : out std_logic_vector(DATA_WIDTH-1 downto 0);     --Output data to RAM3

    f_RW_B       : out std_logic;                                   --RW signal for memory banks setB
    f_Enable_B   : out std_logic;                                   --Enable signal for memory banks setB
    
    --memory bank RAM4 data/address and control signal
    f_addr_4     : out std_logic_vector(ADDR_WIDTH-1 downto 0);     --Address bus
    f_data_in_4  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from RAM4
    f_data_out_4 : out std_logic_vector(DATA_WIDTH-1 downto 0);     --Output data to RAM4

    f_addr_5     : out std_logic_vector(ADDR_WIDTH-1 downto 0);     --Address bus
    f_data_in_5  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from RAM5
    f_data_out_5 : out std_logic_vector(DATA_WIDTH-1 downto 0);     --Output data to RAM5

    f_addr_6     : out std_logic_vector(ADDR_WIDTH-1 downto 0);     --Address bus
    f_data_in_6  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from RAM6
    f_data_out_6 : out std_logic_vector(DATA_WIDTH-1 downto 0);     --Output data to RAM6

    f_addr_7     : out std_logic_vector(ADDR_WIDTH-1 downto 0);     --Address bus
    f_data_in_7  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from RAM7
    f_data_out_7 : out std_logic_vector(DATA_WIDTH-1 downto 0);     --Output data to RAM7

    --memory bank ROM0 data/address signals
    f_addr_8     : out std_logic_vector(ADDR_WIDTH+1 downto 0);     --Address    
    f_data_in_8  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     --Input data from ROM0

    --memory bank ROM1 data/address signals
    f_addr_9     : out std_logic_vector(ADDR_WIDTH+1 downto 0);     --Address
    f_data_in_9  : in  std_logic_vector(DATA_WIDTH-1 downto 0));    --Input data from ROM1
  
end fft_core;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


architecture rtl of fft_core is
  --Component declarations
  
  --Address generation unit
  component addr_gen_unit
  
    generic (
      ADDR_WIDTH  : integer;
      N_width     : integer);

    port (
      clk           : in  std_logic;
      rst           : in  std_logic;
      N             : in  std_logic_vector(N_width-1 downto 0);            
      a_start       : in  std_logic;
      a_begin_stage : in std_logic;
      a_read_data   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      a_read_data1  : out std_logic_vector(ADDR_WIDTH-1 downto 0);      
      a_store_add   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      a_store_sub   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      a_Coef0Addr   : out std_logic_vector(ADDR_WIDTH+1 downto 0);
      a_Coef1Addr   : out std_logic_vector(ADDR_WIDTH+1 downto 0);
      a_done        : out std_logic);
  end component;
  
  
  --Control unit
  component control_unit
    generic (
      N_width                : integer);

  port (
    clk                      : in  std_logic;
    rst                      : in  std_logic;
    c_start                  : in  std_logic;
    N                        : in  std_logic_vector(N_width-1 downto 0);
    c_begin_stage            : out std_logic;
    c_input_flip             : out std_logic;
    c_add_sub                : out std_logic;
    c_load                   : out std_logic;
    c_load1                  : out std_logic;
    c_load_P                 : out std_logic;
    c_load_P2                : out std_logic;
    c_load_Q                 : out std_logic;
    c_load_W                 : out std_logic;
    c_sel                    : out std_logic;
    c_SetA_RW                : out std_logic;
    c_SetB_RW                : out std_logic;
    c_SetA_EN                : out std_logic;
    c_SetB_EN                : out std_logic;
    c_last_stage             : out std_logic;
    c_bfy0_ip0_reg_load      : out std_logic;
    c_bfy0_ip1_reg_load      : out std_logic;
    c_bfy0_mux_sel           : out std_logic;
    c_bfy0_tw_reg_load       : out std_logic;
    c_bfy0_tw_sel            : out std_logic;
    c_bfy0_add_op_reg_load   : out std_logic;
    c_bfy0_sub_op_reg_load   : out std_logic;
    c_bfy0_tw_addr_reg_load  : out std_logic;
    c_bfy1_ip0_reg_load      : out std_logic;
    c_bfy1_ip1_reg_load      : out std_logic;
    c_bfy1_mux_sel           : out std_logic;
    c_bfy1_tw_reg_load       : out std_logic;
    c_bfy1_tw_sel            : out std_logic;
    c_bfy1_add_op_reg_load   : out std_logic;
    c_bfy1_sub_op_reg_load   : out std_logic;
    c_bfy1_tw_addr_reg_load  : out std_logic;
    c_done                   : out std_logic);
  end component;


  --Interconnect unit
  component interconnect
    generic (
      ADDR_WIDTH         : integer;
      N_width            : integer;
      DATA_WIDTH         : integer);
    
    port (
      clk                : in  std_logic;
      rst                : in  std_logic;
      i_RW               : in  std_logic;
      i_last_stage       : in  std_logic;
      i_input_flip       : in  std_logic;
      i_read_data        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      i_read_data1       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);      
      i_store_add        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      i_store_sub        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);

      i_bfy0_in_first    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      i_bfy0_in_second   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      i_bfy1_in_first    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      i_bfy1_in_second   : in  std_logic_vector(DATA_WIDTH-1 downto 0);

      i_bfy0_out_first   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      i_bfy0_out_second  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      i_bfy1_out_first   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      i_bfy1_out_second  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      i_data_in_RAM0     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      i_data_in_RAM1     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      i_data_in_RAM2     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      i_data_in_RAM3     : in  std_logic_vector(DATA_WIDTH-1 downto 0);

      i_data_out_RAM0    : out std_logic_vector(DATA_WIDTH-1 downto 0);
      i_data_out_RAM1    : out std_logic_vector(DATA_WIDTH-1 downto 0);
      i_data_out_RAM2    : out std_logic_vector(DATA_WIDTH-1 downto 0);
      i_data_out_RAM3    : out std_logic_vector(DATA_WIDTH-1 downto 0);      
      
      i_addr_RAM0        : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      i_addr_RAM1        : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      i_addr_RAM2        : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      i_addr_RAM3        : out std_logic_vector(ADDR_WIDTH-1 downto 0));
  end component;
  
  
  --Butterfly unit
  component R2_V6
    port (
      PQI     : in  std_logic_vector(15 downto 0);
      PQ_R    : in  std_logic_vector(15 downto 0);
      WRI     : in  std_logic_vector(15 downto 0);
      add_sub : in  std_logic;
      clk     : in  std_logic;
      load    : in  std_logic;
      load1   : in  std_logic;
      load_P  : in  std_logic;
      load_P2 : in  std_logic;
      load_Q  : in  std_logic;
      load_W  : in  std_logic;
      rst     : in  std_logic;
      sel     : in  std_logic;
      imagout : out std_logic_vector(15 downto 0);
      realout : out std_logic_vector(15 downto 0));
  end component;
  
  
  --2 to 1 multiplexer
  component mux_2_to_1
    generic (
      DATA_WIDTH : integer);
      port (
      input0     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      input1     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      sel        : in  std_logic;
      output     : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;
  
  

  --N-bit register
  component reg_n_bit
    generic (
      DATA_WIDTH : integer);

    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      load       : in  std_logic;
      data_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      data_out   : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;


--signal declarations

  --Control unit signals
  signal s_bfy0_PQI_R, s_bfy1_PQI_R, s_bfy0_WRI, s_bfy1_WRI                                          : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_WRI_0, s_WRI_1, s_bfy0_imagout, s_bfy0_realout, s_bfy1_imagout, s_bfy1_realout            : std_logic_vector(15 downto 0)            := (others => '0');
  signal s_bfy0_real_imag_x, s_bfy0_real_imag_y                                                      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_bfy1_real_imag_x, s_bfy1_real_imag_y                                                      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_add_sub, s_load, s_load1, s_load_P, s_load_P2, s_load_Q, s_load_W, s_sel                  : std_logic                                := '0';
  signal s_SetA_RW, s_SetB_RW, s_SetA_EN, s_SetB_EN                                                  : std_logic                                := '0';
  signal s_bfy0_ip0_reg_load, s_bfy0_ip1_reg_load, s_bfy0_mux_sel, s_bfy0_tw_reg_load, s_bfy0_tw_sel : std_logic;
  signal s_bfy1_ip0_reg_load, s_bfy1_ip1_reg_load, s_bfy1_mux_sel, s_bfy1_tw_reg_load, s_bfy1_tw_sel : std_logic;
  signal s_bfy0_add_op_reg_load, s_bfy0_sub_op_reg_load                                              : std_logic;
  signal s_bfy1_add_op_reg_load, s_bfy1_sub_op_reg_load                                              : std_logic;
  signal s_bfy0_out_first, s_bfy0_out_second, s_bfy1_out_first, s_bfy1_out_second                    : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal s_bfy1_add, s_bfy1_sub                                                                      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_c_last_stage                                                                              : std_logic;
  signal s_bfy0_tw_addr_reg_load, s_bfy1_tw_addr_reg_load                                            : std_logic;
  signal s_begin_stage, s_input_flip                                                                 : std_logic;

  --Address generation unit signals
  signal s_count0, s_count1                                                                          : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_store0, s_store1                                                                          : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_Coef0Addr, s_Coef1Addr                                                                    : std_logic_vector(ADDR_WIDTH+1 downto 0);
  signal s_done                                                                                      : std_logic;

  --Multiplexers at butterfly inputs
  signal s_mux0_op, s_mux1_op                                                                        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_mux4_op, s_mux5_op                                                                        : std_logic_vector(DATA_WIDTH-1 downto 0);

  --Registers required at the interface between butterfly inputs
  --and the memory output
  signal s_bfy0_ip0, s_bfy0_ip1                                                                      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_bfy1_ip0, s_bfy1_ip1                                                                      : std_logic_vector(DATA_WIDTH-1 downto 0);

  --Interconnect signals
  signal s_read_data, s_read_data1, s_store_add, s_store_sub                                         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_bfy0_in_first_A, s_bfy0_in_second_A, s_bfy1_in_first_A, s_bfy1_in_second_A                : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_bfy0_in_first_B, s_bfy0_in_second_B, s_bfy1_in_first_B, s_bfy1_in_second_B                : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_data_in_RAM0_A, s_data_in_RAM1_A, s_data_in_RAM2_A, s_data_in_RAM3_A                      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_data_in_RAM0_B, s_data_in_RAM1_B, s_data_in_RAM2_B, s_data_in_RAM3_B                      : std_logic_vector(DATA_WIDTH-1 downto 0);  
  signal s_data_out_RAM0_A, s_data_out_RAM1_A, s_data_out_RAM2_A, s_data_out_RAM3_A                  : std_logic_vector(DATA_WIDTH-1 downto 0);  
  signal s_data_out_RAM0_B, s_data_out_RAM1_B, s_data_out_RAM2_B, s_data_out_RAM3_B                  : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  -------------------------------------------------------------------------------
  
begin  -- rtl

  --Component instantiations
  
  --Control unit
  U1: control_unit
    generic map (
      N_width                 => N_WIDTH)
    
    port map (
      clk                     => clk,
      rst                     => rst,
      c_start                 => f_start,
      N                       => N,
      c_begin_stage           => s_begin_stage,
      c_input_flip            => s_input_flip,
      c_add_sub               => s_add_sub,
      c_load                  => s_load,
      c_load1                 => s_load1,
      c_load_P                => s_load_P,
      c_load_P2               => s_load_P2,
      c_load_Q                => s_load_Q,
      c_load_W                => s_load_W,
      c_sel                   => s_sel,
      c_SetA_RW               => s_SetA_RW,
      c_SetB_RW               => s_SetB_RW,
      c_SetA_EN               => s_SetA_EN,
      c_SetB_EN               => s_SetB_EN,
      c_last_stage            => s_c_last_stage,
      c_bfy0_ip0_reg_load     => s_bfy0_ip0_reg_load,
      c_bfy0_ip1_reg_load     => s_bfy0_ip1_reg_load,
      c_bfy0_mux_sel          => s_bfy0_mux_sel,
      c_bfy0_tw_reg_load      => s_bfy0_tw_reg_load,
      c_bfy0_tw_sel           => s_bfy0_tw_sel,
      c_bfy0_add_op_reg_load  => s_bfy0_add_op_reg_load,
      c_bfy0_sub_op_reg_load  => s_bfy0_sub_op_reg_load,
      c_bfy0_tw_addr_reg_load => s_bfy0_tw_addr_reg_load,
      c_bfy1_ip0_reg_load     => s_bfy1_ip0_reg_load,
      c_bfy1_ip1_reg_load     => s_bfy1_ip1_reg_load,
      c_bfy1_mux_sel          => s_bfy1_mux_sel,
      c_bfy1_tw_reg_load      => s_bfy1_tw_reg_load,
      c_bfy1_tw_sel           => s_bfy1_tw_sel,
      c_bfy1_add_op_reg_load  => s_bfy1_add_op_reg_load,
      c_bfy1_sub_op_reg_load  => s_bfy1_sub_op_reg_load,
      c_bfy1_tw_addr_reg_load => s_bfy1_tw_addr_reg_load,
      c_done                  => f_done);

     f_RW_A       <= s_SetA_RW;                           --Feed the read-write control signal for the memory bank set A
     f_Enable_A   <= s_SetA_EN;
     f_RW_B       <= s_SetB_RW;                           --Feed the read-write control signal for the memory bank set B
     f_Enable_B   <= s_SetB_EN;
	 
     f_data_out_0 <= s_data_out_RAM0_A;                   --Data to RAM memory banks
     f_data_out_1 <= s_data_out_RAM1_A;
     f_data_out_2 <= s_data_out_RAM2_A;
     f_data_out_3 <= s_data_out_RAM3_A;
  
     f_data_out_4 <= s_data_out_RAM0_B;
     f_data_out_5 <= s_data_out_RAM1_B;
     f_data_out_6 <= s_data_out_RAM2_B;
     f_data_out_7 <= s_data_out_RAM3_B;
	 
     s_data_in_RAM0_A <= f_data_in_0;                     --Data from RAM memory banks
     s_data_in_RAM1_A <= f_data_in_1;
     s_data_in_RAM2_A <= f_data_in_2;
     s_data_in_RAM3_A <= f_data_in_3;

     s_data_in_RAM0_B <= f_data_in_4;                     --Data from RAM memory banks
     s_data_in_RAM1_B <= f_data_in_5;
     s_data_in_RAM2_B <= f_data_in_6;
     s_data_in_RAM3_B <= f_data_in_7;    

  
  MUX0: mux_2_to_1                                        --Mux to select data read from RAM and going to butterfly unit0
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      input0     => s_bfy0_in_first_A,
      input1     => s_bfy0_in_first_B,
      sel        => s_SetA_RW,
      output     => s_mux0_op );


  MUX1: mux_2_to_1                                        --Mux to select data read from RAM and going to butterfly unit0
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      input0     => s_bfy0_in_second_A,
      input1     => s_bfy0_in_second_B,
      sel        => s_SetA_RW,
      output     => s_mux1_op );

  
  REG0: reg_n_bit                                         --Register to store the output of MUX0 above
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy0_ip0_reg_load,
      data_in    => s_mux0_op,
      data_out   => s_bfy0_ip0 );


  REG1: reg_n_bit                                         --Register to store the output of MUX1 above
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy0_ip1_reg_load,
      data_in    => s_mux1_op,
      data_out   => s_bfy0_ip1 );


  MUX2: mux_2_to_1                                        --Mux to select the one input in each clock out of the two inputs required by the butterfly unit0
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      input0     => s_bfy0_ip0,
      input1     => s_bfy0_ip1,
      sel        => s_bfy0_mux_sel,
      output     => s_bfy0_PQI_R);

  
  REG2: reg_n_bit                                         --Register to store the twiddle factor from ROM0 going to butterfly unit0
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy0_tw_reg_load,
      data_in    => f_data_in_8,
      data_out   => s_bfy0_WRI);

    
  MUX3: mux_2_to_1                                        --Mux to split 32-bit twiddle factor register to 16-bit real and imaginary parts in consecutive clock cycles
    generic map (
      DATA_WIDTH => 16)
    port map (
      input0     => s_bfy0_WRI(15 downto 0),
      input1     => s_bfy0_WRI(31 downto 16),
      sel        => s_bfy0_tw_sel,
      output     => s_WRI_0);

  
  U6: R2_V6                                               --Butterfly unit0
    port map (
      PQI                => s_bfy0_PQI_R(15 downto 0),
      PQ_R               => s_bfy0_PQI_R(DATA_WIDTH-1 downto 16),
      WRI                => s_WRI_0,
      add_sub            => s_add_sub,
      clk                => clk,
      load               => s_load,
      load1              => s_load1,
      load_P             => s_load_P,
      load_P2            => s_load_P2,
      load_Q             => s_load_Q,
      load_W             => s_load_W,
      rst                => rst,
      sel                => s_sel,
      imagout            => s_bfy0_imagout,
      realout            => s_bfy0_realout);

      s_bfy0_real_imag_y <= s_bfy0_realout & s_bfy0_imagout; --Combine real and imaginary parts into one unit  
  
 
  REG3: reg_n_bit                                            --Register to hold the addition output result from butterfly unit0
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk               => clk,
      rst               => rst,
      load              => s_bfy0_add_op_reg_load,
      data_in           => s_bfy0_real_imag_y,
      data_out          => s_bfy0_out_first);

     s_bfy0_real_imag_x <= s_bfy0_realout & s_bfy0_imagout; --Combine real and imaginary parts into one unit

  
  REG4: reg_n_bit                                           --Register to hold the subtraction output result from butterfly unit0
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy0_sub_op_reg_load,
      data_in    => s_bfy0_real_imag_x,
      data_out   => s_bfy0_out_second);
  
  
  MUX4: mux_2_to_1                                          --Mux to select data read from RAM and going to butterfly unit1
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      input0     => s_bfy1_in_first_A,
      input1     => s_bfy1_in_first_B,
      sel        => s_SetA_RW,
      output     => s_mux4_op );


  MUX5: mux_2_to_1                                          --Mux to select data read from RAM and going to butterfly unit1
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      input0     => s_bfy1_in_second_A,
      input1     => s_bfy1_in_second_B,
      sel        => s_SetA_RW,
      output     => s_mux5_op );


  REG5: reg_n_bit                                           --Register to store the output of MUX4 above
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy1_ip0_reg_load,
      data_in    => s_mux4_op,
      data_out   => s_bfy1_ip0);

  
  REG6: reg_n_bit                                           --Register to store the output of MUX5 above
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy1_ip1_reg_load,
      data_in    => s_mux5_op,
      data_out   => s_bfy1_ip1 );

  
  MUX6: mux_2_to_1                                          --Mux to select the one input in each clock out of the two inputs required by the butterfly unit1
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      input0     => s_bfy1_ip0,
      input1     => s_bfy1_ip1,
      sel        => s_bfy1_mux_sel,
      output     => s_bfy1_PQI_R );


  REG7: reg_n_bit                                           --Register to store the twiddle factor from ROM1 going to butterfly unit1
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy1_tw_reg_load,
      data_in    => f_data_in_9,
      data_out   => s_bfy1_WRI);

  
  MUX7: mux_2_to_1                                          --Mux to split 32-bit twiddle factor register to 16-bit real and imaginary parts in consecutive clock cycles
    generic map (
      DATA_WIDTH => 16)
    port map (
      input0     => s_bfy1_WRI(15 downto 0),
      input1     => s_bfy1_WRI(31 downto 16),
      sel        => s_bfy1_tw_sel,
      output     => s_WRI_1);

  
  U7: R2_V6                                                 --Butterfly unit1
    port map (
      PQI                => s_bfy1_PQI_R(15 downto 0),
      PQ_R               => s_bfy1_PQI_R(DATA_WIDTH-1 downto 16),
      WRI                => s_WRI_1,
      add_sub            => s_add_sub,
      clk                => clk,
      load               => s_load,
      load1              => s_load1,
      load_P             => s_load_P,
      load_P2            => s_load_P2,
      load_Q             => s_load_Q,
      load_W             => s_load_W,
      rst                => rst,
      sel                => s_sel,
      imagout            => s_bfy1_imagout,
      realout            => s_bfy1_realout);
  
      s_bfy1_real_imag_y <= s_bfy1_realout & s_bfy1_imagout; --Combine real and imaginary parts into one unit

  
  REG8: reg_n_bit                                            --Register to hold the addition output result from butterfly unit1
    generic map (
      DATA_WIDTH         => DATA_WIDTH)
    port map (
      clk                => clk,
      rst                => rst,
      load               => s_bfy1_add_op_reg_load,
      data_in            => s_bfy1_real_imag_y,
      data_out           => s_bfy1_out_first);
      
      s_bfy1_real_imag_x <= s_bfy1_realout & s_bfy1_imagout; --Combine real and imaginary parts into one unit  

  
  REG9: reg_n_bit                                            --Register to hold the subtraction output result from butterfly unit1
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy1_sub_op_reg_load,
      data_in    => s_bfy1_real_imag_x,
      data_out   => s_bfy1_out_second);

  
  U8: addr_gen_unit                                          --Address generation unit TODO: done? should it be connected to output toplevel done or removed as redundant?
    generic map (
      ADDR_WIDTH    => ADDR_WIDTH,
      N_width       => N_WIDTH)
    port map (
      clk           => clk,
      rst           => rst,
      N             => N,
      a_start       => f_start,
      a_begin_stage => s_begin_stage,
      a_read_data   => s_read_data,
      a_read_data1  => s_read_data1,
      a_store_add   => s_store_add,
      a_store_sub   => s_store_sub,
      a_Coef0Addr   => s_Coef0Addr,
      a_Coef1Addr   => s_Coef1Addr,
      a_done        => s_done);

  
  INTER_CONNECT_A: interconnect                              --InterconnectA instantiation
    generic map (
      ADDR_WIDTH         => ADDR_WIDTH,
      N_width            => N_WIDTH,
      DATA_WIDTH         => DATA_WIDTH)
    port map (
      clk                => clk,
      rst                => rst,
      i_RW               => s_SetA_RW,
      i_last_stage       => s_c_last_stage,
      i_input_flip       => s_input_flip,
      i_read_data        => s_read_data,
      i_read_data1       => s_read_data1,      
      i_store_add        => s_store_add,
      i_store_sub        => s_store_sub,
      
      i_bfy0_in_first    => s_bfy0_out_first,
      i_bfy0_in_second   => s_bfy0_out_second,
      i_bfy1_in_first    => s_bfy1_out_first,
      i_bfy1_in_second   => s_bfy1_out_second,
      
      i_bfy0_out_first   => s_bfy0_in_first_A,
      i_bfy0_out_second  => s_bfy0_in_second_A,
      i_bfy1_out_first   => s_bfy1_in_first_A,
      i_bfy1_out_second  => s_bfy1_in_second_A,
      
      i_data_in_RAM0     => s_data_in_RAM0_A,
      i_data_in_RAM1     => s_data_in_RAM1_A,
      i_data_in_RAM2     => s_data_in_RAM2_A,
      i_data_in_RAM3     => s_data_in_RAM3_A,
      
      i_data_out_RAM0    => s_data_out_RAM0_A,
      i_data_out_RAM1    => s_data_out_RAM1_A,
      i_data_out_RAM2    => s_data_out_RAM2_A,
      i_data_out_RAM3    => s_data_out_RAM3_A,
      
      i_addr_RAM0        => f_addr_0,
      i_addr_RAM1        => f_addr_1,
      i_addr_RAM2        => f_addr_2,
      i_addr_RAM3        => f_addr_3);

  
  INTER_CONNECT_B: interconnect                          --InterconnectB instantiation
    generic map (
      ADDR_WIDTH         => ADDR_WIDTH,
      N_width            => N_WIDTH,
      DATA_WIDTH         => DATA_WIDTH)
    port map (
      clk                => clk,
      rst                => rst,
      i_RW               => s_SetB_RW,
      i_last_stage       => s_c_last_stage,
      i_input_flip       => s_input_flip,      
      i_read_data        => s_read_data,
      i_read_data1       => s_read_data1,      
      i_store_add        => s_store_add,
      i_store_sub        => s_store_sub,
      
      i_bfy0_in_first    => s_bfy0_out_first,
      i_bfy0_in_second   => s_bfy0_out_second,
      i_bfy1_in_first    => s_bfy1_out_first,
      i_bfy1_in_second   => s_bfy1_out_second,
      
      i_bfy0_out_first   => s_bfy0_in_first_B,
      i_bfy0_out_second  => s_bfy0_in_second_B,
      i_bfy1_out_first   => s_bfy1_in_first_B,
      i_bfy1_out_second  => s_bfy1_in_second_B,
      
      i_data_in_RAM0     => s_data_in_RAM0_B,
      i_data_in_RAM1     => s_data_in_RAM1_B,
      i_data_in_RAM2     => s_data_in_RAM2_B,
      i_data_in_RAM3     => s_data_in_RAM3_B,
      
      i_data_out_RAM0    => s_data_out_RAM0_B,
      i_data_out_RAM1    => s_data_out_RAM1_B,
      i_data_out_RAM2    => s_data_out_RAM2_B,
      i_data_out_RAM3    => s_data_out_RAM3_B,
      
      i_addr_RAM0        => f_addr_4,
      i_addr_RAM1        => f_addr_5,
      i_addr_RAM2        => f_addr_6,
      i_addr_RAM3        => f_addr_7
      );

  REG_ROM0: reg_n_bit                                            --Register to hold the twiddle factor address for butterfly0
    generic map (
      DATA_WIDTH => ADDR_WIDTH+2)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy0_tw_addr_reg_load,
      data_in    => s_Coef0Addr,
      data_out   => f_addr_8);


  REG_ROM1: reg_n_bit                                            --Register to hold the twiddle factor address for butterfly1
    generic map (
      DATA_WIDTH => ADDR_WIDTH+2)
    port map (
      clk        => clk,
      rst        => rst,
      load       => s_bfy1_tw_addr_reg_load,
      data_in    => s_Coef1Addr,
      data_out   => f_addr_9);  
	  
	  
end rtl;
