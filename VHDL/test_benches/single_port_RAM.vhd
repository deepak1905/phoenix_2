-------------------------------------------------------------------------------
-- Title      : Single port RAM module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : single_port_RAM.vhd
-- Author     : Deepak Revanna  <deepak.revanna@tut.fi>
-- Company    : Tampere university of technology
-- Last update: 2012/12/05
-- Platform   : Altera stratix II FPGA
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
use ieee.std_logic_unsigned.all;
use std.textio.all;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity single_port_RAM is

  generic (
    FILE_NAME    :       string  := "ram_0.txt";
    ADDR_WIDTH   :       integer := 4;                              --Log(N/m) for m memory banks and N point FFT: default N=64
    DATA_WIDTH   :       integer := 32
	      );

  port (
    clk          : in    std_logic;                                 --Clock signal
    ram_rw       : in    std_logic;                                 --Read-write control signal(0 = read, 1 = write)
    ram_enable   : in    std_logic;                                 --Enable signale 1=enable, 0=disable
    ram_addr     : in    std_logic_vector(ADDR_WIDTH-1 downto 0);   --Address bus
    ram_data_in  : in    std_logic_vector(DATA_WIDTH-1 downto 0);   --The data in(upper 16 bits:real part, lower 16 bits: imaginary part)
    ram_data_out : out   std_logic_vector(DATA_WIDTH-1 downto 0);   --The data out(upper 16 bits:real part, lower 16 bits: imaginary part)
    ram_done     : in    std_logic                                  --Temporary to sense FFT completion and store results from RAM to text file
	   );                                                           
                                        
end single_port_RAM;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

architecture rtl of single_port_RAM is

  subtype ram_word   is std_logic_vector(DATA_WIDTH-1 downto 0);
  type    RAM_memory is array ((2**ADDR_WIDTH)-1 downto 0) of ram_word;
  signal temp : std_logic;

  --NOTE: We cannot reference file parameters inside
  --the pure function, hence the function is defined
  --as an impure function
  
  impure function initialize_RAM(file_name : string)             --Function to initialize RAM from text file
  return RAM_memory is

    variable ram_mem          : RAM_memory;
    file file_handle          : text;
    variable lineread         : line;
    variable dataread         : integer range -2_147_483_647 to 2_147_483_647;
    variable is_open          : boolean                               := false;
    variable num_pos          : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
    variable index            : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
    variable init_index_value : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');

    begin

    if is_open = false then

      file_open(file_handle, file_name, READ_MODE);
      is_open := true;

    end if;

    num_pos             := conv_std_logic_vector(ADDR_WIDTH, ADDR_WIDTH+1);         --Read data from RAM initialization file and : store it in RAM
    init_index_value(0) := '1';
    index               := SHL(init_index_value, num_pos);
    
    for i in 0 to conv_integer(index)-1 loop

        if (not endfile(file_handle)) then
          
            readline(file_handle, lineread);
            read(lineread, dataread);
            ram_mem(i) := conv_std_logic_vector(dataread, DATA_WIDTH);

        end if;

    end loop;

    file_close(file_handle);
    return ram_mem;
      
  end function initialize_RAM;
  
-------------------------------------------------------------------------------

  signal RAM_memory_bank : RAM_memory                              := initialize_RAM(FILE_NAME); --Instantiate and initialize RAM
  signal undef_value     : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => 'U');

  begin

    RW_PROCESS: process(clk)                                                             --Perform synchronous read-write RAM operation

      file file_handle   : text;
      variable linewrite : line;
      variable datawrite : integer;
      
    begin

        if clk'event and clk = '1' then

            if ram_rw = '0' then                                                         --Read operation when ram_rw='0'

                if ram_enable = '1' and ram_addr /= undef_value then                     --Read when enable is active and address is valid

                    ram_data_out <= RAM_memory_bank(conv_integer(unsigned(ram_addr)));   --Read from the RAM and send the data in the output bus
          
                end if;          

            elsif ram_rw = '1' then                                                      --Write operation when ram_rw='1'

                if ram_enable = '1' and ram_addr /= undef_value then                     --Write only if enable is active and the address is valid

                    RAM_memory_bank(conv_integer(unsigned(ram_addr))) <= ram_data_in;    --Write the data coming in from input bus into RAM

                end if;

            end if;

        end if;

    end process RW_PROCESS;

end rtl;
