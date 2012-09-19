-------------------------------------------------------------------------------
-- Title      : Control unit test bench
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : control_unit_tb.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/09/18
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Instantiates control unit module for different value of
--              N(number of FFT points) and applies stimulus to all those
--              modules.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/07/19  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity control_unit_tb is
end control_unit_tb;

architecture control_unit_tb_arch of control_unit_tb is
--Component declarations

  --control unit which is under test is declared
  --before instantiating it in the architecture
  --body
  component control_unit
    generic (
      N_width : integer);
    
    port (
      clk               : in std_logic;
      rst               : in std_logic;
      start             : in std_logic;
      N                 : in std_logic_vector (N_width-1 downto 0);
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
      done      : out std_logic);
  end component;

  signal tb_clk: std_logic := '0';
  signal tb_rst: std_logic := '0';
  constant half_clk_period : time := 5 ns;
  signal tb_start : std_logic := '0';  
  
  signal tb_N_1 : std_logic_vector(3 downto 0) := (others=>'0');
  signal tb_SetA_RW_1, tb_SetB_RW_1, tb_done_1 : std_logic := '0';
  signal tb_add_sub_1, tb_load_1, tb_load1_1, tb_load_Q_1 : std_logic := '0';
  signal tb_load_P_1, tb_load_P2_1, tb_load_W_1, tb_sel_1 : std_logic := '0';
  signal tb_bfy0_ip0_reg_load_1, tb_bfy0_ip1_reg_load_1, tb_bfy0_mux_sel_1, tb_bfy0_tw_reg_load_1, tb_bfy0_tw_sel_1 : std_logic;
  signal tb_bfy1_ip0_reg_load_1, tb_bfy1_ip1_reg_load_1, tb_bfy1_mux_sel_1, tb_bfy1_tw_reg_load_1, tb_bfy1_tw_sel_1 : std_logic;

  signal tb_N_2 : std_logic_vector(4 downto 0) := (others => '0');
  signal tb_SetA_RW_2, tb_SetB_RW_2, tb_done_2 : std_logic := '0';
  signal tb_add_sub_2, tb_load_2, tb_load1_2, tb_load_Q_2 : std_logic := '0';
  signal tb_load_P_2, tb_load_P2_2, tb_load_W_2, tb_sel_2 : std_logic := '0';
  signal tb_bfy0_ip0_reg_load_2, tb_bfy0_ip1_reg_load_2, tb_bfy0_mux_sel_2, tb_bfy0_tw_reg_load_2, tb_bfy0_tw_sel_2 : std_logic;
  signal tb_bfy1_ip0_reg_load_2, tb_bfy1_ip1_reg_load_2, tb_bfy1_mux_sel_2, tb_bfy1_tw_reg_load_2, tb_bfy1_tw_sel_2 : std_logic;  
  
  signal tb_N_3 : std_logic_vector(5 downto 0) := (others=>'0');
  signal tb_SetA_RW_3, tb_SetB_RW_3, tb_done_3 : std_logic := '0';
  signal tb_add_sub_3, tb_load_3, tb_load1_3, tb_load_Q_3 : std_logic := '0';
  signal tb_load_P_3, tb_load_P2_3, tb_load_W_3, tb_sel_3 : std_logic := '0';
  signal tb_bfy0_ip0_reg_load_3, tb_bfy0_ip1_reg_load_3, tb_bfy0_mux_sel_3, tb_bfy0_tw_reg_load_3, tb_bfy0_tw_sel_3 : std_logic;
  signal tb_bfy1_ip0_reg_load_3, tb_bfy1_ip1_reg_load_3, tb_bfy1_mux_sel_3, tb_bfy1_tw_reg_load_3, tb_bfy1_tw_sel_3 : std_logic;  
  
  signal tb_N_4 : std_logic_vector(6 downto 0) := (others=>'0');
  signal tb_SetA_RW_4, tb_SetB_RW_4, tb_done_4 : std_logic := '0';
  signal tb_add_sub_4, tb_load_4, tb_load1_4, tb_load_Q_4 : std_logic := '0';
  signal tb_load_P_4, tb_load_P2_4, tb_load_W_4, tb_sel_4 : std_logic := '0';
  signal tb_bfy0_ip0_reg_load_4, tb_bfy0_ip1_reg_load_4, tb_bfy0_mux_sel_4, tb_bfy0_tw_reg_load_4, tb_bfy0_tw_sel_4 : std_logic;
  signal tb_bfy1_ip0_reg_load_4, tb_bfy1_ip1_reg_load_4, tb_bfy1_mux_sel_4, tb_bfy1_tw_reg_load_4, tb_bfy1_tw_sel_4 : std_logic;  
  
