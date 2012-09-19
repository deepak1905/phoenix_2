-------------------------------------------------------------------------------
-- Title      : FFT processor test bench
-- Project    : N-point FFT processor
-------------------------------------------------------------------------------
-- File       : fft_core_top_level_tb.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/09/19
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: The test bench tests the FFT processor providing appropriate
--              test inputs
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/09/18  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fft_core_top_level_tb is
  
end fft_core_top_level_tb;

architecture rtl of fft_core_top_level_tb is

  --Component declaration
  component fft_core_top_level
    generic (
      N_WIDTH    : integer;
      ADDR_WIDTH : integer;
      DATA_WIDTH : integer);

    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      N     : in  std_logic_vector(N_WIDTH-1 downto 0);
      start : in  std_logic;
      done  : out std_logic);
  end component;

  --signal declarations
  signal tb_clk, tb_rst, tb_start : std_logic := '0';
  signal tb_done : std_logic;
  signal tb_N : std_logic_vector(6 downto 0) := (others => '0');
  
begin  -- rtl

  --Component instantiation

  --8 point FFT processor
  U0: fft_core_top_level
    generic map (
      N_WIDTH    => 7,
      ADDR_WIDTH => 4,
      DATA_WIDTH => 32)

    port map (
      clk   => tb_clk,
      rst   => tb_rst,
      N     => tb_N,
      start => tb_start,
      done  => tb_done);

  tb_clk <= not tb_clk after 10 ns;
  tb_rst <= '1' after 20 ns, '0' after 40 ns;

--  CLK_PROCESS: process
--    begin
--    end process CLK_PROCESS;

end rtl;
