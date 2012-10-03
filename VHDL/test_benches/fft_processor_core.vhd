-------------------------------------------------------------------------------
-- Title      : FFT processor core
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : fft_processor_core.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/10/02
-- Platform   : 
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


entity fft_core is
  
  generic (
    N_WIDTH : integer := 7;
    ADDR_WIDTH : integer := 4;                               -- by default support 64 point FFT
    DATA_WIDTH : integer := 32);                             -- upper 16 bits for real part and
                                                             -- lower 16 bits for imaginary part
  port (
    clk   : in  std_logic;                                   -- input clock signal
    rst   : in  std_logic;                                   -- asynchronous reset signal
    start : in  std_logic;                                   -- signal to initiate FFT computation
    N     : in std_logic_vector(N_WIDTH-1 downto 0);         -- number of FFT points
    done  : out std_logic;                                   -- signal indicating the completion of FFT computation

    --memory bank RAM0 data/address and control signal
    din0  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- input data
    dout0 : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- output data
    rw0   : out  std_logic       ;                           -- read-write control signal
    addr0 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     -- address bus

    --memory bank RAM1 data/address and control signal
    din1  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- input data
    dout1 : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- output data
    rw1   : out  std_logic;                                  -- read-write control signal
    addr1 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     -- address bus

    --memory bank RAM2 data/address and control signal
    din2  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- input data
    dout2 : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- output data
    rw2   : out  std_logic;                                  -- read-write control
    addr2 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     -- address bus

    --memory bank RAM3 data/address and control signal
    din3  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- input data
    dout3 : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- output data
    rw3   : out  std_logic;                                  -- read-write control signal
    addr3 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     -- address bus        

    --memory bank RAM4 data/address and control signal
    din4  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- input data
    dout4 : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- output data
    rw4   : out  std_logic;                                  -- read-write control signal
    addr4 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     -- address bus    

    --memory bank RAM5 data/address and control signal
    din5  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- input data
    dout5 : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- output data
    rw5   : out  std_logic;                                  -- read-write control signal
    addr5 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     -- address bus    

    --memory bank RAM6 data/address and control signal
    din6  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- input data
    dout6 : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- output data
    rw6   : out  std_logic;                                  -- read-write control signal
    addr6 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     -- address bus    

    --memory bank RAM7 data/address and control signal
    din7  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- input data
    dout7 : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- output data
    rw7   : out  std_logic;                                  -- read-write control signal
    addr7 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     -- address bus

    --memory bank ROM0 data/address signals
    din8 : in std_logic_vector(DATA_WIDTH-1 downto 0);       -- input data
    addr8 : out std_logic_vector(ADDR_WIDTH downto 0);       -- output address

    --memory bank ROM1 data/address signals
    din9 : in std_logic_vector(DATA_WIDTH-1 downto 0);       -- input data
    addr9 : out std_logic_vector(ADDR_WIDTH downto 0));      -- output address
    
end fft_core;

