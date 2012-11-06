-------------------------------------------------------------------------------
-- Title      : Single port RAM module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : single_port_RAM.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere university of technology
-- Last update: 2012/11/06
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Single port RAM module enables single clock read-write
--              operation of data.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/08/06  1.0      revanna	Created
-------------------------------------------------------------------------------

--Include necessary library and
--packages
library ieee, std;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;

entity single_port_RAM is
  
  generic (
    FILE_NAME  : string  := "ram_0.txt";
    ADDR_WIDTH : integer := 4;
    DATA_WIDTH : integer := 32);         -- the width of address bus configurable at the design time(
                                        -- default width for 64 point FFT which
                                        -- requires storing 16 operands per bank

  port (
    clk      : in    std_logic;         -- clock signal
    rw       : in    std_logic;         -- read-write control signal(0 = read, 1 = write)
    addr_bus : in    std_logic_vector(ADDR_WIDTH-1 downto 0);   -- the address bus whose width is configurable at the design time
    
    --the data bus carrying the data(upper 16 bits for real part of data and lower 16 bits is for imaginary part of data)
    data_in  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
    done     : in std_logic);           --FFT completion signal required to
                                        --write the final results back to file
                                        --(data verification strategy)

                                        
end single_port_RAM;

architecture rtl of single_port_RAM is

  subtype ram_word is std_logic_vector(DATA_WIDTH-1 downto 0);
  type RAM_memory is array ((2**ADDR_WIDTH)-1 downto 0) of ram_word;
  signal temp : std_logic;

  impure function initialize_RAM(file_name : string)
    return RAM_memory is

    file file_handle : text;
    variable lineread : line;
    variable dataread : integer range -2_147_483_647 to 2_147_483_647;
    variable ram_mem : RAM_memory;
    variable is_open : boolean := false;

  begin

    if is_open = false then

    file_open(file_handle, file_name, READ_MODE);
    is_open := true;

    end if;

      --for 8 point FFT
      for i in 0 to 1 loop

        if (not endfile(file_handle)) then
          
          readline(file_handle, lineread);
          read(lineread, dataread);
          ram_mem(i) := conv_std_logic_vector(dataread, DATA_WIDTH);

        end if;      

      end loop;

      file_close(file_handle);
      return ram_mem;
      
    end function initialize_RAM;

  signal RAM_memory_bank : RAM_memory := initialize_RAM(FILE_NAME);
  signal undef_value : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => 'U');

  begin

    --perform synchronous read-write RAM operation
    RW_PROCESS: process(clk)

      file file_handle : text;
      variable linewrite: line;
      variable datawrite : integer;
      
    begin

      if clk'event and clk = '1' then

        if rw = '0' then

          --Read from RAM only if the address is valid
          if addr_bus /= undef_value then
            
          --read from the RAM and send the data in the output bus
          data_out <= RAM_memory_bank(conv_integer(unsigned(addr_bus)));

          else

            --drive the output to tristate if
            --the address bus is invalid
            data_out <= (others => 'Z');

          end if;          
          
        elsif rw = '1' then

          --write only if the address is valid
          if addr_bus /= undef_value then
            
            --write the data coming in from input bus into the RAM
            --and drive the output bus into tristate value
            RAM_memory_bank(conv_integer(unsigned(addr_bus))) <= data_in;
            
          end if;

          --drive the output data bus to tristate during
          --the read operation
          data_out <= (others => 'Z');
            
        else

          --when the rw signal is not valid, drive
          --output to tristate
          data_out <= (others => 'Z');              
            
        end if;

--        temp <= done;
--
--        if temp = '1' then
--
--        file_open(file_handle, file_name, WRITE_MODE);
--
--          for i in 0 to 1 loop
--
--            datawrite := conv_integer(signed(RAM_memory_bank(i)));
--            write(linewrite, datawrite);
--            writeline(file_handle, linewrite);
--
--          end loop;
--
--          file_close(file_handle);
--
--        end if;

      end if;

    end process RW_PROCESS;

end rtl;
