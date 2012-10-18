-------------------------------------------------------------------------------
-- Title      : Address generation unit test bench
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : addr_gen_unit_tb.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/10/17
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Instantiates the address generation unit module for different
--              FFT points(N) and applies the stimulus to those modules.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/07/22  1.0      revanna	Created
-------------------------------------------------------------------------------

--Include the libraries and packages
library ieee;
use ieee.std_logic_1164.all;

entity addr_gen_unit_tb is
  
end addr_gen_unit_tb;

architecture addr_gen_unit_tb_arch of addr_gen_unit_tb is

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
      store0   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      store1    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      Coef0Addr : out std_logic_vector(N_width-2 downto 0);
      Coef1Addr : out std_logic_vector(N_width-2 downto 0);
      done      : out std_logic);
  end component;
  
  signal tb_clk : std_logic := '0';     -- test bench clock generation
  signal tb_rst : std_logic := '0';     -- test bench reset signal generation
  constant half_clk_period : time := 5 ns;  -- half of clock period
  signal tb_start : std_logic := '0';

  -- fo 8 point FFT
  signal tb_N_0 : std_logic_vector(3 downto 0) := (others => '0');  
  signal tb_count0_0 : std_logic_vector(0 downto 0) := (others => '0');
  signal tb_count1_0 : std_logic_vector(0 downto 0) := (others => '0');
  signal tb_store0_0 : std_logic_vector(0 downto 0) := (others => '0');
  signal tb_store1_0 : std_logic_vector(0 downto 0) := (others => '0');
  signal tb_Coef0Addr_0 : std_logic_vector(2 downto 0) := (others => '0');
  signal tb_Coef1Addr_0 : std_logic_vector(2 downto 0) := (others => '0');
  signal tb_done_0 : std_logic := '0';

  --for 16 point FFT
  signal tb_N_1 : std_logic_vector(4 downto 0) := (others => '0');  
  signal tb_count0_1 : std_logic_vector(1 downto 0) := (others => '0');
  signal tb_count1_1 : std_logic_vector(1 downto 0) := (others => '0');
  signal tb_store0_1 : std_logic_vector(1 downto 0) := (others => '0');
  signal tb_store1_1 : std_logic_vector(1 downto 0) := (others => '0');
  signal tb_Coef0Addr_1 : std_logic_vector(3 downto 0) := (others => '0');
  signal tb_Coef1Addr_1 : std_logic_vector(3 downto 0) := (others => '0');
  signal tb_done_1 : std_logic := '0';
  
  -- fo 32 point FFT
  signal tb_N_2 : std_logic_vector(5 downto 0) := (others => '0');  
  signal tb_count0_2 : std_logic_vector(2 downto 0) := (others => '0');
  signal tb_count1_2 : std_logic_vector(2 downto 0) := (others => '0');
  signal tb_store0_2 : std_logic_vector(2 downto 0) := (others => '0');
  signal tb_store1_2 : std_logic_vector(2 downto 0) := (others => '0');
  signal tb_Coef0Addr_2 : std_logic_vector(4 downto 0) := (others => '0');
  signal tb_Coef1Addr_2 : std_logic_vector(4 downto 0) := (others => '0');
  signal tb_done_2 : std_logic := '0';  

  --signals for 64 point FFT
  signal tb_N_3 : std_logic_vector(6 downto 0) := (others => '0');
  signal tb_count0_3 : std_logic_vector(3 downto 0) := (others => '0');
  signal tb_count1_3 : std_logic_vector(3 downto 0) := (others => '0');
  signal tb_store0_3 : std_logic_vector(3 downto 0) := (others => '0');
  signal tb_store1_3 : std_logic_vector(3 downto 0) := (others => '0');
  signal tb_Coef0Addr_3 : std_logic_vector(5 downto 0) := (others => '0');
  signal tb_Coef1Addr_3 : std_logic_vector(5 downto 0) := (others => '0');
  signal tb_done_3 : std_logic := '0';

begin  -- addr_gen_unit_tb_arch

  U0 : addr_gen_unit generic map (
    ADDR_WIDTH => 1,
    N_width    => 4)
    port map (
    clk       => tb_clk,
    rst       => tb_rst,
    N         => tb_N_0,
    start     => tb_start,
    count0    => tb_count0_0,
    count1    => tb_count1_0,
    store0    => tb_store0_0,
    store1    => tb_store1_0,
    Coef0Addr => tb_Coef0Addr_0,
    Coef1Addr => tb_Coef1Addr_0,
    done      => tb_done_0);
    
  U1 : addr_gen_unit generic map (
    ADDR_WIDTH => 2,
    N_width    => 5)
    port map (
    clk       => tb_clk,
    rst       => tb_rst,
    N         => tb_N_1,
    start     => tb_start,
    count0    => tb_count0_1,
    count1    => tb_count1_1,
    store0    => tb_store0_1,
    store1    => tb_store1_1,
    Coef0Addr => tb_Coef0Addr_1,
    Coef1Addr => tb_Coef1Addr_1,
    done      => tb_done_1);
    
  U2 : addr_gen_unit generic map (
    ADDR_WIDTH => 3,
    N_width    => 6)
    port map (
    clk       => tb_clk,
    rst       => tb_rst,
    N         => tb_N_2,
    start     => tb_start,
    count0    => tb_count0_2,
    count1    => tb_count1_2,
    store0    => tb_store0_2,
    store1    => tb_store1_2,
    Coef0Addr => tb_Coef0Addr_2,
    Coef1Addr => tb_Coef1Addr_2,
    done      => tb_done_2);
  
  U3 : addr_gen_unit generic map (
    ADDR_WIDTH => 4,
    N_width    => 7)
    port map (
    clk       => tb_clk,
    rst       => tb_rst,
    N         => tb_N_3,
    start     => tb_start,
    count0    => tb_count0_3,
    count1    => tb_count1_3,
    store0    => tb_store0_3,
    store1    => tb_store1_3,
    Coef0Addr => tb_Coef0Addr_3,
    Coef1Addr => tb_Coef1Addr_3,
    done      => tb_done_3);
 
  CLK_PROCESS: process
    begin

      tb_clk <= not tb_clk;
      wait for half_clk_period;

    end process CLK_PROCESS;

    tb_rst <= '0' after 30 ns, '1' after 50 ns;

    tb_start <= '1' after 60 ns, '0' after 80 ns;

    FFT_PROCESS: process(tb_clk, tb_rst)
      begin

        tb_N_0 <= "1000";        
        tb_N_1 <= "10000";
        tb_N_2 <= "100000";
        tb_N_3 <= "1000000";

      end process FFT_PROCESS;

end addr_gen_unit_tb_arch;
