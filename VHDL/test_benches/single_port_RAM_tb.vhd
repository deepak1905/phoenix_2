-------------------------------------------------------------------------------
-- Title      : RAM test bench
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : single_port_RAM_tb.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere university of technology
-- Last update: 2012/08/14
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Test bench to test the RAM module with different combinations
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


entity single_port_RAM_tb is
end single_port_RAM_tb;


architecture stimulus of single_port_RAM_tb is

  --Declare the RAM component
  component single_port_RAM
    generic (
      ADDR_WIDTH : integer;
      DATA_WIDTH : integer);
    
    port (
      clk      : in    std_logic;
      rw       : in    std_logic;
      addr_bus : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));    
  end component;

  --Declare the necessary signals
  constant tb_addr_width : integer := 4;  
  signal tb_clk, tb_rw : std_logic := '0';
  signal tb_addr_bus : std_logic_vector(tb_addr_width-1 downto 0) := (others => '0');
  signal tb_data_in : std_logic_vector(31 downto 0);
  signal tb_data_out : std_logic_vector(31 downto 0);
  constant half_clk_period : time := 10 ns;
  signal write_done_1 : boolean := false;
  
begin  -- stimulus

  U0: single_port_RAM
    generic map (
      ADDR_WIDTH => 4,
      DATA_WIDTH => 32)
    
    port map (
      clk      => tb_clk,
      rw       => tb_rw,
      addr_bus => tb_addr_bus,
      data_in  => tb_data_in,
      data_out => tb_data_out);

  CLK_PROCESS: process
    begin

      tb_clk <= not tb_clk;
      wait for half_clk_period;
      
    end process CLK_PROCESS;

  --Read data from the file and write into RAM
   TEST_PROCESS:process

     file file_handle_1, file_handle_2  : text;
     variable LineRead, LineWrite : line;
     variable dataRead, dataWrite : integer;
     variable counter_write, counter_read : integer := 0;
     variable read_fileOpen, write_fileOpen, write_done, read_done, done1, done: boolean := false;
 
     begin

       --make sure that writing and
       --reading from RAM execute exclusively
       if done1 = false then

         --open the file only once
         if read_fileOpen = false then

           file_open(file_handle_1, "sp_ram.hex", READ_MODE);
           read_fileOpen := true;
        
         end if;

         --While reading from file check for the
         --end of file
         if (not endfile(file_handle_1)) then

           --If all the possible addresses are considered
           --the flag write_done is set to true
           if write_done = false then

             --read data from the file and write into RAM
             readline(file_handle_1, LineRead);
             read(LineRead, dataRead);
             tb_data_in <= conv_std_logic_vector(dataRead, 32);
             tb_addr_bus <= conv_std_logic_vector(counter_write, tb_addr_width);
             tb_rw <= '1';
             counter_write := counter_write + 1;

             wait for 4*half_clk_period;

             --If all the addresses are considered then
             --set the write_done flag to true
             if counter_write = 2**tb_addr_width then

               write_done := true;
          
             end if;
           else

             --close the file if write_done
             --is set to true
            file_close(file_handle_1);
            read_fileOpen := false;
            done1 := true;
        
           end if;

         else

           --close the file if end of file is reached
            file_close(file_handle_1);
            read_fileOpen := false;
            done1 := true;
        
         end if;
       end if;            
            
         --Read data from RAM and write it into the file

        --Make sure reading from RAM is exclusive of writing
       --into RAM
         if write_done = true then

           if done = false then

             --open the write file only once
             if write_fileOpen = false then

               file_open(file_handle_2, "sp_ram_1.hex", WRITE_MODE);
               write_fileOpen := true;
              
             end if;

             --if all the possible read addresses are considered
             --then set the read_done flag to true
              if read_done = false then

                --read from RAM
                tb_rw <= '0';
                tb_addr_bus <= conv_std_logic_vector(counter_read, tb_addr_width);

                wait for 4*half_clk_period;

                --write the value read from RAM into the file
                dataWrite := conv_integer(tb_data_out);
                counter_read := counter_read + 1;

                write(LineWrite, dataWrite);
                writeline(file_handle_2, LineWrite);
          
                if counter_read = 2**tb_addr_width then

                  read_done := true;
          
                end if;

              else

                --close the file when reading from RAM
                --is finished
                file_close(file_handle_2);
                write_fileOpen := false;
                done := true;
        
              end if;             
              
            end if;
           
          end if;           

      end process TEST_PROCESS;

end stimulus;
