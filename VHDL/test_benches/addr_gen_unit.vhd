-------------------------------------------------------------------------------
-- Title      : Address generation unit
-- Project    : N-point FFT processor
-------------------------------------------------------------------------------
-- File       : addr_gen_unit.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/09/23
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
    ADDR_WIDTH : integer := 4;   --By default 64 point FFT supported
    N_width    : integer := 7);  --By default 64 point FFT is supported.

  port (
    clk       : in std_logic;                              -- input clock signal
    rst       : in std_logic;                              -- input reset signal
    N         : in std_logic_vector(N_width-1 downto 0);   -- Number of FFT points
    start     : in std_logic;                              -- Indicate the start of address generation
    count0    : out std_logic_vector(ADDR_WIDTH-1 downto 0);  --Address of memory banks to read two input values to the butterfly units
    count1    : out std_logic_vector(ADDR_WIDTH-1 downto 0);  --Address of memory banks to read next two input values to the butterfly units
    store0    : out std_logic_vector(ADDR_WIDTH-1 downto 0);  --Address of memory banks to write output values from butterfly units
    store1    : out std_logic_vector(ADDR_WIDTH-1 downto 0);  --Address of memory banks to write output values from butterfly units
    Coef0Addr : out std_logic_vector(ADDR_WIDTH+1 downto 0);  --Coefficient address for the first butterfly unit
    Coef1Addr : out std_logic_vector(ADDR_WIDTH+1 downto 0);  --Coefficient address for the second butterfly unit
    done      : out std_logic);

end addr_gen_unit;

architecture addr_gen_unit_arch of addr_gen_unit is

  --width same as that of count0
  signal s_count0 : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  -- flag indicating that address generation is in progress
  signal addr_gen_on : std_logic := '0';
  constant zero_value : std_logic_vector(ADDR_WIDTH+1 downto 0) := (others => '0');
  --stage counter, it runs like 0,1,2,3 etc  
  signal s_stage_counter : integer := 0;
                                          
  
begin  -- addr_gen_unit_arch

CLK_PROCESS: process(clk, rst)

  --number of iterations per stage = N/4  
  variable stage_iteration_count : std_logic_vector(N_width-1 downto 0) := (others => '0');
  --count of the number of stages while computing FFT(counts by shifting bit position to the left after each stage)  
  variable stage_count : std_logic_vector(N_width-1 downto 0) := (others => '0');
  variable coef : std_logic_vector(ADDR_WIDTH+1 downto 0) := (others => '0');
  variable addr_gen_freq : integer := 1;  -- the addresses are generated every two clock cycles
  variable last_stage : boolean := false;  -- to retain the values of counts and stores for one extra cycle in the last stage
    
  begin
    if rst = '1' then
      
      count0                <= (others => '0');
      count1                <= (others => '0');
      store0                <= (others => '0');
      store1                <= (others => '0');
      Coef0Addr             <= (others => '0');
      Coef1Addr             <= (others => '0');
      done                  <= '0';
      s_count0              <= (others => '0');
      addr_gen_on           <= '0';
      s_stage_counter       <= 0;
      --shifting N by two positions to the right gives N/4 = number of iterations per stage      
      stage_iteration_count := SHR(N, "10");
      --initialize stage count to 1 inorder to keep track of the stage count      
      stage_count           := stage_count(N_width-1 downto 1) & '1';
      coef                  := (others => '0');
      
    elsif clk'event and clk = '1' then

      if (start = '1' or addr_gen_on = '1') and N >= 8 then

        addr_gen_on <= '1';

        if stage_count <= N and last_stage = false then

          if addr_gen_freq /= 0 then
            
          count0 <= s_count0;          --Generate address to read two operands for the butterfies
          count1 <= not s_count0;      --Generate address to read next two operands for the butterflies
          --Generate address to write the two output results of butterflies
          store0 <= '0' & s_count0(ADDR_WIDTH-1 downto 1);
          --Generate address to write the next two output results of butterflies
          store1 <= '1' & s_count0(ADDR_WIDTH-1 downto 1);
          s_count0  <= s_count0 + 1;
          coef      := "00" & s_count0;
          --Generate address for first coefficient
--          Coef0Addr <= coef(N_width-2 downto N_width-2-s_stage_counter) & zero_value(N_width-3-s_stage_counter downto 0);
          Coef0Addr <= coef(ADDR_WIDTH+1 downto ADDR_WIDTH+1-s_stage_counter) & zero_value(ADDR_WIDTH-s_stage_counter downto 0);          
          coef      := "01" & (not s_count0);
          --Generate address for the next coefficient
--          Coef1Addr <= coef(N_width-2 downto N_width-2-s_stage_counter) & zero_value(N_width-3-s_stage_counter downto 0);
          Coef1Addr <= coef(ADDR_WIDTH+1 downto ADDR_WIDTH+1-s_stage_counter) & zero_value(ADDR_WIDTH-s_stage_counter downto 0);          

          stage_iteration_count := stage_iteration_count - 1;

          if stage_iteration_count = 0 then

            stage_iteration_count := SHR(N, "10");  --re-initialize the stage iteration count after completing each stage
            stage_count           := SHL(stage_count, "1"); --update the stage count after completing each stage
            s_count0              <= (others => '0');     --re-initialize the address counter
            s_stage_counter       <= s_stage_counter + 1; --re-initialize the stage counter

          end if;

          addr_gen_freq := addr_gen_freq - 1;

          else

            addr_gen_freq := 1;

            if stage_count = N then
              last_stage := true;              
            end if;
          
          end if;

        else

          count0          <= (others => '0');
          count1          <= (others => '0');
          store0          <= (others => '0');
          store1          <= (others => '0');
          Coef0Addr       <= (others => '0');
          Coef1Addr       <= (others => '0');
          done            <= '1';
          addr_gen_on     <= '0';
          s_stage_counter <= 0;
          
        end if;
        
      end if;
      
    end if;
  end process CLK_PROCESS;

end addr_gen_unit_arch;