architecture rtl of fft_core is
  --Component declarations

  --Address generation unit
  component addr_gen_unit
    generic (
      ADDR_WIDTH : integer;
      N_width    : integer);

    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      N         : in  std_logic_vector(N_width-1 downto 0);
      start     : in  std_logic;
      count0    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      count1    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      store0    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      store1    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      Coef0Addr : out std_logic_vector(ADDR_WIDTH+1 downto 0);
      Coef1Addr : out std_logic_vector(ADDR_WIDTH+1 downto 0);
      done      : out std_logic);
  end component;

  --Control unit
  component control_unit
    generic (
      N_width : integer);

  port (
    clk               : in  std_logic;
    rst               : in  std_logic;
    start             : in  std_logic;    
    N                 : in  std_logic_vector(N_width-1 downto 0);
    c_add_sub         : out std_logic;
    c_load            : out std_logic;
    c_load1           : out std_logic;
    c_load_P          : out std_logic;
    c_load_P2         : out std_logic;
    c_load_Q          : out std_logic;
    c_load_W          : out std_logic;
    c_sel             : out std_logic;
    SetA_RW           : out std_logic;
    SetB_RW           : out std_logic;
    bfy0_ip0_reg_load : out std_logic;
    bfy0_ip1_reg_load : out std_logic;
    bfy0_mux_sel      : out std_logic;
    bfy0_tw_reg_load  : out std_logic;
    bfy0_tw_sel       : out std_logic;

    bfy1_ip0_reg_load : out std_logic;
    bfy1_ip1_reg_load : out std_logic;
    bfy1_mux_sel      : out std_logic;
    bfy1_tw_reg_load  : out std_logic;
    bfy1_tw_sel       : out std_logic;
    
    done              : out std_logic);
  end component;

  --Interconnect unit
  component interconnect
    generic (
      ADDR_WIDTH : integer;
      N_width    : integer;
      DATA_WIDTH : integer);
    port (
      clk              : in  std_logic;
      rst              : in  std_logic;
      RW               : in  std_logic;
      count0_i         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      count1_i         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      store0_i         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      store1_i         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      bfy0_add         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      bfy0_sub         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      bfy1_add         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      bfy1_sub         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      operand0_out_bfy : out std_logic_vector(DATA_WIDTH-1 downto 0);
      operand1_out_bfy : out std_logic_vector(DATA_WIDTH-1 downto 0);
      operand2_out_bfy : out std_logic_vector(DATA_WIDTH-1 downto 0);
      operand3_out_bfy : out std_logic_vector(DATA_WIDTH-1 downto 0);
      operand0_addr    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      operand1_addr    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      operand2_addr    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      operand3_addr    : out std_logic_vector(ADDR_WIDTH-1 downto 0));
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
      clk      : in  std_logic;
      rst      : in  std_logic;
      load     : in  std_logic;
      data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;
  
  --signal declarations

  --Control unit signals
  signal s_bfy0_PQI_R, s_bfy1_PQI_R, s_bfy0_WRI, s_bfy1_WRI : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_WRI_0, s_WRI_1, s_bfy0_imagout, s_bfy0_realout, s_bfy1_imagout, s_bfy1_realout : std_logic_vector(15 downto 0) := (others => '0');
  signal s_bfy0_real_imag_x, s_bfy0_real_imag_y : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_bfy1_real_imag_x, s_bfy1_real_imag_y : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_add_sub, s_load, s_load1, s_load_P, s_load_P2, s_load_Q, s_load_W, s_sel : std_logic := '0';
  signal s_SetA_RW, s_SetB_RW : std_logic := '0';
  signal s_bfy0_ip0_reg_load, s_bfy0_ip1_reg_load, s_bfy0_mux_sel, s_bfy0_tw_reg_load, s_bfy0_tw_sel : std_logic;
  signal s_bfy1_ip0_reg_load, s_bfy1_ip1_reg_load, s_bfy1_mux_sel, s_bfy1_tw_reg_load, s_bfy1_tw_sel : std_logic;
  signal s_bfy0_add_op_reg_load, s_bfy0_sub_op_reg_load: std_logic;
  signal s_bfy1_add_op_reg_load, s_bfy1_sub_op_reg_load: std_logic;
  signal s_bfy0_add, s_bfy0_sub : std_logic_vector(DATA_WIDTH-1 downto 0);  
  signal s_bfy1_add, s_bfy1_sub : std_logic_vector(DATA_WIDTH-1 downto 0);

  --Address generation unit signals
  signal s_count0, s_count1 : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_store0, s_store1 : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_Coef0Addr, s_Coef1Addr : std_logic_vector(ADDR_WIDTH+1 downto 0);
  signal s_done : std_logic;

  --Multiplexers at butterfly inputs
  signal s_mux0_op, s_mux1_op : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_mux4_op, s_mux5_op : std_logic_vector(DATA_WIDTH-1 downto 0);

  --Registers required at the interface between butterfly inputs
  --and the memory output
  signal s_bfy0_ip0, s_bfy0_ip1 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_bfy1_ip0, s_bfy1_ip1 : std_logic_vector(DATA_WIDTH-1 downto 0);

