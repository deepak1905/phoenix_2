-------------------------------------------------------------------------------
-- Title      : 2 to 1 mux test bench
-- Project    : N-point FFT processor
-------------------------------------------------------------------------------
-- File       : tb_2_to_1_mux.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/09/12
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Test bench to test the functionality of 2 to 1 mux
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/09/12  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity mux_2_to_1_tb is
  
end mux_2_to_1_tb;

architecture rtl of mux_2_to_1_tb is

  --Component declaration
  component mux_2_to_1
    generic (
      DATA_WIDTH : integer);
    
    port (
      input0 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      input1 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      sel    : in  std_logic;
      output : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;

  --Signal declarations
  signal tb_input0, tb_input1: std_logic_vector(31 downto 0) := (others => '0');
  signal tb_output : std_logic_vector(31 downto 0);
  signal tb_sel : std_logic := '0';
  
begin  -- rtl

  --Instantiation
  U1: mux_2_to_1
    generic map (
      DATA_WIDTH => 32)

    port map (
      input0 => tb_input0,
      input1 => tb_input1,
      sel    => tb_sel,
      output => tb_output);

  TEST_PROCESS: process
    begin

      tb_input0 <= conv_std_logic_vector(2,32);
      tb_input1 <= conv_std_logic_vector(3,32);

      wait for 10 ns;

      tb_sel <= '1';

      wait for 10 ns;

      tb_sel <= '0';
      
    end process TEST_PROCESS;

end rtl;
