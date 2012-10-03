-------------------------------------------------------------------------------
-- Title      : N-point FFT processor top level view
-- Project    : N-point FFT processor
-------------------------------------------------------------------------------
-- File       : fft_core_top_level.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/10/03
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: The interface of N-point FFT processor core with the memory
--              units. The memory consists two RAM memory sets SETA and SETB.
--              And each set consists of 4 RAM memory banks which allows
--              sample value read-write required during the computation.
--              There are two ROM units ROM0 and ROM1 which store twiddle
--              factors corresponding to butterfly unit0 and butterfly unit1
--              respectively present in the FFT core.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/09/18  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity fft_core_top_level is
  
end fft_core_top_level;

architecture rtl of fft_core_top_level is

  --Component declarations

  --FFT core
  component fft_core
    generic (
      N_WIDTH    : integer;
      ADDR_WIDTH : integer;
      DATA_WIDTH : integer);
    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      start : in  std_logic;
      N     : in  std_logic_vector(N_WIDTH-1 downto 0);
      done  : out std_logic;

      din0  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      dout0 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rw0   : out std_logic;
      addr0 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din1  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      dout1 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rw1   : out std_logic;
      addr1 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din2  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      dout2 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rw2   : out std_logic;
      addr2 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din3  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      dout3 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rw3   : out std_logic;
      addr3 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din4  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      dout4 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rw4   : out std_logic;
      addr4 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din5  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      dout5 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rw5   : out std_logic;
      addr5 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din6  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      dout6 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rw6   : out std_logic;
      addr6 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din7  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      dout7 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      rw7   : out std_logic;
      addr7 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din8  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      addr8 : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      din9  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      addr9 : out std_logic_vector(ADDR_WIDTH-1 downto 0));
  end component;

  --RAM unit
  component single_port_RAM
    generic (
      FILE_NAME  : string;
      ADDR_WIDTH : integer;
      DATA_WIDTH : integer);
    port (
      clk      : in  std_logic;
      rw       : in  std_logic;
      addr_bus : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;

  --ROM unit
  component single_port_ROM
    generic (
      FILE_NAME  : string;
      ADDR_WIDTH : integer;
      DATA_WIDTH : integer);
    port (
      clk      : in  std_logic;
      addr_bus : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;

  -- Signal declarations
  constant DATA_WIDTH : integer := 32;
  constant RAM_ADDR_WIDTH : integer := 1;   --8 point FFT, 2 points per bank hence
                                        --1 bit address
  constant ROM_ADDR_WIDTH : integer := 2;
  
  signal s_din0, s_dout0 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr0 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal s_rw0 : std_logic;

  signal s_din1, s_dout1 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr1 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal s_rw1 : std_logic;

  signal s_din2, s_dout2 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr2 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal s_rw2 : std_logic;

  signal s_din3, s_dout3 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr3 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal s_rw3 : std_logic;

  signal s_din4, s_dout4 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr4 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal s_rw4 : std_logic;
  
  signal s_din5, s_dout5 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr5 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal s_rw5 : std_logic;

  signal s_din6, s_dout6 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr6 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal s_rw6 : std_logic;  

  signal s_din7, s_dout7 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr7 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal s_rw7 : std_logic;

  signal s_din8 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr8 : std_logic_vector(ROM_ADDR_WIDTH-1 downto 0);

  signal s_din9 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr9 : std_logic_vector(ROM_ADDR_WIDTH-1 downto 0);

  --Input signals to the core
  signal s_clk, s_rst, s_start : std_logic := '0';
  signal s_done : std_logic;
  signal s_N_8 : std_logic_vector(3 downto 0) := "1000";  -- 8 point FFT
  signal dataread : integer;
  signal init_done, is_file_open : boolean := false;

begin  -- rtl

  --Component instantiations

  --RAM0
  U0: single_port_RAM
    generic map (
      FILE_NAME  => "ram_0.txt",
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rw       => s_rw0,
      addr_bus => s_addr0,
      data_in  => s_dout0,
      data_out => s_din0);

    --RAM1
  U1: single_port_RAM
    generic map (
      FILE_NAME  => "ram_1.txt",      
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rw       => s_rw1,
      addr_bus => s_addr1,
      data_in  => s_dout1,
      data_out => s_din1);

  --RAM2  
  U2: single_port_RAM
    generic map (
      FILE_NAME  => "ram_2.txt",      
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rw       => s_rw2,
      addr_bus => s_addr2,
      data_in  => s_dout2,
      data_out => s_din2);

  --RAM3  
  U3: single_port_RAM
    generic map (
      FILE_NAME  => "ram_3.txt",      
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rw       => s_rw3,
      addr_bus => s_addr3,
      data_in  => s_dout3,
      data_out => s_din3);
  
  --RAM4
  U4: single_port_RAM
    generic map (
      FILE_NAME  => "ram_4.txt",      
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rw       => s_rw4,
      addr_bus => s_addr4,
      data_in  => s_dout4,
      data_out => s_din4);

  --RAM5  
  U5: single_port_RAM
    generic map (
      FILE_NAME  => "ram_5.txt",      
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rw       => s_rw5,
      addr_bus => s_addr5,
      data_in  => s_dout5,
      data_out => s_din5);

  --RAM6  
  U6: single_port_RAM
    generic map (
      FILE_NAME  => "ram_6.txt",      
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rw       => s_rw6,
      addr_bus => s_addr6,
      data_in  => s_dout6,
      data_out => s_din6);

  --RAM7  
  U7: single_port_RAM
    generic map (
      FILE_NAME  => "ram_7.txt",      
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      rw       => s_rw7,
      addr_bus => s_addr7,
      data_in  => s_dout7,
      data_out => s_din7);  

  --ROM0
  U8: single_port_ROM
    generic map (
      FILE_NAME  => "rom.txt",
      ADDR_WIDTH => ROM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      addr_bus => s_addr8,
      data_out => s_din8);

  --ROM1
  U9: single_port_ROM
    generic map (
      FILE_NAME  => "rom.txt",
      ADDR_WIDTH => ROM_ADDR_WIDTH,
      DATA_WIDTH => 32)

    port map (
      clk      => s_clk,
      addr_bus => s_addr9,
      data_out => s_din9);

  --8 point FFT core instantiation
 U10: fft_core
   generic map (
     N_WIDTH    => 4,
     ADDR_WIDTH => RAM_ADDR_WIDTH,
     DATA_WIDTH => 32)

   port map (
     clk   => s_clk,
     rst   => s_rst,
     start => s_start,
     N     => s_N_8,
     done  => s_done,

     din0  => s_din0,
     dout0 => s_dout0,
     rw0   => s_rw0,
     addr0 => s_addr0,

     din1  => s_din1,
     dout1 => s_dout1,
     rw1   => s_rw1,
     addr1 => s_addr1,

     din2  => s_din2,
     dout2 => s_dout2,
     rw2   => s_rw2,
     addr2 => s_addr2,

     din3  => s_din3,
     dout3 => s_dout3,
     rw3   => s_rw3,
     addr3 => s_addr3,

     din4  => s_din4,
     dout4 => s_dout4,
     rw4   => s_rw4,
     addr4 => s_addr4,

     din5  => s_din5,
     dout5 => s_dout5,
     rw5   => s_rw5,
     addr5 => s_addr5,

     din6  => s_din6,
     dout6 => s_dout6,
     rw6   => s_rw6,
     addr6 => s_addr6,

     din7  => s_din7,
     dout7 => s_dout7,
     rw7   => s_rw7,
     addr7 => s_addr7,

     din8  => s_din8,
     addr8 => s_addr8,

     din9  => s_din9,
     addr9 => s_addr9 );

  --generate clk, rst signals
  s_clk <= not s_clk after 10 ns;
  s_rst <= '1' after 30 ns, '0' after 60 ns;

  --provide go signal to start the FFT computation
  s_start <= '1' after 90 ns, '0' after 130 ns;

end rtl;
