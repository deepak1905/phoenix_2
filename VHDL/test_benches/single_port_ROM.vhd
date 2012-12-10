-------------------------------------------------------------------------------
-- Title      : Single port ROM module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : single_port_ROM.vhd
-- Author     : Deepak Revanna  <deepak.revanna@tut.fi>
-- Company    : Tampere university of technology
-- Last update: 2012/12/05
-- Platform   : Altera stratix II FPGA
-------------------------------------------------------------------------------
-- Description: Single port ROM module enables single clock read
--              operation of data.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/08/06  1.0      Revanna	Created
-------------------------------------------------------------------------------

--Include necessary library and
--packages

library ieee, std;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity single_port_ROM is
  
  generic (
    FILE_NAME    :     string  := "rom.txt";
    ADDR_WIDTH   :     integer := 5;
    DATA_WIDTH   :     integer := 32
	      );

  port (
    clk          : in  std_logic;                                  --Clock signal
    rom_addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);    --The address bus
    rom_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)     --The data bus(upper 16 bits: real part, lower 16 bits:  imaginary part)    
       );
	   
end single_port_ROM;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


architecture rtl of single_port_ROM is

  subtype rom_word      is std_logic_vector(DATA_WIDTH-1 downto 0);
  type    ROM_memory    is array ((2**ADDR_WIDTH)-1 downto 0) of rom_word;
  file    file_handle : text;

  --NOTE: We cannot reference file parameters inside
  --the pure function, hence the function is defined
  --as an impure function
  
  impure function initialize_ROM(file_name : string)               --Function to initialize ROM with data read from initialization text file
  return ROM_memory is
	
    variable ROM_mem_init     : ROM_memory;
    file file_handle          : text;
    variable lineread         : line;
    variable dataread         : integer;
    variable is_open          : boolean                               := false;
    variable num_pos          : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
    variable index            : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
    variable init_index_value : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');

    begin
	
	if is_open = false then

        file_open(file_handle, file_name, READ_MODE);
        is_open := true;

    end if;

    num_pos             := conv_std_logic_vector(ADDR_WIDTH-1, ADDR_WIDTH+1);   --Read data from ROM initialization text file and store in ROM
    init_index_value(0) := '1';
    index               := SHL(init_index_value, num_pos);
      
    for i in 0 to (conv_integer(index)-1) loop

        if (not endfile(file_handle)) then
		
            readline(file_handle, lineread);
            read(lineread, dataread);
            ROM_mem_init(i) := conv_std_logic_vector(dataread, DATA_WIDTH);
        
		end if;   
     
    end loop;  -- i

    file_close(file_handle);
    return ROM_mem_init;
      
  end function initialize_ROM;

-------------------------------------------------------------------------------

  --NOTE:ROM initialization to zeros can be done as (others =>(others=>'0'))
  --but used a function to initialize - just for a change.!
  
  signal ROM_memory_bank : ROM_memory                              := initialize_ROM(FILE_NAME);   --Instantiate ROM and initialize
  signal undef_value     : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => 'U');

  begin

    READ_PROCESS: process(clk)                                                                     --Perform synchronous read operation
    
    begin

        if clk'event and clk = '1' then

            if rom_addr /= undef_value then                                                        --Read only if the address is valid
          
                rom_data_out <= ROM_memory_bank(conv_integer(unsigned(rom_addr)));                 --Read from ROM and send the data in the output bus
        
            else

                rom_data_out <= (others => 'Z');                                                   --If the address iss invalid drive the data bus to high impedence state
          
            end if;
        
        end if;
      
    end process READ_PROCESS;

end rtl;
