-------------------------------------------------------------------------------
-- Title      : ROM test bench
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : single_port_ROM_tb.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere university of technology
-- Last update: 2012/08/14
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Test bench to test the ROM module with different combinations
--              of inputs
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/08/07  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee, std;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;


entity single_port_ROM_tb is
end single_port_ROM_tb;


architecture stimulus of single_port_ROM_tb is

  --Declare the ROM component
  component single_port_ROM
    generic (
      ADDR_WIDTH : integer;
      DATA_WIDTH : integer);
    
    port (
      clk      : in    std_logic;
      addr_bus : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));    
  end component;

  --Declare the necessary signals
  constant tb_addr_width : integer := 5;
  constant tb_data_width : integer := 32;
  signal tb_clk: std_logic := '0';
  signal tb_addr_bus : std_logic_vector(tb_addr_width-1 downto 0) := (others => '0');
  signal tb_data_out : std_logic_vector(tb_data_width-1 downto 0);
  constant half_clk_period : time := 10 ns;
  
begin  -- stimulus

  U0: single_port_ROM
    generic map (
      ADDR_WIDTH => 5,
      DATA_WIDTH => 32)
    
    port map (
      clk      => tb_clk,
      addr_bus => tb_addr_bus,
      data_out => tb_data_out);

  CLK_PROCESS: process
    begin

      tb_clk <= not tb_clk;
      wait for half_clk_period;
      
    end process CLK_PROCESS;

  --Read data from the file and write into ROM
   TEST_PROCESS:process

     file file_handle : text;
     variable LineWrite : line;
     variable dataWrite : integer;
     variable counter_read : integer := 0;
     variable fileOpen, read_done, done: boolean := false;
 
     begin
            
         --Read data from ROM and write it into the file

           if done = false then

             --open the write file only once
             if fileOpen = false then

               file_open(file_handle, "sp_rom.hex", WRITE_MODE);
               fileOpen := true;
              
             end if;

             --if all the possible read addresses are considered
             --then set the read_done flag to true
              if read_done = false then

                --read from ROM
                tb_addr_bus <= conv_std_logic_vector(counter_read, tb_addr_width);

                wait for 4*half_clk_period;

                --write the value read from ROM into the file
                dataWrite := conv_integer(tb_data_out);
                counter_read := counter_read + 1;

                write(LineWrite, dataWrite);
                writeline(file_handle, LineWrite);
          
                if counter_read = 2**tb_addr_width then

                  read_done := true;
          
                end if;

              else

                --close the file when reading from ROM
                --is finished
                file_close(file_handle);
                fileOpen := false;
                done := true;
        
              end if;             
              
            end if;

      end process TEST_PROCESS;

end stimulus;
