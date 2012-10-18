-------------------------------------------------------------------------------
-- Title      : Register test bench
-- Project    : 
-------------------------------------------------------------------------------
-- File       : reg_n_bit_tb.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/10/17
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Test bench for the register
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/09/13  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity reg_n_bit_tb is
  
end reg_n_bit_tb;

architecture rtl of reg_n_bit_tb is

  --Component declaration
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
  signal s_clk, s_rst, s_load : std_logic := '0';
  signal s_data_in, s_data_out : std_logic_vector(31 downto 0);
  signal iterate : integer range 0 to 3 := 0;

begin  -- rtl

  --Component instantiation
  U1: reg_n_bit
    generic map (
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rst      => s_rst,
      load     => s_load,
      data_in  => s_data_in,
      data_out => s_data_out);

  s_clk <= not s_clk after 10 ns;
  s_rst <= '0' after 30 ns, '1' after 50 ns;

  TEST_PROCESS: process
    begin

      case iterate is
        when 0 =>
          s_data_in <= conv_std_logic_vector(3, 32);
          s_load <= '1';
          iterate <= 1;
        when 1 =>
          s_data_in <= conv_std_logic_vector(2, 32);
          s_load <= '0';
          iterate <= 2;
        when 2 =>
          s_data_in <= conv_std_logic_vector(4, 32);
          s_load <= '1';
          iterate <= 3;
        when others =>
          s_data_in <= conv_std_logic_vector(5, 32);
          s_load <= '0';
          iterate <= 0;
      end case;

      wait for 10 ns;
      
    end process TEST_PROCESS;

end rtl;
