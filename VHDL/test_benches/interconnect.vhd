-------------------------------------------------------------------------------
-- Title      : Interconnect module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : interconnect.vhd
-- Author     : Deepak Revanna  <deepak.revanna@tut.fi>
-- Co-Author  : Manuele Cucchi  <manuele.cucchi@studio.unibo.it>
-- Company    : Tampere University of Technology
-- Last update: 2012/12/05
-- Platform   : Altera stratix II FPGA
-------------------------------------------------------------------------------
-- Description: The interconnect which routes operand address to RAM modules
--                for operand read-write operation. It also routes operands for
--                writing into RAM modules
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/07/24  1.0      revanna	Created
-------------------------------------------------------------------------------

--Include libraries and packages
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity interconnect is
  
  generic (
    ADDR_WIDTH         :     integer := 4;                              --Log(N/m) for m memory banks, default value 4 for 64 pt FFT
    N_width            :     integer := 7;                              --Width = ADDR_WIDTH+3, By fault N = 64 point FFT is supported 64("1000000")
    DATA_WIDTH         :     integer := 32                              --By default the data width is 32 bits
          );
   
  port (
  
    --Signals from control unit
    clk                : in  std_logic;                                --Clk signal
    rst                : in  std_logic;                                --Active low reset signal
    i_RW               : in  std_logic;                                --Read-write signal from control unit(0 = read, 1 = write)
    i_last_stage       : in  std_logic;                                --Indicate if the current stage is last stage or not
    i_input_flip       : in  std_logic;

    --Signals from address generation unit
    i_read_data        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  --Read operand address from address gen unit
    i_read_data1       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  --Second Read operand address from address gen unit
    i_store_add        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  --Add result address from address gen unit
    i_store_sub        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  --Subtraction result operand address from address gen unit

    --NOTE: The result data from butterfly output is 32 bit wide - the first two bytes
    --are real part and the next two bytes are imag part
    
    i_bfy0_in_first    : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --Result of addition from butterfly0
    i_bfy0_in_second   : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --Result of subtraction from butterfly0
    i_bfy1_in_first    : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --Result of addition from butterfly1
    i_bfy1_in_second   : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --Result of subtraction from(to) butterfly1

    i_bfy0_out_first   : out std_logic_vector(DATA_WIDTH-1 downto 0);  --First Input to butterfly0
    i_bfy0_out_second  : out std_logic_vector(DATA_WIDTH-1 downto 0);  --Second input to butterfly0
    i_bfy1_out_first   : out std_logic_vector(DATA_WIDTH-1 downto 0);  --First input to butterfly1
    i_bfy1_out_second  : out std_logic_vector(DATA_WIDTH-1 downto 0);  --Second input to butterfly1    

    --Signals from/to RAM memory banks
    i_data_in_RAM0     : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --Data input from RAM bank0
    i_data_in_RAM1     : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --Data input from RAM bank1 
    i_data_in_RAM2     : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --Data input from RAM bank2 
    i_data_in_RAM3     : in  std_logic_vector(DATA_WIDTH-1 downto 0);  --Data input from RAM bank3

    i_data_out_RAM0    : out std_logic_vector(DATA_WIDTH-1 downto 0);  --Data output to RAM bank0
    i_data_out_RAM1    : out std_logic_vector(DATA_WIDTH-1 downto 0);  --Data output to RAM bank1
    i_data_out_RAM2    : out std_logic_vector(DATA_WIDTH-1 downto 0);  --Data output to RAM bank2
    i_data_out_RAM3    : out std_logic_vector(DATA_WIDTH-1 downto 0);  --Data output to RAM bank3
                                                                      
    i_addr_RAM0        : out std_logic_vector(ADDR_WIDTH-1 downto 0);  --Address of RAM 0
    i_addr_RAM1        : out std_logic_vector(ADDR_WIDTH-1 downto 0);  --Address of RAM 1
    i_addr_RAM2        : out std_logic_vector(ADDR_WIDTH-1 downto 0);  --Address of RAM 2
    i_addr_RAM3        : out std_logic_vector(ADDR_WIDTH-1 downto 0)); --Address of RAM 3

end interconnect;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

