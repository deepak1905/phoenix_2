-------------------------------------------------------------------------------
-- Title      : Interconnect module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : interconnect.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/08/03
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: The interconnect which routes operand address to RAM modules
--                for operand read-write operation. It routes operands for
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

entity interconnect is
  
  generic (
    N_width : integer := 4);                 -- default value of N = 8 hence the width of port is 4("1000")

  port (
    clk             : in  std_logic;
    rst             : in  std_logic;
    RW              : in  std_logic;         -- read-write signal from control unit(0 = read, 1 = write)
    count0_i        : in  std_logic_vector(N_width-4 downto 0);  -- operand address from address gen unit
    count1_i        : in  std_logic_vector(N_width-4 downto 0);  -- operand address from address gen unit
    store0_i        : in  std_logic_vector(N_width-3 downto 0);  -- write operand address from address gen unit
    store1_i        : in  std_logic_vector(N_width-3 downto 0);  -- write operand address from address gen unit

    --the result data from butterfly output is 32 bit wide - the first two bytes
    --are real part and the next two bytes are imag part
    bfy0_add        : in  integer range -32767 to 32767;   --result of addition from butterfly0 real & imag parts
    bfy0_sub        : in  integer range -32767 to 32767;  --result of subtraction from butterfly0 unit real & imag parts
    bfy1_add        : in  integer range -32767 to 32767;  --result of addition from butterfly1 unit real & imag parts
    bfy1_sub        : in  integer range -32767 to 32767;  --result of subtraction from butterfly1 unit real & imag parts

    operand0_out_bfy : out integer range -32767 to 32767;   --input to RAM bank0 with real & imag parts 
    operand1_out_bfy : out integer range -32767 to 32767;   --input to RAM bank1 with real & imag parts 
    operand2_out_bfy : out integer range -32767 to 32767;   --input to RAM bank2 with real & imag parts 
    operand3_out_bfy : out integer range -32767 to 32767;  --input to RAM bank3 with real & imag parts 

    --NOTE: (NOTE:store addr is 1 bit bigger than count addr hence o/p addr of
    --interconnect is of the same size as that of store addr
    operand0_addr   : out std_logic_vector(N_width-3 downto 0);  -- address of operand 0
    operand1_addr   : out std_logic_vector(N_width-3 downto 0);  -- address of operand 1
    operand2_addr   : out std_logic_vector(N_width-3 downto 0);  -- address of operand 2
    operand3_addr   : out std_logic_vector(N_width-3 downto 0)); -- address of operand 3

end interconnect;

architecture interconnect_arch of interconnect is

begin  -- interconnect_arch

  --When the count0, count1 inputs change execute this process
  ADDR_PROCESS: process(clk, rst)

  variable storex_0 : std_logic_vector(N_width-3 downto 0) := (others => '0');
  variable storex_1 : std_logic_vector(N_width-3 downto 0) := (others => '0');
  variable storex_2 : std_logic_vector(N_width-3 downto 0) := (others => '0');
  variable storex_3 : std_logic_vector(N_width-3 downto 0) := (others => '0');        

    begin

      if rst = '1' then

        --Do nothing on reset

      elsif clk'event and clk = '1' then

        --update the storex values(intermediate signals)
        --and output operand values based on the first
        --bit of input count0 address
        case count0_i(0) is
          when  '0' =>
            
            storex_0 := store0_i;
            storex_2 := store0_i;

            operand0_out_bfy <= bfy0_add;
            operand2_out_bfy <= bfy0_sub;            
            
          when '1' =>
            
            storex_0 := store1_i;
            storex_2 := store1_i;

            operand0_out_bfy <= bfy1_add;
            operand2_out_bfy <= bfy1_sub;                        
            
          when others => null;
        end case;

        --update storex values(intermediate signals)
        --and output operand values based on the first
        --bit of input count1 address
        case count1_i(0) is
          when '0' =>
            
            storex_1 := store0_i;
            storex_3 := store0_i;

            operand1_out_bfy <= bfy0_add;
            operand3_out_bfy <= bfy0_sub;
            
          when '1' =>
            
            storex_1 := store1_i;
            storex_3 := store1_i;

            operand1_out_bfy <= bfy1_add;
            operand3_out_bfy <= bfy1_sub;            
            
          when others => null;
        end case;


        --set the output operand address values
        --based on the read-write signal value
        case RW is
          when '0' =>

            operand0_addr <= '0' & count0_i;
            operand1_addr <= '0' & count0_i;
            operand2_addr <= '0' & count1_i;
            operand3_addr <= '0' & count1_i;
              
          when '1' =>

            operand0_addr <= storex_0;
            operand1_addr <= storex_1;
            operand2_addr <= storex_2;
            operand3_addr <= storex_3;
              
          when others => null;
        end case;

      end if;

    end process ADDR_PROCESS;

  end interconnect_arch;
