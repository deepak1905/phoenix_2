-------------------------------------------------------------------------------
-- Title      : Single port RAM module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : single_port_RAM.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere university of technology
-- Last update: 2012/08/14
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

entity single_port_RAM is
  
  generic (
    ADDR_WIDTH : integer := 4;
    DATA_WIDTH : integer := 32);         -- the width of address bus configurable at the design time(
                                        -- default width for 64 point FFT which
                                        -- requires storing 16 operands per bank

  port (
    clk      : in    std_logic;         -- clock signal
    rw       : in    std_logic;
                                        -- read-write control signal(0 = read, 1 = write)
    addr_bus : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
                                        -- the address bus whose width is configurable at the design time
--    data_bus : inout integer range -32767 to 32767);           --the data bus carrying the data(upper 16 bits for real part of data and lower 16 bits is for imaginary part of data)
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));

                                        
end single_port_RAM;

architecture rtl of single_port_RAM is

  subtype ram_word is std_logic_vector(DATA_WIDTH-1 downto 0);
  type RAM_memory is array ((2**ADDR_WIDTH)-1 downto 0) of ram_word;
  signal RAM_memory_bank : RAM_memory;

  begin

    --perform synchronous read-write RAM operation
    RW_PROCESS: process(clk)
    
    begin

      if clk'event and clk = '1' then

        if rw = '0' then

          --read from the RAM and send the data in the output bus
          data_out <= RAM_memory_bank(conv_integer(unsigned(addr_bus)));
          
          else

            --write the data coming in from input bus into the RAM
            --and drive the output bus into tristate value
            RAM_memory_bank(conv_integer(unsigned(addr_bus))) <= data_in;
            data_out <= (others => 'Z');
            
        end if;

      end if;
      
    end process RW_PROCESS;

end rtl;