architecture interconnect_arch of interconnect is

  signal s_read_data, s_read_data1 : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_store_add               : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_store_sub               : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal s_bfy0_in_second          : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_bfy1_in_second          : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_input_flip              : std_logic;
  
begin  -- interconnect_arch

    ADDR_PROCESS: process(clk, rst)

    begin

        if rst = '0' then

            --Do nothing

        elsif clk'event and clk = '1' then

            s_read_data     <= i_read_data;
            s_read_data1    <= i_read_data1;
            s_store_sub     <= i_store_sub;
            s_store_add     <= i_store_add;
            s_input_flip    <= i_input_flip;

            if i_RW = '0' then                                -- Routing RAM addresses based on the RW signal, RW = 0 routes read adresses, RW = 1 routes store addresses

                i_addr_RAM0 <= i_read_data;
                i_addr_RAM1 <= i_read_data;
                i_addr_RAM2 <= i_read_data;
                i_addr_RAM3 <= i_read_data;

                if i_last_stage = '0' then                    -- Routing data from RAM banks to butterflies during read mode
                                                     
                    if s_input_flip = '0' then                -- From 0th stage to m-1 stage the bfy0 is supplied with data from RAM0 &
                                                              -- RAM1 and bfy1 is supplied with data from RAM2 & RAM3
                        i_bfy0_out_first  <= i_data_in_RAM0;
                        i_bfy0_out_second <= i_data_in_RAM1;
                        i_bfy1_out_first  <= i_data_in_RAM2;
                        i_bfy1_out_second <= i_data_in_RAM3;

                    else

                        i_bfy0_out_first  <= i_data_in_RAM1;
                        i_bfy0_out_second <= i_data_in_RAM0;
                        i_bfy1_out_first  <= i_data_in_RAM3;
                        i_bfy1_out_second <= i_data_in_RAM2;              

                    end if;            

                else
                                                   
                    i_bfy0_out_first  <= i_data_in_RAM0;      -- From 0th stage to m-1 stage the bfy0 is supplied with data from RAM0 &
                    i_bfy0_out_second <= i_data_in_RAM2;      -- RAM1 and bfy1 is supplied with data from RAM2 & RAM3
                    i_bfy1_out_first  <= i_data_in_RAM1;
                    i_bfy1_out_second <= i_data_in_RAM3;

                end if;                                       -- end if last_stage = '0'
          
            else

                if s_read_data1(0) = '0' then                 -- If the lsb of read_data_i is 0 the addition result is stored in RAM0 &
                                                              -- RAM2 and the result of subtraction stored in RAM1 & RAM
                    i_addr_RAM0      <= s_store_add;
                    i_addr_RAM2      <= s_store_add;              
                    i_addr_RAM1      <= s_store_sub;
                    i_addr_RAM3      <= s_store_sub;
                    s_bfy0_in_second <= i_bfy0_in_second;
                    s_bfy1_in_second <= i_bfy1_in_second;
                    i_data_out_RAM0  <= i_bfy0_in_first;
                    i_data_out_RAM2  <= i_bfy1_in_first;
                    i_data_out_RAM1  <= s_bfy0_in_second;
                    i_data_out_RAM3  <= s_bfy1_in_second;                                

                else                                           -- If the lsb of read_data_i is 1 the addition result is stored in RAM1 &
                                                               -- RAM 3 and the result of subtraction is stored in RAM0 & RAM2
                    i_addr_RAM0      <= s_store_sub;
                    i_addr_RAM2      <= s_store_sub;              
                    i_addr_RAM1      <= s_store_add;
                    i_addr_RAM3      <= s_store_add;                
                    s_bfy0_in_second <= i_bfy0_in_second;
		    s_bfy1_in_second <= i_bfy1_in_second;
		    i_data_out_RAM0  <= s_bfy0_in_second;
		    i_data_out_RAM2  <= s_bfy1_in_second;
		    i_data_out_RAM1  <= i_bfy0_in_first;
		    i_data_out_RAM3  <= i_bfy1_in_first;              

                end if;                                        --end if read_data_i(0) = '0'

            end if;                                            --end of RW = '0'
        
        end if;                                               -- rst = '0'

    end process ADDR_PROCESS;

 end interconnect_arch;
