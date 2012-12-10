-------------------------------------------------------------------------------
-- Title      : N-point FFT processor top level view
-- Project    : N-point FFT processor
-------------------------------------------------------------------------------
-- File       : fft_core_top_level.vhd
-- Author     : Deepak Revanna  <deepak.revanna@tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/12/05
-- Platform   : Altera stratix II FPGA
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

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity fft_core_top_level is
  
end fft_core_top_level;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

architecture rtl of fft_core_top_level is

  --Component declarations

  --FFT core
  component fft_core
    generic (
      N_WIDTH      : integer;
      ADDR_WIDTH   : integer;
      DATA_WIDTH   : integer);
    port (
      clk          : in  std_logic;
      rst          : in  std_logic;
      f_start      : in  std_logic;
      N            : in  std_logic_vector(N_WIDTH-1 downto 0);
      f_done       : out std_logic;

      f_RW_A       : out std_logic;
      f_Enable_A   : out std_logic;
      f_RW_B       : out std_logic;
      f_Enable_B   : out std_logic;

      f_addr_0     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      f_data_in_0  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      f_data_out_0 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      f_addr_1     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      f_data_in_1  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      f_data_out_1 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      f_addr_2     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      f_data_in_2  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      f_data_out_2 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      f_addr_3     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      f_data_in_3  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      f_data_out_3 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      f_addr_4     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      f_data_in_4  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      f_data_out_4 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      f_addr_5     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      f_data_in_5  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      f_data_out_5 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      f_addr_6     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      f_data_in_6  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      f_data_out_6 : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      f_addr_7     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      f_data_in_7  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      f_data_out_7 : out std_logic_vector(DATA_WIDTH-1 downto 0);

      f_addr_8     : out std_logic_vector(ADDR_WIDTH+1 downto 0);
      f_data_in_8  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      
      f_addr_9     : out std_logic_vector(ADDR_WIDTH+1 downto 0);
      f_data_in_9  : in  std_logic_vector(DATA_WIDTH-1 downto 0));
     
      end component;

  --RAM unit
  component single_port_RAM
    generic (
      FILE_NAME    : string;
      ADDR_WIDTH   : integer;
      DATA_WIDTH   : integer);
    port (
      clk          : in  std_logic;
      ram_rw       : in  std_logic;
      ram_enable   : in  std_logic;
      ram_addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      ram_data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      ram_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
      ram_done     : in  std_logic);
  end component;

  --ROM unit
  component single_port_ROM
    generic (
      FILE_NAME                    : string;
      ADDR_WIDTH                   : integer;
      DATA_WIDTH                   : integer);
    port (
      clk                          : in  std_logic;
      rom_addr                     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      rom_data_out                 : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;

  -- Signal declarations
  constant DATA_WIDTH              : integer                                      := 32;           --Always 32 bit(higher 16 bits - real part, lower 16 bits - imag part)
  constant RAM_ADDR_WIDTH          : integer                                      := 7;            --Log(N/4), N= 32 point FFT, 8 inputs per bank
  constant ROM_ADDR_WIDTH          : integer                                      := 9;            --Log(N)
  constant N_WIDTH                 : integer                                      := 10;           --Log(N)+1
  signal s_N_16                    : std_logic_vector(N_WIDTH-1 downto 0)         := "1000000000"; --N

  signal s_RW_A, s_Enable_A        : std_logic;
  signal s_data_in_0, s_data_out_0 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_0                  : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal s_data_in_1, s_data_out_1 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_1                  : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal s_data_in_2, s_data_out_2 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_2                  : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal s_data_in_3, s_data_out_3 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_3                  : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal s_RW_B, s_Enable_B        : std_logic;
  signal s_data_in_4, s_data_out_4 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_4                  : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  
  signal s_data_in_5, s_data_out_5 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_5                  : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal s_data_in_6, s_data_out_6 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_6                  : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal s_data_in_7, s_data_out_7 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_7                  : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal s_data_in_8               : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_8                  : std_logic_vector(ROM_ADDR_WIDTH-1 downto 0);

  signal s_data_in_9               : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_addr_9                  : std_logic_vector(ROM_ADDR_WIDTH-1 downto 0);

  --Input signals to the core
  signal s_clk, s_rst, s_start     : std_logic:= '0';
  signal s_done                    : std_logic;
  signal dataread                  : integer;
  signal init_done, is_file_open   : boolean:= false;

begin  -- rtl

  --Component instantiations

  U0: single_port_RAM                       --RAM0
    generic map (
      FILE_NAME    => "ram_0.txt",
      ADDR_WIDTH   => RAM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      ram_rw       => s_RW_A,
      ram_enable   => s_Enable_A,
      ram_addr     => s_addr_0,
      ram_data_in  => s_data_in_0,
      ram_data_out => s_data_out_0,
      ram_done     => s_done);



  
  U1: single_port_RAM                       --RAM1
    generic map (
      FILE_NAME    => "ram_1.txt",
      ADDR_WIDTH   => RAM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      ram_rw       => s_RW_A,
      ram_enable   => s_Enable_A,
      ram_addr     => s_addr_1,
      ram_data_in  => s_data_in_1,
      ram_data_out => s_data_out_1,
      ram_done     => s_done);
	  
	  
	  

  U2: single_port_RAM                      --RAM2
    generic map (
      FILE_NAME    => "ram_2.txt",
      ADDR_WIDTH   => RAM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      ram_rw       => s_RW_A,
      ram_enable   => s_Enable_A,
      ram_addr     => s_addr_2,
      ram_data_in  => s_data_in_2,
      ram_data_out => s_data_out_2,
      ram_done     => s_done);




  U3: single_port_RAM                      --RAM3
    generic map (
      FILE_NAME    => "ram_3.txt",
      ADDR_WIDTH   => RAM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      ram_rw       => s_RW_A,
      ram_enable   => s_Enable_A,
      ram_addr     => s_addr_3,
      ram_data_in  => s_data_in_3,
      ram_data_out => s_data_out_3,
      ram_done     => s_done);




  U4: single_port_RAM                      --RAM4
    generic map (
      FILE_NAME    => "ram_4.txt",
      ADDR_WIDTH   => RAM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      ram_rw       => s_RW_B,
      ram_enable   => s_Enable_B,
      ram_addr     => s_addr_4,
      ram_data_in  => s_data_in_4,
      ram_data_out => s_data_out_4,
      ram_done     => s_done);




  U5: single_port_RAM                      --RAM5
    generic map (
      FILE_NAME    => "ram_5.txt",
      ADDR_WIDTH   => RAM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      ram_rw       => s_RW_B,
      ram_enable   => s_Enable_B,
      ram_addr     => s_addr_5,
      ram_data_in  => s_data_in_5,
      ram_data_out => s_data_out_5,
      ram_done     => s_done);

  
  
  
  U6: single_port_RAM                      --RAM6
    generic map (
      FILE_NAME    => "ram_6.txt",
      ADDR_WIDTH   => RAM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      ram_rw       => s_RW_B,
      ram_enable   => s_Enable_B,
      ram_addr     => s_addr_6,
      ram_data_in  => s_data_in_6,
      ram_data_out => s_data_out_6,
      ram_done     => s_done);

  
  
  
  U7: single_port_RAM                      --RAM7
    generic map (
      FILE_NAME    => "ram_7.txt",
      ADDR_WIDTH   => RAM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      ram_rw       => s_RW_B,
      ram_enable   => s_Enable_B,
      ram_addr     => s_addr_7,
      ram_data_in  => s_data_in_7,
      ram_data_out => s_data_out_7,
      ram_done     => s_done);

  
  
  
  U8: single_port_ROM                      --ROM0
    generic map (
      FILE_NAME    => "rom.txt",
      ADDR_WIDTH   => ROM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      rom_addr     => s_addr_8,
      rom_data_out => s_data_in_8);

  
  
  
  U9: single_port_ROM                      --ROM1
    generic map (
      FILE_NAME    => "rom.txt",
      ADDR_WIDTH   => ROM_ADDR_WIDTH,
      DATA_WIDTH   => DATA_WIDTH)

    port map (
      clk          => s_clk,
      rom_addr     => s_addr_9,
      rom_data_out => s_data_in_9);



  
 U10: fft_core                             --N point FFT core instantiation
   generic map (
     N_WIDTH      => N_WIDTH,
     ADDR_WIDTH   => RAM_ADDR_WIDTH,
     DATA_WIDTH   => DATA_WIDTH)

   port map (
     clk          => s_clk,
     rst          => s_rst,
     f_start      => s_start,
     N            => s_N_16,
     f_done       => s_done,

     f_RW_A       => s_RW_A,
     f_Enable_A   => s_Enable_A,

     f_addr_0     => s_addr_0,
     f_data_in_0  => s_data_out_0,
     f_data_out_0 => s_data_in_0,

     f_addr_1     => s_addr_1,
     f_data_in_1  => s_data_out_1,
     f_data_out_1 => s_data_in_1,

     f_addr_2     => s_addr_2,
     f_data_in_2  => s_data_out_2,
     f_data_out_2 => s_data_in_2,
     
     f_addr_3     => s_addr_3,
     f_data_in_3  => s_data_out_3,
     f_data_out_3 => s_data_in_3,

     f_RW_B       => s_RW_B,
     f_Enable_B   => s_Enable_B,
     
     f_addr_4     => s_addr_4,
     f_data_in_4  => s_data_out_4,
     f_data_out_4 => s_data_in_4,

     f_addr_5     => s_addr_5,
     f_data_in_5  => s_data_out_5,
     f_data_out_5 => s_data_in_5,

     f_addr_6     => s_addr_6,
     f_data_in_6  => s_data_out_6,
     f_data_out_6 => s_data_in_6,

     f_addr_7     => s_addr_7,
     f_data_in_7  => s_data_out_7,
     f_data_out_7 => s_data_in_7,

     f_data_in_8  => s_data_in_8,
     f_addr_8     => s_addr_8,

     f_data_in_9  => s_data_in_9,
     f_addr_9     => s_addr_9 );


  s_clk   <= not s_clk after 10 ns;               --generate clk, rst signals
  s_rst   <= '0' after 30 ns, '1' after 60 ns;
  s_start <= '1' after 90 ns, '0' after 130 ns;   --provide go signal to start the FFT computation

end rtl;
