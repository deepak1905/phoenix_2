-------------------------------------------------------------------------------
-- Title      : Control unit test bench
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : control_unit_tb.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/08/03
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
      clk     : in std_logic;
      rst     : in std_logic;
      start   : in std_logic;
      N       : in std_logic_vector (N_width-1 downto 0);
      SetA_RW : out std_logic;
      SetB_RW : out std_logic;
      done    : out std_logic);
  end component;

  signal tb_clk: std_logic := '0';
  signal tb_rst: std_logic := '0';
  signal tb_N : std_logic_vector(3 downto 0) := (others=>'0');
  signal tb_SetA_RW : std_logic := '0';
  signal tb_SetB_RW : std_logic := '0';
  signal tb_done : std_logic := '0';
  constant half_clk_period : time := 5 ns;
  signal tb_start : std_logic := '0';
  signal tb_N_1 : std_logic_vector(4 downto 0) := (others => '0');
  signal tb_N_2 : std_logic_vector(5 downto 0) := (others=>'0');
  signal tb_N_3 : std_logic_vector(6 downto 0) := (others=>'0');
  signal tb_SetA_RW_1, tb_SetA_RW_2, tb_SetA_RW_3 : std_logic := '0';
  signal tb_SetB_RW_1, tb_SetB_RW_2, tb_SetB_RW_3 : std_logic := '0';
  signal tb_done_1, tb_done_2, tb_done_3 : std_logic := '0';
  
begin  -- control_unit_tb_arch
--Architecture body - Concurrent statements

  --Instantiate the control unit under test
  U0 : control_unit generic map (
    N_width => 4)
    port map (
    clk     => tb_clk,
    rst     => tb_rst,
    start   => tb_start,
    N       => tb_N,
    SetA_RW => tb_SetA_RW,
    SetB_RW => tb_SetB_RW,
    done    => tb_done
    );

  U1 : control_unit generic map (
    N_width => 5)
    port map (
    clk     => tb_clk,
    rst     => tb_rst,
    start   => tb_start,
    N       => tb_N_1,
    SetA_RW => tb_SetA_RW_1,
    SetB_RW => tb_SetB_RW_1,
    done    => tb_done_1
    );
  
  U2 : control_unit generic map (
    N_width => 6)
    port map (
    clk     => tb_clk,
    rst     => tb_rst,
    start   => tb_start,
    N       => tb_N_2,
    SetA_RW => tb_SetA_RW_2,
    SetB_RW => tb_SetB_RW_2,
    done    => tb_done_2
    );
  
  U3 : control_unit generic map (
    N_width => 7)
    port map (
    clk     => tb_clk,
    rst     => tb_rst,
    start   => tb_start,
    N       => tb_N_3,
    SetA_RW => tb_SetA_RW_3,
    SetB_RW => tb_SetB_RW_3,
    done    => tb_done_3
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
      tb_N <= "1000";
      tb_N_1 <= "10000";
      tb_N_2 <= "100000";
      tb_N_3 <= "1000000";

  end process STIMULI_PROCESS;

end control_unit_tb_arch;