begin  -- rtl

  --Component instantiations

  --Control unit
  U1: control_unit
    generic map (
      N_width => N_WIDTH)
    
    port map (
      clk               => clk,
      rst               => rst,
      start             => start,
      N                 => N,
      c_add_sub         => s_add_sub,
      c_load            => s_load,
      c_load1           => s_load1,
      c_load_P          => s_load_P,
      c_load_P2         => s_load_P2,
      c_load_Q          => s_load_Q,
      c_load_W          => s_load_W,
      c_sel             => s_sel,
      SetA_RW           => s_SetA_RW,
      SetB_RW           => s_SetB_RW,
      bfy0_ip0_reg_load => s_bfy0_ip0_reg_load,
      bfy0_ip1_reg_load => s_bfy0_ip1_reg_load,
      bfy0_mux_sel      => s_bfy0_mux_sel,
      bfy0_tw_reg_load  => s_bfy0_tw_reg_load,
      bfy0_tw_sel       => s_bfy0_tw_sel,
      bfy1_ip0_reg_load => s_bfy1_ip0_reg_load,
      bfy1_ip1_reg_load => s_bfy1_ip1_reg_load,
      bfy1_mux_sel      => s_bfy1_mux_sel,
      bfy1_tw_reg_load  => s_bfy1_tw_reg_load,
      bfy1_tw_sel       => s_bfy1_tw_sel,
      done              => done);

  --Feed the read-write control
  --signal for the memory bank set A
  rw0 <= s_SetA_RW;
  rw1 <= s_SetA_RW;
  rw2 <= s_SetA_RW;
  rw3 <= s_SetA_RW;

  --Feed the read-write control
  --signal for the memory bank set B  
  rw4 <= s_SetB_RW;
  rw5 <= s_SetB_RW;
  rw6 <= s_SetB_RW;
  rw7 <= s_SetB_RW;  

  --Mux to select data read from
  --RAM and going to butterfly unit0
  MUX0: mux_2_to_1
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      input0 => din0,
      input1 => din4,
      sel    => s_SetA_RW,
      output => s_mux0_op );

  --Mux to select data read from
  --RAM and going to butterfly unit0  
  MUX1: mux_2_to_1
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      input0 => din1,
      input1 => din5,
      sel    => s_SetA_RW,
      output => s_mux1_op );

  --Register to store the output
  --of MUX0 above
  REG0: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy0_ip0_reg_load,
      data_in  => s_mux0_op,
      data_out => s_bfy0_ip0 );

  --Register to store the output
  --of MUX1 above  
  REG1: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy0_ip1_reg_load,
      data_in  => s_mux1_op,
      data_out => s_bfy0_ip1 );

  --Mux to select the one input in
  --each clock out of the two inputs
  --required by the butterfly unit0
  MUX2: mux_2_to_1
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      input0 => s_bfy0_ip0,
      input1 => s_bfy0_ip1,
      sel    => s_bfy0_mux_sel,
      output => s_bfy0_PQI_R);

  --Register to store the twiddle factor
  --from ROM0 going to butterfly unit0
  REG2: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy0_tw_reg_load,
      data_in  => din8,
      data_out =>  s_bfy0_WRI);

  --Mux to split 32-bit twiddle factor
  --register to 16-bit real and imaginary
  --parts in consecutive clock cycles
  MUX3: mux_2_to_1
    generic map (
      DATA_WIDTH => 16)

    port map (
      input0 => s_bfy0_WRI(31 downto 16),
      input1 => s_bfy0_WRI(15 downto 0),
      sel    => s_bfy0_tw_sel,
      output => s_WRI_0);
  
  --Butterfly unit0
  U6: R2_V6
    port map (
      PQI     => s_bfy0_PQI_R(15 downto 0),
      PQ_R    => s_bfy0_PQI_R(DATA_WIDTH-1 downto 16),
      WRI     => s_WRI_0,
      add_sub => s_add_sub,
      clk     => clk,
      load    => s_load,
      load1   => s_load1,
      load_P  => s_load_P,
      load_P2 => s_load_P2,
      load_Q  => s_load_Q,
      load_W  => s_load_W,
      rst     => rst,
      sel     => s_sel,
      imagout => s_bfy0_imagout,
      realout => s_bfy0_realout);

  --Combine real and imaginary parts into one unit  
  s_bfy0_real_imag_y <= s_bfy0_realout & s_bfy0_imagout;
  
  --Register to hold the addition output
  --result from butterfly unit0
  REG3: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy0_add_op_reg_load,
      data_in  => s_bfy0_real_imag_y,
      data_out => s_bfy0_add);

  --Combine real and imaginary parts into one unit
  s_bfy0_real_imag_x <= s_bfy0_realout & s_bfy0_imagout;
  
  --Register to hold the subtraction output
  --result from butterfly unit0
  REG4: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy0_sub_op_reg_load,
      data_in  => s_bfy0_real_imag_x,
      data_out => s_bfy0_sub);
  

  --Mux to select data read from
  --RAM and going to butterfly unit1  
  MUX4: mux_2_to_1
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      input0 => din2,
      input1 => din6,
      sel    => s_SetA_RW,
      output => s_mux4_op );

  --Mux to select data read from
  --RAM and going to butterfly unit1    
  MUX5: mux_2_to_1
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      input0 => din3,
      input1 => din7,
      sel    => s_SetA_RW,
      output => s_mux5_op );

  --Register to store the output
  --of MUX4 above
  REG5: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy1_ip0_reg_load,
      data_in  => s_mux4_op,
      data_out => s_bfy1_ip0);

  --Register to store the output
  --of MUX5 above
  REG6: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy1_ip1_reg_load,
      data_in  => s_mux5_op,
      data_out => s_bfy1_ip1 );

  --Mux to select the one input in
  --each clock out of the two inputs
  --required by the butterfly unit1  
  MUX6: mux_2_to_1
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      input0 => s_bfy1_ip0,
      input1 => s_bfy1_ip1,
      sel    => s_bfy1_mux_sel,
      output => s_bfy1_PQI_R );

  --Register to store the twiddle factor
  --from ROM1 going to butterfly unit1
  REG7: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy1_tw_reg_load,
      data_in  => din9,
      data_out => s_bfy1_WRI);

  --Mux to split 32-bit twiddle factor
  --register to 16-bit real and imaginary
  --parts in consecutive clock cycles  
  MUX7: mux_2_to_1
    generic map (
      DATA_WIDTH => 16)

    port map (
      input0 => s_bfy1_WRI(31 downto 16),
      input1 => s_bfy1_WRI(15 downto 0),
      sel    => s_bfy1_tw_sel,
      output => s_WRI_1);
  
  --Butterfly unit1
  U7: R2_V6
    port map (
      PQI     => s_bfy1_PQI_R(15 downto 0),
      PQ_R    => s_bfy1_PQI_R(DATA_WIDTH-1 downto 16),
      WRI     => s_WRI_1,
      add_sub => s_add_sub,
      clk     => clk,
      load    => s_load,
      load1   => s_load1,
      load_P  => s_load_P,
      load_P2 => s_load_P2,
      load_Q  => s_load_Q,
      load_W  => s_load_W,
      rst     => rst,
      sel     => s_sel,
      imagout => s_bfy1_imagout,
      realout => s_bfy1_realout);

  --Combine real and imaginary parts into one unit
  s_bfy1_real_imag_y <= s_bfy1_realout & s_bfy1_imagout;
    
  --Register to hold the addition output
  --result from butterfly unit1
  REG8: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy1_add_op_reg_load,
      data_in  => s_bfy1_real_imag_y,
      data_out => s_bfy1_add);

  --Combine real and imaginary parts into one unit  
  s_bfy1_real_imag_x <= s_bfy1_realout & s_bfy1_imagout;
    
  --Register to hold the subtraction output
  --result from butterfly unit1
  REG9: reg_n_bit
    generic map (
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk      => clk,
      rst      => rst,
      load     => s_bfy1_sub_op_reg_load,
      data_in  => s_bfy1_real_imag_x,
      data_out => s_bfy1_sub);

  --Address generation unit
  --TODO: done? should it be connected
  --to output toplevel done or removed
  --as redundant?
  U8: addr_gen_unit
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      N_width    => N_WIDTH)

    port map (
      clk       => clk,
      rst       => rst,
      N         => N,
      start     => start,
      count0    => s_count0,
      count1    => s_count1,
      store0    => s_store0,
      store1    => s_store1,
      Coef0Addr => s_Coef0Addr,
      Coef1Addr => s_Coef1Addr,
      done      => s_done);

  --InterconnectA instantiation
  INTER_CONNECT_A: interconnect
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      N_width    => N_WIDTH,
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk              => clk,
      rst              => rst,
      RW               => s_SetA_RW,
      count0_i         => s_count0,
      count1_i         => s_count1,
      store0_i         => s_store0,
      store1_i         => s_store1,
      bfy0_add         => s_bfy0_add,
      bfy0_sub         => s_bfy0_sub,
      bfy1_add         => s_bfy1_add,
      bfy1_sub         => s_bfy1_sub,
      operand0_out_bfy => dout0,
      operand1_out_bfy => dout1,
      operand2_out_bfy => dout2,
      operand3_out_bfy => dout3,
      operand0_addr    => addr0,      
      operand1_addr    => addr1,
      operand2_addr    => addr2,
      operand3_addr    => addr3);

  --InterconnectB instantiation
  INTER_CONNECT_B: interconnect
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      N_width    => N_WIDTH,
      DATA_WIDTH => DATA_WIDTH)

    port map (
      clk              => clk,
      rst              => rst,
      RW               => s_SetB_RW,
      count0_i         => s_count0,
      count1_i         => s_count1,
      store0_i         => s_store0,
      store1_i         => s_store1,
      bfy0_add         => s_bfy0_add,
      bfy0_sub         => s_bfy0_sub,
      bfy1_add         => s_bfy1_add,
      bfy1_sub         => s_bfy1_sub,
      operand0_out_bfy => dout4,
      operand1_out_bfy => dout5,
      operand2_out_bfy => dout6,
      operand3_out_bfy => dout7,
      operand0_addr    => addr4,
      operand1_addr    => addr5,
      operand2_addr    => addr6,
      operand3_addr    => addr7);

end rtl;
