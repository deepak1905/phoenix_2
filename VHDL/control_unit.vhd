-------------------------------------------------------------------------------
-- Title      : Control unit module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : control_unit.vhd
-- Author     : Deepak Revanna  <deepak.revanna@tut.fi>
-- Co-Author  : Manuele Cucchi  <manuele.cucchi@studio.unibo.it>
-- Company    : Tampere University of Technology
-- Last update: 2012/12/05
-- Platform   : Altera stratix II FPGA
-------------------------------------------------------------------------------
-- Description: Control unit generates the control signal required to carry
--              the FFT computations for different values of N(number of FFT
--              points.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/07/016  1.0      revanna	Created
-------------------------------------------------------------------------------

--Include the standard library
--packages
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity control_unit is

  generic (
    N_width                 : integer := 7);                              --By default 64 point FFT is supported.
  
  port (
    clk                     : in  std_logic;                              --Clock input
    rst                     : in  std_logic;                              --Reset signal
    c_start                 : in  std_logic;                              --Enables start of FFT computation
    N                       : in  std_logic_vector (N_width-1 downto 0);  --Number of FFT points
    c_begin_stage           : out std_logic;                              --Indicate the begining of each stage
    c_input_flip            : out std_logic;                              --Indicate whether inputs to butterfly have to be flipped or not in a stage
    c_add_sub               : out std_logic;                              --Add/subtract butterfly control signal
    c_load                  : out std_logic;                              --Multiplication result register load of complex multiplier
    c_load1                 : out std_logic;                              --Add-subtract result register load of complex multiplier
    c_load_P                : out std_logic;                              --Load P register input - control signal
    c_load_P2               : out std_logic;                              --Load P2(next P) reg input - control signal
    c_load_Q                : out std_logic;                              --Load Q register input - control signal
    c_load_W                : out std_logic;                              --Load W register input - control signal
    c_sel                   : out std_logic;                              --Select PR, PI mux control signal
    c_SetA_RW               : out std_logic;                              --Interconnect A RW signal('0' - read, '1' - write)
    c_SetB_RW               : out std_logic;                              --Interconnect B RW signal('0' - read, '1' - write)
    c_SetA_EN               : out std_logic;                              --Memory set A read enable signal
    c_SetB_EN               : out std_logic;                              --Memory set B read enable signal
    c_last_stage            : out std_logic;                              --0 indicates its not a last stage, 1 indicates the last stage
    c_bfy0_ip0_reg_load     : out std_logic;                              --Butterfly unit0 input0 register load
    c_bfy0_ip1_reg_load     : out std_logic;                              --Butterfly unit0 input1 register load
    c_bfy0_mux_sel          : out std_logic;                              --Butterfly unit0 input(Q/P) sel
    c_bfy0_tw_reg_load      : out std_logic;                              --Butterfly unit0 twiddle factor reg load
    c_bfy0_tw_sel           : out std_logic;                              --Butterfly unit0 twiddle factor sel(WR/WI)
    c_bfy0_add_op_reg_load  : out std_logic;                              --Butterfly unit0 addition output result load
    c_bfy0_sub_op_reg_load  : out std_logic;                              --Butterfly unit0 subtraction output result load
    c_bfy0_tw_addr_reg_load : out std_logic;                              --Butterfly unit0 twiddle factor address load register
    c_bfy1_ip0_reg_load     : out std_logic;                              --Butterfly unit1 input0 register load
    c_bfy1_ip1_reg_load     : out std_logic;                              --Butterfly unit1 input1 register load
    c_bfy1_mux_sel          : out std_logic;                              --Butterfly unit1 input(Q/P) sel
    c_bfy1_tw_reg_load      : out std_logic;                              --Butterfly unit1 twiddle factor reg load
    c_bfy1_tw_sel           : out std_logic;                              --Butterfly unit1 twiddle factor sel(WR/WI)
    c_bfy1_add_op_reg_load  : out std_logic;                              --Butterfly unit1 addition output result load
    c_bfy1_sub_op_reg_load  : out std_logic;                              --Butterfly unit1 subtraction output result load
    c_bfy1_tw_addr_reg_load : out std_logic;                              --Butterfly unit1 twiddle factor address load register
    c_done                  : out std_logic);                             --Indicates completion of FFT computation
  
end control_unit;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


architecture control_unit_arch of control_unit is

  type state_type is (S0, S1, S2, S3);                                                  --States required in the Moore state machine
  signal current_state       : state_type                           := S0;              --State variable initialized to the reset state
  signal next_state          : state_type                           := S0;              --Next state variable
  signal last_state          : state_type                           := S0;
  signal s_last_stage        : boolean                              := false;           --Indicate the last stage
  signal s_input_flip        : std_logic                            := '0';             --Indicate input flip required or not
  signal s_store_flip_enable : std_logic_vector(N_width-1 downto 0) := (others => '0'); --Flip enable counter value
  signal begin_period        : integer                              := 0;               --Period between two begining of two stages
  constant WRITE_SET_UP_TIME : integer                              := 9;               --Clock cycles required to start write operation after the stage begins
                                                                                        --(4 cycles for data arrival at buttefly input +
                                                                                        -- 3 cycles to fill up the pipeline +
                                                                                        -- 2 cycles for data to arrive at the RAM for storage)

begin  -- control_unit_arch
  STATE_MACHINE: process(clk, rst)

    variable stage_iteration_count : std_logic_vector(N_width - 1 downto 0);                     --N/4 is the number of iterations per stage with two butterfly units
    variable stage_count           : std_logic_vector(N_width - 1 downto 0)  := (others =>'0');  --Keeping count of FFT computation stage, its same size as that of N
    variable cycle_clock_instance  : integer range -2 to 9                   := 0;               --Clock cycle instance during piplined execution in butterfly
    variable enable_count          : std_logic_vector(N_width-1 downto 0)    := (others => '0'); --Counter to control the setA and setB enable signals
    variable v_flip_count          : std_logic_vector(N_width-1 downto 0)    := (others => '0'); --Flip control variables
    variable s_flip_count          : std_logic_vector(N_width-1 downto 0)    := (others => '0');
    variable s_flip_enable_count   : std_logic_vector(N_width-1 downto 0)    := (others => '0');

    begin

      if rst = '0' then

          c_done                  <= '0';
          c_begin_stage           <= '0';
          c_input_flip            <= '0';
          c_SetA_RW               <= '0';
          c_SetB_RW               <= '0';
          c_SetA_EN               <= '0';
          c_SetB_EN               <= '0';
          c_last_stage            <= '0';
          c_add_sub               <= '0';
          c_load                  <= '0';
          c_load1                 <= '0';
          c_load_P                <= '0';
          c_load_P2               <= '0';
          c_load_Q                <= '0';
          c_load_W                <= '0';
          c_sel                   <= '0';
          c_bfy0_ip0_reg_load     <= '0';
          c_bfy0_ip1_reg_load     <= '0';
          c_bfy0_mux_sel          <= '0';
          c_bfy0_tw_reg_load      <= '0';
          c_bfy0_tw_sel           <= '0';
          c_bfy0_add_op_reg_load  <= '0';
          c_bfy0_sub_op_reg_load  <= '0';
          c_bfy0_tw_addr_reg_load <= '0';
          c_bfy1_ip0_reg_load     <= '0';
          c_bfy1_ip1_reg_load     <= '0';
          c_bfy1_mux_sel          <= '0';
          c_bfy1_tw_reg_load      <= '0';
          c_bfy1_tw_sel           <= '0';
          c_bfy1_add_op_reg_load  <= '0';
          c_bfy1_sub_op_reg_load  <= '0';
          c_bfy1_tw_addr_reg_load <= '0';

        
          current_state <= S0; --After reset begin with the initial state
          next_state    <= S0;
        
          --Shifting right by 1 positions makes it N/2 which is number of clock cycles
          --required per FFT stage(because butterfly reads new sample every 2
          --clock cycles). Each stage takes N/2+9 to complete.
          stage_iteration_count := SHR(N, "01") + "1001";
          stage_count           := stage_count(N_width-1 downto 1) & '1';
          cycle_clock_instance  := 0;
          v_flip_count          := N;
          s_flip_count          := N;
          s_flip_enable_count   := (others => '0');

      elsif clk'event and clk = '1' then
        
          if N > 8 then  --Supports only 16 or greater FFT points computation
          
              case current_state is
          
                  when  S0 =>

                      last_state <= S0;
            
                      if (stage_count /= N and c_start = '1') then  --Start the computation only after start=1
              
                          next_state              <= S1;  --Initialize the variables and signals required for control signal timing
                          c_SetA_EN               <= '1';
                          c_SetB_EN               <= '0';
                          c_begin_stage           <= '1';
                          s_flip_count            := SHR(s_flip_count, "1")+"1";
                          s_input_flip            <= '0';
                          v_flip_count            := s_flip_count;
                          s_flip_enable_count(0)  := '1';
                          s_store_flip_enable(0)  <= '1';
                          stage_iteration_count   := SHR(N, "01") + "1001";  --Number of clock cycles per stage(N/2+9)
                          enable_count            := (others => '0');  --Control RAM enable signal through count value
                          begin_period            <= conv_integer(unsigned(stage_iteration_count));
               
                      else
                
                          next_state              <= S0;  --Reset the control signals
                          c_begin_stage           <= '0';
                          c_SetA_RW               <= '0';
                          c_SetB_RW               <= '0';
                          c_SetA_EN               <= '0';
                          c_SetB_EN               <= '0';                
                          c_done                  <= '0';
                          c_last_stage            <= '0';
                          c_add_sub               <= '0';
                          c_load                  <= '0';
                          c_load1                 <= '0';
                          c_load_P                <= '0';
                          c_load_P2               <= '0';
                          c_load_Q                <= '0';
                          c_load_W                <= '0';
                          c_sel                   <= '0';
                          c_bfy0_ip0_reg_load     <= '0';
                          c_bfy0_ip1_reg_load     <= '0';
                          c_bfy0_mux_sel          <= '0';
                          c_bfy0_tw_reg_load      <= '0';
                          c_bfy0_tw_sel           <= '0';
                          c_bfy0_add_op_reg_load  <= '0';
                          c_bfy0_sub_op_reg_load  <= '0';
                          c_bfy0_tw_addr_reg_load <= '0';
                          c_bfy1_ip0_reg_load     <= '0';
                          c_bfy1_ip1_reg_load     <= '0';
                          c_bfy1_mux_sel          <= '0';
                          c_bfy1_tw_reg_load      <= '0';
                          c_bfy1_tw_sel           <= '0';
                          c_bfy1_add_op_reg_load  <= '0';
                          c_bfy1_sub_op_reg_load  <= '0';
                          c_bfy1_tw_addr_reg_load <= '0';
                
                      end if;
           

            
                when S1 =>

                    last_state            <= S1;
                    stage_iteration_count := stage_iteration_count - 1;  --Decrease iteration count by 1 every clock cycle
                    c_begin_stage         <= '0';
                    c_SetA_RW             <= '0';  --In state S1 read inputs from RAM set A and write into RAM set B
                    c_SetB_RW             <= '1';
                    c_done                <= '0';

                    if enable_count < (begin_period - WRITE_SET_UP_TIME) then --Read from set A RAM from the beginning till N/2 cycles

                        c_SetA_EN <= '1';
                
                    else
                
                        c_SetA_EN <= '0';
                        
                    end if;

                    if enable_count < (WRITE_SET_UP_TIME-1) then  --Start writing to set B RAM after 8 cycles from the beginning of the stage

                        c_SetB_EN <= '0';
                
                    else

                        c_SetB_EN <= '1';
                
                    end if;

                    enable_count := enable_count + 1;

                    if s_last_stage = false then  --No input data flip in the first and last stage, for all other stages flip required

                        if s_input_flip = '0' then

                            if (v_flip_count = "0" and s_flip_enable_count /= "0") then

                                s_input_flip        <= not s_input_flip;
                                v_flip_count        := s_flip_count;
                                s_flip_enable_count := s_flip_enable_count-1;

                                if s_flip_enable_count = "0" then

                                    s_input_flip <= '0';
                                    
                                end if;
                                
                            end if;
                            
                        else
                
                            if (v_flip_count = "1" and s_flip_enable_count /= "0") then

                                s_input_flip        <= not s_input_flip;
                                v_flip_count        := s_flip_count-"1";
                                s_flip_enable_count := s_flip_enable_count-1;

                                if s_flip_enable_count = "0" then

                                    s_input_flip <= '0';
                  
                                end if;

                            end if;
                
                        end if;

                        v_flip_count := v_flip_count-1;

                        if s_flip_enable_count = "0" then
                
                            s_input_flip <= '0';
                
                        end if;
              
                    end if;              
            
                    if stage_iteration_count = 0 then  --End of stage when iteration count is zero

                        stage_count             := SHL(stage_count, "1");  --Current stage is complete, go to next stage
                        stage_iteration_count   := SHR(N, "01") + "1001";  --Initialize the iteration count for the next stage
                        cycle_clock_instance    := 0;
                        enable_count            := (others => '0');                

                        next_state              <= S2;  --Move to the next state for the next stage

                        c_add_sub               <= '0';
                        c_load                  <= '0';
                        c_load1                 <= '0';
                        c_load_P                <= '0';
                        c_load_P2               <= '0';
                        c_load_Q                <= '0';
                        c_load_W                <= '0';
                        c_sel                   <= '0';
                  
                        c_bfy0_ip0_reg_load     <= '0';
                        c_bfy0_ip1_reg_load     <= '0';
                        c_bfy0_mux_sel          <= '0';
                        c_bfy0_tw_reg_load      <= '0';
                        c_bfy0_tw_sel           <= '0';
                        c_bfy0_add_op_reg_load  <= '0';
                        c_bfy0_sub_op_reg_load  <= '0';
                        c_bfy0_tw_addr_reg_load <= '0';
                  
                        c_bfy1_ip0_reg_load     <= '0';
                        c_bfy1_ip1_reg_load     <= '0';
                        c_bfy1_mux_sel          <= '0';
                        c_bfy1_tw_reg_load      <= '0';
                        c_bfy1_tw_sel           <= '0';
                        c_bfy1_add_op_reg_load  <= '0';
                        c_bfy1_sub_op_reg_load  <= '0';
                        c_bfy1_tw_addr_reg_load <= '0';                  

                    elsif (stage_iteration_count = "10") then

                        cycle_clock_instance := 8;
                
                    else

                        next_state <= S1;  --Stay in the same state and continue with iterations

                    end if;

                    --After the stage begins, it takes 4 cycles for the data to reach
                    --the buttefly input. It takes 3 cycles to fill up the butterfly
                    --pipeline and hence after 7 cycles are first output is available
                    --at the butterfly output.And after 9 cycles from the beginning of
                    --the stage writing to set B RAM starts
                    case cycle_clock_instance is
                      
                        when 0 =>
                            c_add_sub               <= '0';
                            c_load                  <= '0';
                            c_load1                 <= '0';
                            c_load_P                <= '0';
                            c_load_P2               <= '0';
                            c_load_Q                <= '0';
                            c_load_W                <= '0';
                            c_sel                   <= '0';
                  
                            c_bfy0_ip0_reg_load     <= '0';
                            c_bfy0_ip1_reg_load     <= '0';
                            c_bfy0_mux_sel          <= '0';
                            c_bfy0_tw_reg_load      <= '0';
                            c_bfy0_tw_sel           <= '0';
                            c_bfy0_add_op_reg_load  <= '0';
                            c_bfy0_sub_op_reg_load  <= '0';
                            c_bfy0_tw_addr_reg_load <= '1';
                  
                            c_bfy1_ip0_reg_load     <= '0';
                            c_bfy1_ip1_reg_load     <= '0';
                            c_bfy1_mux_sel          <= '0';
                            c_bfy1_tw_reg_load      <= '0';
                            c_bfy1_tw_sel           <= '0';
                            c_bfy1_add_op_reg_load  <= '0';
                            c_bfy1_sub_op_reg_load  <= '0';
                            c_bfy1_tw_addr_reg_load <= '1';
                  
                            cycle_clock_instance    := 1;
                
                        when 1 =>
                            c_add_sub               <= '0';
                            c_load                  <= '0';
                            c_load1                 <= '0';
                            c_load_P                <= '0';
                            c_load_P2               <= '0';
                            c_load_Q                <= '0';
                            c_load_W                <= '0';
                            c_sel                   <= '0';
                  
                            c_bfy0_ip0_reg_load     <= '0';
                            c_bfy0_ip1_reg_load     <= '0';
                            c_bfy0_mux_sel          <= '0';
                            c_bfy0_tw_reg_load      <= '0';
                            c_bfy0_tw_sel           <= '0';
                            c_bfy0_add_op_reg_load  <= '0';
                            c_bfy0_sub_op_reg_load  <= '0';
                            c_bfy0_tw_addr_reg_load <= '0';
                  
                  
                            c_bfy1_ip0_reg_load     <= '0';
                            c_bfy1_ip1_reg_load     <= '0';
                            c_bfy1_mux_sel          <= '0';
                            c_bfy1_tw_reg_load      <= '0';
                            c_bfy1_tw_sel           <= '0';
                            c_bfy1_add_op_reg_load  <= '0';
                            c_bfy1_sub_op_reg_load  <= '0';
                            c_bfy1_tw_addr_reg_load <= '0';
                  
                            cycle_clock_instance    := 2;

                        when 2 =>
                            c_add_sub               <= '0';
                            c_load                  <= '0';
                            c_load1                 <= '0';
                            c_load_P                <= '0';
          
                            c_load_P2               <= '0';
                            c_load_Q                <= '0';
                            c_load_W                <= '0';
                            c_sel                   <= '0';
                  
                            c_bfy0_ip0_reg_load     <= '0';
                            c_bfy0_ip1_reg_load     <= '0';
                            c_bfy0_mux_sel          <= '0';
                            c_bfy0_tw_reg_load      <= '0';
                            c_bfy0_tw_sel           <= '0';
                            c_bfy0_add_op_reg_load  <= '0';
                            c_bfy0_sub_op_reg_load  <= '0';
                            c_bfy0_tw_addr_reg_load <= '1';
                  
                            c_bfy1_ip0_reg_load     <= '0';
                            c_bfy1_ip1_reg_load     <= '0';
                            c_bfy1_mux_sel          <= '0';
                            c_bfy1_tw_reg_load      <= '0';
                            c_bfy1_tw_sel           <= '0';
                            c_bfy1_add_op_reg_load  <= '0';
                            c_bfy1_sub_op_reg_load  <= '0';
                            c_bfy1_tw_addr_reg_load <= '1';
                  
                            cycle_clock_instance    := 3;                  

                        when 3 =>
                          c_add_sub               <= '0';
                          c_load                  <= '0';
                          c_load1                 <= '0';
                          c_load_P                <= '0';
                          c_load_P2               <= '0';
                          c_load_Q                <= '0';
                          c_load_W                <= '0';
                          c_sel                   <= '0';
                  
                          c_bfy0_ip0_reg_load     <= '1';
                          c_bfy0_ip1_reg_load     <= '1';
                          c_bfy0_mux_sel          <= '0';
                          c_bfy0_tw_reg_load      <= '1';
                          c_bfy0_tw_sel           <= '0';
                          c_bfy0_add_op_reg_load  <= '0';
                          c_bfy0_sub_op_reg_load  <= '0';
                          c_bfy0_tw_addr_reg_load <= '0';
                  
                          c_bfy1_ip0_reg_load     <= '1';
                          c_bfy1_ip1_reg_load     <= '1';
                          c_bfy1_mux_sel          <= '0';
                          c_bfy1_tw_reg_load      <= '1';
                          c_bfy1_tw_sel           <= '0';
                          c_bfy1_add_op_reg_load  <= '0';
                          c_bfy1_sub_op_reg_load  <= '0';
                          c_bfy1_tw_addr_reg_load <= '0';
                  
                          cycle_clock_instance    := 4;

                      when 4 =>
                          c_add_sub               <= '1';
                          c_load                  <= '0';
                          c_load1                 <= '1';
                          c_load_P                <= '0';
                          c_load_P2               <= '0';
                          c_load_Q                <= '1';
                          c_load_W                <= '1';
                          c_sel                   <= '0';
                  
                          c_bfy0_ip0_reg_load     <= '0';
                          c_bfy0_ip1_reg_load     <= '0';
                          c_bfy0_mux_sel          <= '1';
                          c_bfy0_tw_reg_load      <= '0';
                          c_bfy0_tw_sel           <= '1';
                          c_bfy0_add_op_reg_load  <= '1';
                          c_bfy0_sub_op_reg_load  <= '0';
                          c_bfy0_tw_addr_reg_load <= '1';
                  
                          c_bfy1_ip0_reg_load     <= '0';
                          c_bfy1_ip1_reg_load     <= '0';
                          c_bfy1_mux_sel          <= '1';
                          c_bfy1_tw_reg_load      <= '0';
                          c_bfy1_tw_sel           <= '1';
                          c_bfy1_add_op_reg_load  <= '1';

                          c_bfy1_sub_op_reg_load  <= '0';
                          c_bfy1_tw_addr_reg_load <= '1';
                  
                          cycle_clock_instance    := 5;
                  
                      when 5 =>
                          c_add_sub               <= '0';
                          c_load                  <= '1';
                          c_load1                 <= '0';

                          c_load_P                <= '1';
                          c_load_P2               <= '0';
                          c_load_Q                <= '0';
                          c_load_W                <= '1';
                          c_sel                   <= '1';
                  
                          c_bfy0_ip0_reg_load     <= '1';
                          c_bfy0_ip1_reg_load     <= '1';
                          c_bfy0_mux_sel          <= '0';
                          c_bfy0_tw_reg_load      <= '1';
                          c_bfy0_tw_sel           <= '0';
                          c_bfy0_add_op_reg_load  <= '0';
                          c_bfy0_sub_op_reg_load  <= '1';
                          c_bfy0_tw_addr_reg_load <= '0';
                  
                          c_bfy1_ip0_reg_load     <= '1';
                          c_bfy1_ip1_reg_load     <= '1';
                          c_bfy1_mux_sel          <= '0';
                          c_bfy1_tw_reg_load      <= '1';
                          c_bfy1_tw_sel           <= '0';
                          c_bfy1_add_op_reg_load  <= '0';
                          c_bfy1_sub_op_reg_load  <= '1';
                          c_bfy1_tw_addr_reg_load <= '0';
                  
                          cycle_clock_instance    := 6;
                  
                      when 6 =>
                          c_add_sub               <= '1';
                          c_load                  <= '0';
                          c_load1                 <= '1';
                          c_load_P                <= '0';
                          c_load_P2               <= '0';
                          c_load_Q                <= '1';
                          c_load_W                <= '1';
                          c_sel                   <= '1';
                  
                          c_bfy0_ip0_reg_load     <= '0';
                          c_bfy0_ip1_reg_load     <= '0';
                          c_bfy0_mux_sel          <= '1';
                          c_bfy0_tw_reg_load      <= '0';
                          c_bfy0_tw_sel           <= '1';
                          c_bfy0_add_op_reg_load  <= '1';
                          c_bfy0_sub_op_reg_load  <= '0';
                          c_bfy0_tw_addr_reg_load <= '1';
                  
                          c_bfy1_ip0_reg_load     <= '0';
                          c_bfy1_ip1_reg_load     <= '0';
                          c_bfy1_mux_sel          <= '1';
                          c_bfy1_tw_reg_load      <= '0';
                          c_bfy1_tw_sel           <= '1';
                          c_bfy1_add_op_reg_load  <= '1';
                          c_bfy1_sub_op_reg_load  <= '0';
                          c_bfy1_tw_addr_reg_load <= '1';
                  
                          cycle_clock_instance    := 7;
                  
                      when 7 =>
                          c_add_sub               <= '0';
                          c_load                  <= '1';
                          c_load1                 <= '0';
                          c_load_P                <= '0';
                          c_load_P2               <= '1';
                          c_load_Q                <= '0';
                          c_load_W                <= '1';
                          c_sel                   <= '0';
                  
                          c_bfy0_ip0_reg_load     <= '1';
                          c_bfy0_ip1_reg_load     <= '1';
                          c_bfy0_mux_sel          <= '0';
                          c_bfy0_tw_reg_load      <= '1';
                          c_bfy0_tw_sel           <= '0';
                          c_bfy0_add_op_reg_load  <= '0';
                          c_bfy0_sub_op_reg_load  <= '1';
                          c_bfy0_tw_addr_reg_load <= '0';
                  
                          c_bfy1_ip0_reg_load     <= '1';
                          c_bfy1_ip1_reg_load     <= '1';
                          c_bfy1_mux_sel          <= '0';
                          c_bfy1_tw_reg_load      <= '1';
                          c_bfy1_tw_sel           <= '0';
                          c_bfy1_add_op_reg_load  <= '0';
                          c_bfy1_sub_op_reg_load  <= '1';
                          c_bfy1_tw_addr_reg_load <= '0';
                  
                          cycle_clock_instance    := 4;

                      when 8 =>
                          c_add_sub               <= '1';
                          c_load                  <= '0';
                          c_load1                 <= '0';
                          c_load_P                <= '0';
                          c_load_P2               <= '0';
                          c_load_Q                <= '0';
                          c_load_W                <= '1';
                          c_sel                   <= '1';
                  
                          c_bfy0_ip0_reg_load     <= '0';
                          c_bfy0_ip1_reg_load     <= '0';
                          c_bfy0_mux_sel          <= '0';
                          c_bfy0_tw_reg_load      <= '0';
                          c_bfy0_tw_sel           <= '0';
                          c_bfy0_add_op_reg_load  <= '1';
                          c_bfy0_sub_op_reg_load  <= '0';
                          c_bfy0_tw_addr_reg_load <= '0';
                  
                          c_bfy1_ip0_reg_load     <= '0';
                          c_bfy1_ip1_reg_load     <= '0';
                          c_bfy1_mux_sel          <= '0';
                          c_bfy1_tw_reg_load      <= '0';
                          c_bfy1_tw_sel           <= '0';
                          c_bfy1_add_op_reg_load  <= '1';
                          c_bfy1_sub_op_reg_load  <= '0';
                          c_bfy1_tw_addr_reg_load <= '0';
                  
                          cycle_clock_instance    := 9;

                      when 9 =>
                          c_add_sub               <= '0';
                          c_load                  <= '0';
                          c_load1                 <= '0';
                          c_load_P                <= '0';
                          c_load_P2               <= '0';
                          c_load_Q                <= '0';
                          c_load_W                <= '0';
                          c_sel                   <= '0';
                  
                          c_bfy0_ip0_reg_load     <= '0';
                          c_bfy0_ip1_reg_load     <= '0';
                          c_bfy0_mux_sel          <= '0';
                          c_bfy0_tw_reg_load      <= '0';
                          c_bfy0_tw_sel           <= '0';
                          c_bfy0_add_op_reg_load  <= '0';
                          c_bfy0_sub_op_reg_load  <= '1';
                          c_bfy0_tw_addr_reg_load <= '0';
                  
                          c_bfy1_ip0_reg_load     <= '0';
                          c_bfy1_ip1_reg_load     <= '0';
                          c_bfy1_mux_sel          <= '0';
                          c_bfy1_tw_reg_load      <= '0';
                          c_bfy1_tw_sel           <= '0';
                          c_bfy1_add_op_reg_load  <= '0';
                          c_bfy1_sub_op_reg_load  <= '1';
                          c_bfy1_tw_addr_reg_load <= '0';
                  
                          cycle_clock_instance    := 0;

                      when others => null;
                  end case;



              when S2 =>  --Transition state between state S1, S3, S0

                  c_begin_stage <= '1';

                  s_flip_count            := SHR(s_flip_count, "1")+"1";  --Initialize values required for input flip control
                  s_flip_enable_count     := SHL(s_store_flip_enable, "1");
                  s_store_flip_enable     <= SHL(s_store_flip_enable, "1");
                  s_input_flip            <= '0';
                  v_flip_count            := s_flip_count;               

                  if last_state = S1 then  --Set the enable signals for read-write operation

                      next_state <= S3;
                      c_SetA_EN  <= '0';
                      c_SetB_EN  <= '1';                 

                  else

                      next_state <= S1;
                      c_SetA_EN  <= '1';
                      c_SetB_EN  <= '0';
                   
                end if;

                if stage_count = N then  --After the last stage return to S0 and reset the begin stage signal
                  
                    next_state    <= S0;
                    c_begin_stage <= '0';
                  
                end if;

                if stage_count = SHR(N, "1") then  --Set the last stage signal to true when the stage count is N
                  
                    c_last_stage <= '1';
                    s_last_stage <= true;
                  
                else
                  
                    c_last_stage <= '0';
                    s_last_stage <= false;
                  
                end if;
              
               last_state           <= S2;
               cycle_clock_instance := 0;



          when S3 =>

              last_state <= S3;
               
              stage_iteration_count := stage_iteration_count - 1;  --Decrease iteration count by 1 every clock cycle
              c_begin_stage         <= '0';
              c_SetA_RW             <= '1'; --Read from set B RAM and write into set A RAM
              c_SetB_RW             <= '0';
              c_done                <= '0';

              if enable_count < (begin_period - WRITE_SET_UP_TIME) then --Read from set B RAM from the beginning till N/2 cycles

                  c_SetB_EN <= '1';
                
              else
                
                  c_SetB_EN <= '0';
                
              end if;

              if enable_count < (WRITE_SET_UP_TIME-1) then --Start writing to set A RAM after 8 cycles from the beginning of the stage

                  c_SetA_EN <= '0';
                
              else

                  c_SetA_EN <= '1';
                
              end if;                 

              enable_count := enable_count + 1;

              if s_last_stage = false then --No input data flip in the first and last stage, for all other stages flip required
                
                  if s_input_flip = '0' then

                      if (v_flip_count = "0" and s_flip_enable_count /= "0") then

                          s_input_flip        <= not s_input_flip;
                          v_flip_count        := s_flip_count;
                          s_flip_enable_count := s_flip_enable_count-1;

                          if s_flip_enable_count = "0" then

                              s_input_flip <= '0';
                  
                          end if;

                      end if;                

                  else
                
                      if (v_flip_count = "1" and s_flip_enable_count /= "0") then

                          s_input_flip        <= not s_input_flip;
                          v_flip_count        := s_flip_count-"1";
                          s_flip_enable_count := s_flip_enable_count-1;

                          if s_flip_enable_count = "0" then

                              s_input_flip <= '0';
                  
                          end if;

                      end if;
                
                  end if;                 

                  v_flip_count := v_flip_count-1;

                  if s_flip_enable_count = "0" then

                      s_input_flip <= '0';
                  
                  end if;
                 
              end if;                 
                 
            
              if stage_iteration_count = 0 then  --End of stage when iteration count is zero

                  stage_count             := SHL(stage_count, "1");  --Current stage is complete, go to next stage
                  stage_iteration_count   := SHR(N, "01") + "1001";  --Initialize the iteration count for the next stage
                  cycle_clock_instance    := 0;
                  enable_count            := (others => '0');

                  next_state              <= S2;  --Move to the next state for the next stage

                  c_add_sub               <= '0';
                  c_load                  <= '0';
                  c_load1                 <= '0';
                  c_load_P                <= '0';
                  c_load_P2               <= '0';
                  c_load_Q                <= '0';
                  c_load_W                <= '0';
                  c_sel                   <= '0';
                  
                  c_bfy0_ip0_reg_load     <= '0';
                  c_bfy0_ip1_reg_load     <= '0';
                  c_bfy0_mux_sel          <= '0';
                  c_bfy0_tw_reg_load      <= '0';
                  c_bfy0_tw_sel           <= '0';
                  c_bfy0_add_op_reg_load  <= '0';
                  c_bfy0_sub_op_reg_load  <= '0';
                  c_bfy0_tw_addr_reg_load <= '0';
                  
                  
                  c_bfy1_ip0_reg_load     <= '0';
                  c_bfy1_ip1_reg_load     <= '0';
                  c_bfy1_mux_sel          <= '0';
                  c_bfy1_tw_reg_load      <= '0';
                  c_bfy1_tw_sel           <= '0';
                  c_bfy1_add_op_reg_load  <= '0';
                  c_bfy1_sub_op_reg_load  <= '0';
                  c_bfy1_tw_addr_reg_load <= '0';                  
                  

              elsif (stage_iteration_count = "10") then

                  cycle_clock_instance := 8;
                
              else

                  next_state <= S3;  --Stay in the same state and continue with iterations

              end if;


              --After the stage begins, it takes 4 cycles for the data to reach
              --the buttefly input. It takes 3 cycles to fill up the butterfly
              --pipeline and hence after 7 cycles are first output is available
              --at the butterfly output.And after 9 cycles from the beginning of
              --the stage writing to set B RAM starts
              case cycle_clock_instance is
                  when 0 =>
                      c_add_sub               <= '0';
                      c_load                  <= '0';
                      c_load1                 <= '0';
                      c_load_P                <= '0';
                      c_load_P2               <= '0';
                      c_load_Q                <= '0';
                      c_load_W                <= '0';
                      c_sel                   <= '0';
                  
                      c_bfy0_ip0_reg_load     <= '0';
                      c_bfy0_ip1_reg_load     <= '0';
                      c_bfy0_mux_sel          <= '0';
                      c_bfy0_tw_reg_load      <= '0';
                      c_bfy0_tw_sel           <= '0';
                      c_bfy0_add_op_reg_load  <= '0';
                      c_bfy0_sub_op_reg_load  <= '0';
                      c_bfy0_tw_addr_reg_load <= '1';
                  
                      c_bfy1_ip0_reg_load     <= '0';
                      c_bfy1_ip1_reg_load     <= '0';
                      c_bfy1_mux_sel          <= '0';
                      c_bfy1_tw_reg_load      <= '0';
                      c_bfy1_tw_sel           <= '0';
                      c_bfy1_add_op_reg_load  <= '0';
                      c_bfy1_sub_op_reg_load  <= '0';
                      c_bfy1_tw_addr_reg_load <= '1';
                  
                      cycle_clock_instance    := 1;
                
                  when 1 =>
                      c_add_sub               <= '0';
                      c_load                  <= '0';
                      c_load1                 <= '0';
                      c_load_P                <= '0';
                      c_load_P2               <= '0';
                      c_load_Q                <= '0';
                      c_load_W                <= '0';
                      c_sel                   <= '0';
                  
                      c_bfy0_ip0_reg_load     <= '0';
                      c_bfy0_ip1_reg_load     <= '0';
                      c_bfy0_mux_sel          <= '0';
                      c_bfy0_tw_reg_load      <= '0';
                      c_bfy0_tw_sel           <= '0';
                      c_bfy0_add_op_reg_load  <= '0';
                      c_bfy0_sub_op_reg_load  <= '0';
                      c_bfy0_tw_addr_reg_load <= '0';
                  
                      c_bfy1_ip0_reg_load     <= '0';
                      c_bfy1_ip1_reg_load     <= '0';
                      c_bfy1_mux_sel          <= '0';
                      c_bfy1_tw_reg_load      <= '0';
                      c_bfy1_tw_sel           <= '0';
                      c_bfy1_add_op_reg_load  <= '0';
                      c_bfy1_sub_op_reg_load  <= '0';
                      c_bfy1_tw_addr_reg_load <= '0';
                  
                      cycle_clock_instance    := 2;

                  when 2 =>
                      c_add_sub               <= '0';
                      c_load                  <= '0';
                      c_load1                 <= '0';
                      c_load_P                <= '0';
          
                      c_load_P2               <= '0';
                      c_load_Q                <= '0';
                      c_load_W                <= '0';
                      c_sel                   <= '0';
                  
                      c_bfy0_ip0_reg_load     <= '0';
                      c_bfy0_ip1_reg_load     <= '0';
                      c_bfy0_mux_sel          <= '0';
                      c_bfy0_tw_reg_load      <= '0';
                      c_bfy0_tw_sel           <= '0';
                      c_bfy0_add_op_reg_load  <= '0';
                      c_bfy0_sub_op_reg_load  <= '0';
                      c_bfy0_tw_addr_reg_load <= '1';
                  
                      c_bfy1_ip0_reg_load     <= '0';
                      c_bfy1_ip1_reg_load     <= '0';
                      c_bfy1_mux_sel          <= '0';
                      c_bfy1_tw_reg_load      <= '0';
                      c_bfy1_tw_sel           <= '0';
                      c_bfy1_add_op_reg_load  <= '0';
                      c_bfy1_sub_op_reg_load  <= '0';
                      c_bfy1_tw_addr_reg_load <= '1';
                  
                      cycle_clock_instance    := 3;                  

                  when 3 =>
                      c_add_sub               <= '0';
                      c_load                  <= '0';
                      c_load1                 <= '0';
                      c_load_P                <= '0';
                      c_load_P2               <= '0';
                      c_load_Q                <= '0';
                      c_load_W                <= '0';
                      c_sel                   <= '0';
                  
                      c_bfy0_ip0_reg_load     <= '1';
                      c_bfy0_ip1_reg_load     <= '1';
                      c_bfy0_mux_sel          <= '0';
                      c_bfy0_tw_reg_load      <= '1';
                      c_bfy0_tw_sel           <= '0';
                      c_bfy0_add_op_reg_load  <= '0';
                      c_bfy0_sub_op_reg_load  <= '0';
                      c_bfy0_tw_addr_reg_load <= '0';
                  
                      c_bfy1_ip0_reg_load     <= '1';
                      c_bfy1_ip1_reg_load     <= '1';
                      c_bfy1_mux_sel          <= '0';
                      c_bfy1_tw_reg_load      <= '1';
                      c_bfy1_tw_sel           <= '0';
                      c_bfy1_add_op_reg_load  <= '0';
                      c_bfy1_sub_op_reg_load  <= '0';
                      c_bfy1_tw_addr_reg_load <= '0';
                  
                      cycle_clock_instance    := 4;

                  when 4 =>
                    c_add_sub               <= '1';
                    c_load                  <= '0';
                    c_load1                 <= '1';
                    c_load_P                <= '0';
                    c_load_P2               <= '0';
                    c_load_Q                <= '1';
                    c_load_W                <= '1';
                    c_sel                   <= '0';
                  
                    c_bfy0_ip0_reg_load     <= '0';
                    c_bfy0_ip1_reg_load     <= '0';
                    c_bfy0_mux_sel          <= '1';
                    c_bfy0_tw_reg_load      <= '0';
                    c_bfy0_tw_sel           <= '1';
                    c_bfy0_add_op_reg_load  <= '1';
                    c_bfy0_sub_op_reg_load  <= '0';
                    c_bfy0_tw_addr_reg_load <= '1';
                  
                    c_bfy1_ip0_reg_load     <= '0';
                    c_bfy1_ip1_reg_load     <= '0';
                    c_bfy1_mux_sel          <= '1';
                    c_bfy1_tw_reg_load      <= '0';
                    c_bfy1_tw_sel           <= '1';
                    c_bfy1_add_op_reg_load  <= '1';

                    c_bfy1_sub_op_reg_load  <= '0';
                    c_bfy1_tw_addr_reg_load <= '1';
                  
                    cycle_clock_instance    := 5;
                  
                when 5 =>
                    c_add_sub               <= '0';
                    c_load                  <= '1';
                    c_load1                 <= '0';

                    c_load_P                <= '1';
                    c_load_P2               <= '0';
                    c_load_Q                <= '0';
                    c_load_W                <= '1';
                    c_sel                   <= '1';
                  
                    c_bfy0_ip0_reg_load     <= '1';
                    c_bfy0_ip1_reg_load     <= '1';
                    c_bfy0_mux_sel          <= '0';
                    c_bfy0_tw_reg_load      <= '1';
                    c_bfy0_tw_sel           <= '0';
                    c_bfy0_add_op_reg_load  <= '0';
                    c_bfy0_sub_op_reg_load  <= '1';
                    c_bfy0_tw_addr_reg_load <= '0';
                  
                    c_bfy1_ip0_reg_load     <= '1';
                    c_bfy1_ip1_reg_load     <= '1';
                    c_bfy1_mux_sel          <= '0';
                    c_bfy1_tw_reg_load      <= '1';
                    c_bfy1_tw_sel           <= '0';
                    c_bfy1_add_op_reg_load  <= '0';
                    c_bfy1_sub_op_reg_load  <= '1';
                    c_bfy1_tw_addr_reg_load <= '0';
                  
                    cycle_clock_instance    := 6;
                  
                when 6 =>
                    c_add_sub               <= '1';
                    c_load                  <= '0';
                    c_load1                 <= '1';
                    c_load_P                <= '0';
                    c_load_P2               <= '0';
                    c_load_Q                <= '1';
                    c_load_W                <= '1';
                    c_sel                   <= '1';
                  
                    c_bfy0_ip0_reg_load     <= '0';
                    c_bfy0_ip1_reg_load     <= '0';
                    c_bfy0_mux_sel          <= '1';
                    c_bfy0_tw_reg_load      <= '0';
                    c_bfy0_tw_sel           <= '1';
 
                    c_bfy0_add_op_reg_load  <= '1';
                    c_bfy0_sub_op_reg_load  <= '0';
                    c_bfy0_tw_addr_reg_load <= '1';
                  
                    c_bfy1_ip0_reg_load     <= '0';
                    c_bfy1_ip1_reg_load     <= '0';
                    c_bfy1_mux_sel          <= '1';
                    c_bfy1_tw_reg_load      <= '0';
                    c_bfy1_tw_sel           <= '1';
                    c_bfy1_add_op_reg_load  <= '1';
                    c_bfy1_sub_op_reg_load  <= '0';
                    c_bfy1_tw_addr_reg_load <= '1';
                  
                    cycle_clock_instance    := 7;
                  
                when 7 =>
                  
                    c_add_sub               <= '0';
                    c_load                  <= '1';
                    c_load1                 <= '0';
                    c_load_P                <= '0';
                    c_load_P2               <= '1';
                    c_load_Q                <= '0';
                    c_load_W                <= '1';
                    c_sel                   <= '0';
                  
                    c_bfy0_ip0_reg_load     <= '1';
                    c_bfy0_ip1_reg_load     <= '1';
                    c_bfy0_mux_sel          <= '0';
                    c_bfy0_tw_reg_load      <= '1';
                    c_bfy0_tw_sel           <= '0';
                    c_bfy0_add_op_reg_load  <= '0';
                    c_bfy0_sub_op_reg_load  <= '1';
                    c_bfy0_tw_addr_reg_load <= '0';
                  
                    c_bfy1_ip0_reg_load     <= '1';
                    c_bfy1_ip1_reg_load     <= '1';
                    c_bfy1_mux_sel          <= '0';
                    c_bfy1_tw_reg_load      <= '1';
                    c_bfy1_tw_sel           <= '0';
                    c_bfy1_add_op_reg_load  <= '0';
                    c_bfy1_sub_op_reg_load  <= '1';
                    c_bfy1_tw_addr_reg_load <= '0';
                  
                    cycle_clock_instance    := 4;
               

                when 8 =>
                    c_add_sub               <= '1';
                    c_load                  <= '0';
                    c_load1                 <= '0';
                    c_load_P                <= '0';
                    c_load_P2               <= '0';
                    c_load_Q                <= '0';
                    c_load_W                <= '1';
                    c_sel                   <= '1';
                  
                    c_bfy0_ip0_reg_load     <= '0';
                    c_bfy0_ip1_reg_load     <= '0';
                    c_bfy0_mux_sel          <= '0';
                    c_bfy0_tw_reg_load      <= '0';
                    c_bfy0_tw_sel           <= '0';
                    c_bfy0_add_op_reg_load  <= '1';
                    c_bfy0_sub_op_reg_load  <= '0';
                    c_bfy0_tw_addr_reg_load <= '0';
                  
                    c_bfy1_ip0_reg_load     <= '0';
                    c_bfy1_ip1_reg_load     <= '0';
                    c_bfy1_mux_sel          <= '0';
                    c_bfy1_tw_reg_load      <= '0';
                    c_bfy1_tw_sel           <= '0';
                    c_bfy1_add_op_reg_load  <= '1';
                    c_bfy1_sub_op_reg_load  <= '0';
                    c_bfy1_tw_addr_reg_load <= '0';
                  
                    cycle_clock_instance    := 9;

                when 9 =>
                    c_add_sub               <= '0';
                    c_load                  <= '0';
                    c_load1                 <= '0';
                    c_load_P                <= '0';
                    c_load_P2               <= '0';
                    c_load_Q                <= '0';
                    c_load_W                <= '0';
                    c_sel                   <= '0';
                  
                    c_bfy0_ip0_reg_load     <= '0';
                    c_bfy0_ip1_reg_load     <= '0';
                    c_bfy0_mux_sel          <= '0';
                    c_bfy0_tw_reg_load      <= '0';
                    c_bfy0_tw_sel           <= '0';
                    c_bfy0_add_op_reg_load  <= '0';
                    c_bfy0_sub_op_reg_load  <= '1';
                    c_bfy0_tw_addr_reg_load <= '0';
                  
                    c_bfy1_ip0_reg_load     <= '0';
                    c_bfy1_ip1_reg_load     <= '0';
                    c_bfy1_mux_sel          <= '0';
                    c_bfy1_tw_reg_load      <= '0';
                    c_bfy1_tw_sel           <= '0';
                    c_bfy1_add_op_reg_load  <= '0';
                    c_bfy1_sub_op_reg_load  <= '1';
                    c_bfy1_tw_addr_reg_load <= '0';
                  
                    cycle_clock_instance    := 0;
                when others => null;
            end case;
            
        when others =>

            next_state             <= S0;  --After everything is done go to the reset state
            c_SetA_RW              <= '0';
            c_SetB_RW              <= '0';
            c_done                 <= '1';
            c_begin_stage          <= '0';
            c_last_stage           <= '0';
            c_add_sub              <= '0';
            c_load                 <= '0';
            c_load1                <= '0';
            c_load_P               <= '0';
            c_load_P2              <= '0';
            c_load_Q               <= '0';
            c_load_W               <= '0';
            c_sel                  <= '0';
            c_bfy0_ip0_reg_load    <= '0';
            c_bfy0_ip1_reg_load    <= '0';
            c_bfy0_mux_sel         <= '0';
            c_bfy0_tw_reg_load     <= '0';
            c_bfy0_tw_sel          <= '0';
            c_bfy0_add_op_reg_load <= '0';
            c_bfy0_sub_op_reg_load <= '0';                            
            c_bfy1_ip0_reg_load    <= '0';
            c_bfy1_ip1_reg_load    <= '0';
            c_bfy1_mux_sel         <= '0';
            c_bfy1_tw_reg_load     <= '0';
            c_bfy1_tw_sel          <= '0';
            c_bfy1_add_op_reg_load <= '0';
            c_bfy1_sub_op_reg_load <= '0';

        end case;

          end if;

      end if;

        current_state <= next_state;  --Update the current state and input flip signals
        c_input_flip <= s_input_flip;

    end process STATE_MACHINE;

end control_unit_arch;
