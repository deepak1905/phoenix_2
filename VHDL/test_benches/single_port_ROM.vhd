-------------------------------------------------------------------------------
-- Title      : Single port ROM module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : single_port_ROM.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere university of technology
-- Last update: 2012/10/04
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Single port ROM module enables single clock read
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

entity single_port_ROM is
  
  generic (
    FILE_NAME  : string := "rom_0.txt";
    ADDR_WIDTH : integer := 5;         -- the width of address bus configurable at the design time(default width for 64 point
                                       -- FFT  which requires storing 32 twiddle factors per bank)
    DATA_WIDTH : integer := 32);         

  port (
    clk      : in    std_logic;         -- clock signal
    addr_bus : in    std_logic_vector(ADDR_WIDTH-1 downto 0);  -- the address bus whose width is configurable at the design time
    --the data bus carrying the data(upper 16 bits for real part of data and lower 16 bits is for imaginary part of data)    
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
                                        
end single_port_ROM;

architecture rtl of single_port_ROM is

  subtype rom_word is std_logic_vector(DATA_WIDTH-1 downto 0);
  type ROM_memory is array ((2**ADDR_WIDTH)-1 downto 0) of rom_word;
  file file_handle : text;

  --function to initialize ROM with default values
  --NOTE: We cannot reference file parameters inside
  --the pure function, hence the function is defined
  --as an impure function
  impure function initialize_ROM(file_name : string)
    return ROM_memory is

    --function to initialize ROM memory to
    --initial default values
    variable ROM_mem_init : ROM_memory;
    file file_handle : text;
    variable lineread : line;
    variable dataread : integer;
    variable is_open : boolean := false;

    begin

      if is_open = false then

      file_open(file_handle, file_name, READ_MODE);
      is_open := true;

      end if;

      --for 8 point FFT
      for i in 0 to 3 loop

        if (not endfile(file_handle)) then

          readline(file_handle, lineread);
          read(lineread, dataread);

          ROM_mem_init(i) := conv_std_logic_vector(dataread, DATA_WIDTH);

        end if;        
      end loop;  -- i

      file_close(file_handle);
      return ROM_mem_init;
      
  end function initialize_ROM;

  --create ROM unit and initialize the contents with zeros
  --NOTE:ROM initialization to zeros can be done as (others =>(others=>'0'))
  --but used a function to initialize - just for a change.!
  signal ROM_memory_bank : ROM_memory := initialize_ROM(FILE_NAME);
  signal undef_value : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => 'U');

  begin

    --perform synchronous read operation
    READ_PROCESS: process(clk)
    
    begin

      if clk'event and clk = '1' then

        --If there is a valid address value
        --only then send the read the data
        --out from ROM otherwise drive the
        --data bus to tristate
        if addr_bus /= undef_value then
          
        --read from ROM and send the data in the output bus
        data_out <= ROM_memory_bank(conv_integer(unsigned(addr_bus)));
        
        else

          --If the address bus has invalid value drive
          --the data bus to high impedence state
          data_out <= (others => 'Z');
          
        end if;
        
      end if;
      
    end process READ_PROCESS;

end rtl;
