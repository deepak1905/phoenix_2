-------------------------------------------------------------------------------
-- Title      : Single port ROM module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : single_port_ROM.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere university of technology
-- Last update: 2012/08/14
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity single_port_ROM is
  
  generic (
    ADDR_WIDTH : integer := 5;         -- the width of address bus configurable at the design time(default width for 64 point
                                       -- FFT  which requires storing 32 twiddle factors per bank
    DATA_WIDTH : integer := 32);         

  port (
    clk      : in    std_logic;         -- clock signal
    addr_bus : in    std_logic_vector(ADDR_WIDTH-1 downto 0);  -- the address bus whose width is configurable at the design time
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));   --the data bus carrying the data(upper 16 bits for real part of data and lower 16 bits is for imaginary part of data)
                                        
end single_port_ROM;

architecture rtl of single_port_ROM is

  subtype rom_word is std_logic_vector(DATA_WIDTH-1 downto 0);
  type ROM_memory is array ((2**ADDR_WIDTH)-1 downto 0) of rom_word;
  signal ROM_init_value : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

  --function to initialize ROM with default values
  function initialize_ROM
    return ROM_memory is

    --function to initialize ROM memory to
    --initial default values
    variable ROM_mem_init : ROM_memory;

    begin

      for i in 2**ADDR_WIDTH-1 downto 0 loop
        
        ROM_mem_init(i) := (others=>'0');
        
      end loop;  -- i

      return ROM_mem_init;
      
  end function initialize_ROM;

  --create ROM unit and initialize the contents with zeros
  --NOTE:ROM initialization to zeros can be done as (others =>(others=>'0'))
  --but used a function to initialize - just for a change.!
  signal ROM_memory_bank : ROM_memory := initialize_ROM;

  begin

    --perform synchronous read operation
    READ_PROCESS: process(clk)
    
    begin

      if clk'event and clk = '1' then

        --read from ROM and send the data in the output bus
        data_out <= ROM_memory_bank(conv_integer(unsigned(addr_bus)));
          
      end if;
      
    end process READ_PROCESS;

end rtl;
