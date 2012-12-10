-------------------------------------------------------------------------------
-- Title      : Address generation unit
-- Project    : N-point FFT processor
-------------------------------------------------------------------------------
-- File       : addr_gen_unit.vhd
-- Author     : Deepak Revanna <deepak.revanna@tut.fi>
-- Co-Author  : Manuele Cucchi <manuele.cucchi@studio.unibo.it> 
-- Company    : Tampere University of Technology
-- Last update: 2012/12/05
-- Platform   : Altera stratix II FPGA
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

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
entity addr_gen_unit is

  generic (
    ADDR_WIDTH    : integer := 4;                                  --Log(N/m) for m  memory banks;
    N_width       : integer := 7);                                 --ADDR_WIDTH + 3;

  port (
    clk           : in  std_logic;                                 --Input clock signal
    rst           : in  std_logic;                                 --Input active low reset signal
    N             : in  std_logic_vector(N_width-1 downto 0);      --Number of FFT points
    a_start       : in  std_logic;                                 --Indicate the start of FFT computation
    a_begin_stage : in  std_logic;                                 --Indicate the beginning of FFT stage
    
    a_read_data   : out std_logic_vector(ADDR_WIDTH-1 downto 0);   --Address of memory banks to read butterfly inputs
    a_read_data1  : out std_logic_vector(ADDR_WIDTH-1 downto 0);   --Input value address required to route the butterfly outputs to memory banks
    a_store_add   : out std_logic_vector(ADDR_WIDTH-1 downto 0);   --Address of memory banks to write addition output values from butterfly units
    a_store_sub   : out std_logic_vector(ADDR_WIDTH-1 downto 0);   --Address of memory banks to write subtraction output values from butterfly units
    a_Coef0Addr   : out std_logic_vector(ADDR_WIDTH+1 downto 0);   --Coefficient address for the first butterfly unit
    a_Coef1Addr   : out std_logic_vector(ADDR_WIDTH+1 downto 0);   --Coefficient address for the second butterfly unit
    a_done        : out std_logic);

end addr_gen_unit;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

architecture addr_gen_unit_arch of addr_gen_unit is

  constant s_zero_value      : std_logic_vector(ADDR_WIDTH   downto 0) := (others => '0'); --For computation of twiddle factor address
  signal   s_addr_gen_on     : std_logic                               := '0'            ; --Flag indicating that address generation is in progress
  signal   s_num_iteration   : std_logic_vector(N_width-1 downto 0)    := (others => '0'); --Indicates half the stage in iterating a stage
  constant WRITE_SET_UP_TIME : integer                                 := 9;               --9 clock cycles required to start memory store operation after beginning of stage                     

  
begin  -- addr_gen_unit_arch