begin  -- control_unit_tb_arch
--Architecture body - Concurrent statements

  --Instantiate the control unit under test
  --8 point FFT
  U0 : control_unit generic map (
    N_width => 4)
    
    port map (
    clk               => tb_clk,
    rst               => tb_rst,
    start             => tb_start,
    N                 => tb_N_1,
    c_add_sub         => tb_add_sub_1,
    c_load            => tb_load_1,
    c_load1           => tb_load1_1,
    c_load_P          => tb_load_P_1,
    c_load_P2         => tb_load_P2_1,
    c_load_Q          => tb_load_Q_1,
    c_load_W          => tb_load_W_1,
    c_sel             => tb_sel_1,
    SetA_RW           => tb_SetA_RW_1,
    SetB_RW           => tb_SetB_RW_1,
    bfy0_ip0_reg_load => tb_bfy0_ip0_reg_load_1,
    bfy0_ip1_reg_load => tb_bfy0_ip1_reg_load_1,
    bfy0_mux_sel      => tb_bfy0_mux_sel_1,
    bfy0_tw_reg_load  => tb_bfy0_tw_reg_load_1,
    bfy0_tw_sel       => tb_bfy0_tw_sel_1,
    bfy1_ip0_reg_load => tb_bfy1_ip0_reg_load_1,
    bfy1_ip1_reg_load => tb_bfy1_ip1_reg_load_1,
    bfy1_mux_sel      => tb_bfy1_mux_sel_1,
    bfy1_tw_reg_load  => tb_bfy1_tw_reg_load_1,
    bfy1_tw_sel       => tb_bfy1_tw_sel_1,
    done              => tb_done_1
    );

  --16 point FFT
  U1 : control_unit generic map (
    N_width => 5)

    port map (
    clk               => tb_clk,
    rst               => tb_rst,
    start             => tb_start,
    N                 => tb_N_2,
    c_add_sub         => tb_add_sub_2,
    c_load            => tb_load_2,
    c_load1           => tb_load1_2,
    c_load_P          => tb_load_P_2,
    c_load_P2         => tb_load_P2_2,
    c_load_Q          => tb_load_Q_2,
    c_load_W          => tb_load_W_2,
    c_sel             => tb_sel_2,
    SetA_RW           => tb_SetA_RW_2,
    SetB_RW           => tb_SetB_RW_2,
    bfy0_ip0_reg_load => tb_bfy0_ip0_reg_load_2,
    bfy0_ip1_reg_load => tb_bfy0_ip1_reg_load_2,
    bfy0_mux_sel      => tb_bfy0_mux_sel_2,
    bfy0_tw_reg_load  => tb_bfy0_tw_reg_load_2,
    bfy0_tw_sel       => tb_bfy0_tw_sel_2,
    bfy1_ip0_reg_load => tb_bfy1_ip0_reg_load_2,
    bfy1_ip1_reg_load => tb_bfy1_ip1_reg_load_2,
    bfy1_mux_sel      => tb_bfy1_mux_sel_2,
    bfy1_tw_reg_load  => tb_bfy1_tw_reg_load_2,
    bfy1_tw_sel       => tb_bfy1_tw_sel_2,
    done              => tb_done_2
    );

  --32 point FFT
  U2 : control_unit generic map (
    N_width => 6)
    port map (
    clk               => tb_clk,
    rst               => tb_rst,
    start             => tb_start,
    N                 => tb_N_3,
    c_add_sub         => tb_add_sub_3,
    c_load            => tb_load_3,
    c_load1           => tb_load1_3,
    c_load_P          => tb_load_P_3,
    c_load_P2         => tb_load_P2_3,
    c_load_Q          => tb_load_Q_3,
    c_load_W          => tb_load_W_3,
    c_sel             => tb_sel_3,
    SetA_RW           => tb_SetA_RW_3,
    SetB_RW           => tb_SetB_RW_3,
    bfy0_ip0_reg_load => tb_bfy0_ip0_reg_load_3,
    bfy0_ip1_reg_load => tb_bfy0_ip1_reg_load_3,
    bfy0_mux_sel      => tb_bfy0_mux_sel_3,
    bfy0_tw_reg_load  => tb_bfy0_tw_reg_load_3,
    bfy0_tw_sel       => tb_bfy0_tw_sel_3,
    bfy1_ip0_reg_load => tb_bfy1_ip0_reg_load_3,
    bfy1_ip1_reg_load => tb_bfy1_ip1_reg_load_3,
    bfy1_mux_sel      => tb_bfy1_mux_sel_3,
    bfy1_tw_reg_load  => tb_bfy1_tw_reg_load_3,
    bfy1_tw_sel       => tb_bfy1_tw_sel_3,
    done              => tb_done_3
    );

  --64 point FFT
  U3 : control_unit generic map (
    N_width => 7)
    port map (
    clk               => tb_clk,
    rst               => tb_rst,
    start             => tb_start,
    N                 => tb_N_4,
    c_add_sub         => tb_add_sub_4,
    c_load            => tb_load_4,
    c_load1           => tb_load1_4,
    c_load_P          => tb_load_P_4,
    c_load_P2         => tb_load_P2_4,
    c_load_Q          => tb_load_Q_4,
    c_load_W          => tb_load_W_4,
    c_sel             => tb_sel_4,
    SetA_RW           => tb_SetA_RW_4,
    SetB_RW           => tb_SetB_RW_4,
    bfy0_ip0_reg_load => tb_bfy0_ip0_reg_load_4,
    bfy0_ip1_reg_load => tb_bfy0_ip1_reg_load_4,
    bfy0_mux_sel      => tb_bfy0_mux_sel_4,
    bfy0_tw_reg_load  => tb_bfy0_tw_reg_load_4,
    bfy0_tw_sel       => tb_bfy0_tw_sel_4,
    bfy1_ip0_reg_load => tb_bfy1_ip0_reg_load_4,
    bfy1_ip1_reg_load => tb_bfy1_ip1_reg_load_4,
    bfy1_mux_sel      => tb_bfy1_mux_sel_4,
    bfy1_tw_reg_load  => tb_bfy1_tw_reg_load_4,
    bfy1_tw_sel       => tb_bfy1_tw_sel_4,
    done              => tb_done_4
    );

  --Generate the reset signal
  tb_rst <= '1' after 10 ns, '0' after 20 ns;

  --Generate the clock signal
  CLK_PROCESS: process
    begin

      tb_clk <= not tb_clk;
      wait for half_clk_period;

  end process CLK_PROCESS;

  --Set the start signal
  tb_start <= '1' after 30 ns, '0' after 40 ns;

  --Generate the required test data
  STIMULI_PROCESS: process(tb_clk, tb_rst)
    begin

      --Applying different combination
      --of test inputs
      tb_N_1 <= "1000";
      tb_N_2 <= "10000";
      tb_N_3 <= "100000";
      tb_N_4 <= "1000000";

  end process STIMULI_PROCESS;

end control_unit_tb_arch;
