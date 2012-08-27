-------------------------------------------------------------------------------
-- Title      : Address generation unit
-- Project    : 
-------------------------------------------------------------------------------
-- File       : addr_gen_unit.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/08/03
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: The address generation unit generates following addresses in
--              one clock cyle
--              a. 4 operand addresses corresponding to 4 input operands
--              to butterfly which are read from RAM memory banks.
--              b. 4 Result operand addresses which are to be written into RAM
--              memory banks after butterfly operation.
--              c. 2 twiddle factor addresses required to feed two butterfly
--              units simultaneously in the same clock cycle.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/07/20  1.0      revanna	Created
-------------------------------------------------------------------------------

--Include libraries and packages
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity addr_gen_unit is
  
  generic (
    N_width : integer := 4);  --The default width of N(number of FFT points) value. Because 8 point FFT is the mimimum FFT computation supported.

  port (
    clk       : in std_logic;                              -- input clock signal
    rst       : in std_logic;                              -- input reset signal
    N         : in std_logic_vector(N_width-1 downto 0);   -- Number of FFT points
    start     : in std_logic;                              -- Indicate the start of address generation
    count0    : out std_logic_vector(N_width-4 downto 0);  --Address of memory banks to read two input values to the butterfly units
    count1    : out std_logic_vector(N_width-4 downto 0);  --Address of memory banks to read next two input values to the butterfly units
    store0    : out std_logic_vector(N_width-3 downto 0);  --Address of memory banks to write output values from butterfly units
    store1    : out std_logic_vector(N_width-3 downto 0);  --Address of memory banks to write output values from butterfly units
    Coef0Addr : out std_logic_vector(N_width-2 downto 0);  --Coefficient address for the first butterfly unit
    Coef1Addr : out std_logic_vector(N_width-2 downto 0);  --Coefficient address for the second butterfly unit
    done      : out std_logic);

end addr_gen_unit;

architecture addr_gen_unit_arch of addr_gen_unit is

  signal s_count0 : std_logic_vector(N_width-4 downto 0) := (others => '0');  --width same as that of count0
  signal addr_gen_on : std_logic := '0';  -- flag indicating that address generation is in progress
  constant zero_value : std_logic_vector(N_width-2 downto 0) := (others => '0');
  signal s_stage_counter : integer := 0;  --stage counter, it runs like 0,1,2,3 etc
                                          
  
begin  -- addr_gen_unit_arch

CLK_PROCESS: process(clk, rst)
  
  variable stage_iteration_count : std_logic_vector(N_width-1 downto 0) := (others => '0');  --number of iterations per stage = N/4
  variable stage_count : std_logic_vector(N_width-1 downto 0) := (others => '0');  --count of the number of stages while computing FFT(counts by shifting bit position to the left after each stage)
  variable coef : std_logic_vector(N_width-2 downto 0) := (others => '0');
    
  begin
    if rst = '1' then
      
      count0    <= (others => '0');
      count1    <= (others => '0');
      store0    <= (others => '0');
      store1    <= (others => '0');
      Coef0Addr <= (others => '0');
      Coef1Addr <= (others => '0');
      done      <= '0';
      s_count0 <= (others => '0');
      addr_gen_on <= '0';
      s_stage_counter <= 0;
      stage_iteration_count := SHR(N, "10"); --shifting N by two positions to the right gives N/4 = number of iterations per stage
      stage_count := stage_count(N_width-1 downto 1) & '1'; --initialize stage count to 1 inorder to keep track of the stage count
      coef := (others => '0');
      
    elsif clk'event and clk = '1' then

      if (start = '1' or addr_gen_on = '1') and N >= 8 then

        addr_gen_on <= '1';

        if stage_count /= N then

          count0 <= s_count0;          --Generate address to read two operands for the butterfies
          count1 <= not s_count0;      --Generate address to read next two operands for the butterflies
          store0 <= '0' & s_count0;    --Generate address to write the two output results of butterflies
          store1 <= '1' & s_count0;    --Generate address to write the next two output results of butterflies
          s_count0 <= s_count0 + 1;
          coef := "00" & s_count0;
          Coef0Addr <= coef(N_width-2 downto N_width-2-s_stage_counter) & zero_value(N_width-3-s_stage_counter downto 0); --Generate address for first coefficient
          coef := "01" & (not s_count0);
          Coef1Addr <= coef(N_width-2 downto N_width-2-s_stage_counter) & zero_value(N_width-3-s_stage_counter downto 0); --Generate address for the next coefficient

          stage_iteration_count := stage_iteration_count - 1;

          if stage_iteration_count = 0 then
          
            stage_iteration_count := SHR(N, "10");  --re-initialize the stage iteration count after completing each stage
            stage_count := SHL(stage_count, "1");  --update the stage count after completing each stage
            s_count0 <= (others => '0');  --re-initialize the address counter
            s_stage_counter <= s_stage_counter + 1; --re-initialize the stage counter
          
          end if;

        else
          
          count0 <= (others => '0');
          done <= '1';
          addr_gen_on <= '0';
          
        end if;
        
      end if;
      
    end if;
  end process CLK_PROCESS;

end addr_gen_unit_arch;