CLK_PROCESS: process(clk, rst)

  variable v_stage_iteration_count : std_logic_vector(N_width-1 downto 0)    := (others => '0');  --Number of iterations per stage = N/4
  variable v_stage_count           : std_logic_vector(N_width-1 downto 0)    := (others => '0');  --Count of the number of stages while computing
                                                                                                  --FFT(counts by shifting bit position to the left after each stage)
  variable v_coef                  : std_logic_vector(ADDR_WIDTH+1 downto 0) := (others => '0');  --Temporary twiddle factor address
  variable v_addr_gen_freq         : integer                                 := 0             ;   --The addresses are generated every two clock cycles
  variable v_last_stage            : boolean                                 := false          ;  --True - for last stage, false - for other stages
  variable s_count                 : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');  --Temporary input read address
  variable s_count1                : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');  --Temporary input read address required for routing butterfly outputs
  variable s_store_count           : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');  --Store address for butterfly addition and subtraction results
  variable s_stage_counter         : integer                                 := 0              ;  --Stage counter, it runs like 0,1,2,3 etc
  variable s_count_gray            : std_logic_vector(ADDR_WIDTH   downto 0) := (others => '0');  --Gray counter for computation of twiddle factor address
  variable s_temp_gray             : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');  --Temporary gray counter for computation of twiddle factor address
  variable cycle_count             : integer                                 := 0;                --Keep count of cycle clocks
    
  begin
    
    if rst = '0' then

        a_read_data             <= (others => '0');
        s_count                 := (others => '0');      
        a_store_add             <= (others => '0');
        a_store_sub             <= (others => '0');
        s_store_count           := (others => '0');
        s_count_gray            := (others => '0');
        s_temp_gray             := (others => '0');
        a_Coef0Addr             <= (others => '0');
        a_Coef1Addr             <= (others => '0');
        a_done                  <= '0';
        s_addr_gen_on           <= '0';
        s_stage_counter         := 0;
        v_stage_iteration_count := SHR(N, "10");                             --Shifting N by two positions to the right gives N/4 = number of iterations per stage 
        s_num_iteration         <= SHR(v_stage_iteration_count,"01" );       --Indicates half the stage while performing iterations
        v_stage_count           := v_stage_count(N_width-1 downto 1) & '1';  --Initialize stage count to 1 inorder to keep track of the stage count
        cycle_count             := 0;                                                                    

    elsif (clk'event and clk = '1') then

        if a_begin_stage = '1' and a_start = '0' then

            s_count                        := (others => '0');
            v_stage_iteration_count        := SHR(N, "10");                      --Re-initialize the stage iteration count after completing each stage
            s_store_count                  := (others => '0');                   --Re-initialize the store address counter
            s_stage_counter                := s_stage_counter + 1;               --Re-initialize the stage counter
            v_stage_count                  := SHL(v_stage_count, "1");           --Update the stage count after completing each stage
            v_addr_gen_freq                := 0;                                 --Re-initialize the address generation frequency at the beginning of stage
            cycle_count                    := 0;                                 --Re-initialize the cycle count at the beginning of stage
                                 
            if v_stage_count = SHR(N, "01") then                                 --Temporary twiddle factor address is re-initialized at the beginning of stage
            
                v_coef := (others => '0');
                v_coef(0) := '1';

            else
              
                v_coef    := (others => '0');
                                      
            end if;
            
        end if;

        if ((a_begin_stage = '1' or s_addr_gen_on = '1') and N > 8) then

            s_addr_gen_on <= '1';                                        --Set the address generation flag on
                              
            if cycle_count = (WRITE_SET_UP_TIME-1) then                  --After 9 cycles from the beginning of the stage reset store counter and corresponding read address counter
                                
                s_count1       := (others => '0');
                s_store_count  := (others => '0');
                                
            end if;

            cycle_count := cycle_count + 1;
          
            if (v_stage_count < N) then
              
                if (v_addr_gen_freq = 0) then

                    if v_stage_count = SHR(N, "01") then
                      
                        v_last_stage := true;
                        
                    end if;
                    
                    a_read_data  <= s_count;                           --Generate address to read two operands for the butterfies
                    a_read_data1 <= s_count1;                          --Generate read address for routing the butterfly outputs

                    if s_count1(0) = '0' then                          --Generate store address
                      
                        a_store_add     <= s_store_count;
                        a_store_sub     <= not s_store_count;
                        s_store_count   := s_store_count + 1;
            
                    end if;
                                                    
                    if (v_last_stage = false) then                        --Generate coefficient stages other than last stage 
                      
                        s_temp_gray   := s_count xor SHR(s_count,"01");   --Create a gray count value by xoring the one bit shift result of count with the count itself.
                        s_count_gray  := '0' & s_temp_gray( ADDR_WIDTH-1 downto 0);
                        v_coef        := s_count_gray(ADDR_WIDTH downto ADDR_WIDTH-s_stage_counter) & s_zero_value(ADDR_WIDTH-s_stage_counter downto 0);
                        a_Coef0Addr   <= v_coef;
                        a_Coef1Addr   <= v_coef;

                    else
                      
                        v_coef := '0' & (s_count + v_coef(ADDR_WIDTH downto 1)) & not v_coef(0);  --Different coefficient address generation logic for last stage

                        if v_stage_iteration_count > s_num_iteration then
                          
                            v_coef(ADDR_WIDTH downto ADDR_WIDTH) := "0";
              
                        else
                          
                            v_coef(ADDR_WIDTH downto ADDR_WIDTH) := "1";
              
                        end if;
            
                        a_Coef0Addr <= v_coef;
                        a_Coef1Addr <= v_coef(ADDR_WIDTH+1 downto 1) & not v_coef(0);
          
                    end if;

                    s_count                 := s_count + 1;
                    s_count1                := s_count1 + 1;
                    v_stage_iteration_count := v_stage_iteration_count - 1;

                    if (v_stage_iteration_count = 0) then

                        v_stage_iteration_count := SHR(N, "10");                      --Re-initialize the stage iteration count after completing each stage
                        s_count                 := (others => '0');                   --Re-initialize the address counter
                                                               
                    end if;
                    
                    v_addr_gen_freq := 1;
          
                else

                    v_addr_gen_freq := v_addr_gen_freq - 1;
          
                end if;

            else

                a_read_data       <= (others => '0');
                a_store_add       <= (others => '0');
                a_store_sub       <= (others => '0');
                a_Coef0Addr       <= (others => '0');
                a_Coef1Addr       <= (others => '0');
                a_done            <= '0';
                s_addr_gen_on     <= '0';
                s_stage_counter   := 0;
            
            end if;
            
        end if;
        
      end if;
    
  end process CLK_PROCESS;

end addr_gen_unit_arch;
