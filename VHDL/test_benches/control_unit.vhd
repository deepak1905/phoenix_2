-------------------------------------------------------------------------------
-- Title      : Control unit module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : control_unit.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/11/06
-- Platform   : 
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


entity control_unit is

  generic (
    N_width : integer := 7);   -- By default 64 point FFT is supported.
  
  port (
    clk                  : in  std_logic;          -- clock input
    rst                  : in  std_logic;          -- reset signal
    start                : in  std_logic;          -- enables start of FFT computation
    N                    : in  std_logic_vector (N_width-1 downto 0);-- number of FFT points    
    c_add_sub            : out std_logic;          --add/subtract control signal
    c_load               : out std_logic;          -- register load control signal
    c_load1              : out std_logic;          -- register load control signal
    c_load_P             : out std_logic;          -- load P register input - control signal
    c_load_P2            : out std_logic;          -- load next P reg input - control signal
    c_load_Q             : out std_logic;          -- load Q register input - control signal
    c_load_W             : out std_logic;          -- load W register input - control signal
    c_sel                : out std_logic;          -- select PR, PI mux control signal
    SetA_RW              : out std_logic;          -- interconnect A RW signal('0' - read, '1' - write)
    SetB_RW              : out std_logic;          -- interconnect B RW signal('0' - read, '1' - write)
    bfy0_ip0_reg_load    : out std_logic;          -- butterfly unit0 input0 register load
    bfy0_ip1_reg_load    : out std_logic;          -- butterfly unit0 input1 register load
    bfy0_mux_sel         : out std_logic;          -- butterfly unit0 input(Q/P) sel
    bfy0_tw_reg_load     : out std_logic;          -- butterfly unit0 twiddle factor reg load
    bfy0_tw_sel          : out std_logic;          -- butterfly unit0 twiddle factor sel(WR/WI)
    bfy0_add_op_reg_load : out std_logic;          --butterfly unit0 addition output result load
    bfy0_sub_op_reg_load : out std_logic;          --butterfly unit0 subtraction output result load
    bfy1_ip0_reg_load    : out std_logic;          -- butterfly unit1 input0 register load
    bfy1_ip1_reg_load    : out std_logic;          -- butterfly unit1 input1 register load
    bfy1_mux_sel         : out std_logic;          -- butterfly unit1 input(Q/P) sel
    bfy1_tw_reg_load     : out std_logic;          -- butterfly unit1 twiddle factor reg load
    bfy1_tw_sel          : out std_logic;          -- butterfly unit1 twiddle factor sel(WR/WI)
    bfy1_add_op_reg_load : out std_logic;          --butterfly unit1 addition output result load
    bfy1_sub_op_reg_load : out std_logic;          --butterfly unit1 subtraction output result load
    done                 : out std_logic);         -- indicates completion of FFT computation
end control_unit;


architecture control_unit_arch of control_unit is

  type state_type is (S0, S1, S2, S3);                  -- States required in the Moore state machine
  signal current_state : state_type := S0;              -- state variable initialized to the reset state
  signal next_state : state_type := S0;                 -- next state variable

begin  -- control_unit_arch

  STATE_MACHINE: process(clk, rst)

    --N/4 is the number of iterations per stage with two butterfly units
    variable stage_iteration_count : std_logic_vector(N_width - 1 downto 0);

    --keeping count of FFT computation stage, its same size as that of N
    variable stage_count : std_logic_vector(N_width - 1 downto 0) := (others =>'0');

    -- clock cycle instance during piplined execution in butterfly
    variable cycle_clock_instance : integer range -2 to 3 := 0;
    -- allow two more cycles to flush the pipeline in
    -- the final stage of FFT computation
    variable pipe_line_flush : integer := 2;
    -- flag indicating whether pipeline flush is required or not
    variable flush_pipeline : boolean := false;  
                                                        
    begin

      if rst = '0' then

        done                 <= '0';
        SetA_RW              <= '0';
        SetB_RW              <= '0';
        c_add_sub            <= '0';
        c_load               <= '0';
        c_load1              <= '0';
        c_load_P             <= '0';
        c_load_P2            <= '0';
        c_load_Q             <= '0';
        c_load_W             <= '0';
        c_sel                <= '0';
        bfy0_ip0_reg_load    <= '0';
        bfy0_ip1_reg_load    <= '0';
        bfy0_mux_sel         <= '0';
        bfy0_tw_reg_load     <= '0';
        bfy0_tw_sel          <= '0';
        bfy0_add_op_reg_load <= '0';
        bfy0_sub_op_reg_load <= '0';
        bfy1_ip0_reg_load    <= '0';
        bfy1_ip1_reg_load    <= '0';
        bfy1_mux_sel         <= '0';
        bfy1_tw_reg_load     <= '0';
        bfy1_tw_sel          <= '0';
        bfy1_add_op_reg_load <= '0';
        bfy1_sub_op_reg_load <= '0';

        --after reset begin with the initial state        
        current_state <= S0;
        next_state    <= S0;
        
        --shifting right by 1 positions makes it N/2 which is number of clock cycles
        --required per FFT stage(because butterfly reads new sample every 2
        --clock cycles). The initial stage takes two additional cycles because
        --the data from the RAM/ROM units take two cycles to arrive at the
        --butterfly input after the address generation.
        stage_iteration_count := SHR(N, "01") + "10";
        stage_count           := stage_count(N_width-1 downto 1) & '1';

        cycle_clock_instance  := -2;

      elsif clk'event and clk = '1' then

        --supports only 8 or greater FFT points computation
        if N >= 8 then 
          
        case current_state is

          when  S0 =>
            
            --start the computation only after start=1            
            if stage_count /= N and start = '1' then 
              
               next_state <= S1;
              
              else
                
                next_state <= S0;
                
            end if;

            --update the output signals in the reset state
            SetA_RW <= '0';
            SetB_RW <= '0';
            done    <= '0';
            
          when S1 =>

            if flush_pipeline = false then
              
            --decrease iteration count by 1
            stage_iteration_count := stage_iteration_count - 1;
            
              if stage_iteration_count = 0 then

                --current stage is complete, go to next stage
                stage_count := SHL(stage_count, "1");
                --initialize the iteration count for the next stage
                stage_iteration_count := SHR(N, "01");

                if stage_count /= N then

                  --move to the next state after all the iterations are
                  --completed in the current state
                  next_state <= S2;

                else

                  --for the last two cycles in the last stage of
                  --FFT there is a need to allow for the pipeline
                  --to finish its computation
                  flush_pipeline := true;
                  pipe_line_flush := pipe_line_flush - 1;

                 end if;

              end if;

              --Set the output control signals
              SetA_RW <= '0';
              SetB_RW <= '1';
              done    <= '0';

            --It takes wwo cycles in the beginning for the input data
            --to arrive at the input of butterfly units, hence start the
            --butterfly unit specific control signals are triggered at the
            --third cycle of stage S1
              case cycle_clock_instance is
                when -2 =>
                  c_add_sub            <= '0';
                  c_load               <= '0';
                  c_load1              <= '0';
                  c_load_P             <= '0';
                  c_load_P2            <= '0';
                  c_load_Q             <= '0';
                  c_load_W             <= '0';
                  c_sel                <= '0';
                  bfy0_ip0_reg_load    <= '0';
                  bfy0_ip1_reg_load    <= '0';
                  bfy0_mux_sel         <= '0';
                  bfy0_tw_reg_load     <= '0';
                  bfy0_tw_sel          <= '0';
                  bfy0_add_op_reg_load <= '0';
                  bfy0_sub_op_reg_load <= '0';
                  bfy1_ip0_reg_load    <= '0';
                  bfy1_ip1_reg_load    <= '0';
                  bfy1_mux_sel         <= '0';
                  bfy1_tw_reg_load     <= '0';
                  bfy1_tw_sel          <= '0';
                  bfy1_add_op_reg_load <= '0';
                  bfy1_sub_op_reg_load <= '0';
                  
                  cycle_clock_instance := -1;
                when -1 =>
                  c_add_sub            <= '0';
                  c_load               <= '0';
                  c_load1              <= '0';
                  c_load_P             <= '0';
                  c_load_P2            <= '0';
                  c_load_Q             <= '0';
                  c_load_W             <= '0';
                  c_sel                <= '0';
                  bfy0_ip0_reg_load    <= '1';
                  bfy0_ip1_reg_load    <= '1';
                  bfy0_mux_sel         <= '1';
                  bfy0_tw_reg_load     <= '1';
                  bfy0_tw_sel          <= '1';
                  bfy0_add_op_reg_load <= '0';
                  bfy0_sub_op_reg_load <= '0';                  
                  bfy1_ip0_reg_load    <= '1';
                  bfy1_ip1_reg_load    <= '1';
                  bfy1_mux_sel         <= '1';
                  bfy1_tw_reg_load     <= '1';
                  bfy1_tw_sel          <= '1';
                  bfy1_add_op_reg_load <= '0';
                  bfy1_sub_op_reg_load <= '0';                  

                  cycle_clock_instance := 0;                  
                when 0 =>
                  c_add_sub            <= '1';
                  c_load               <= '0';
                  c_load1              <= '1';
                  c_load_P             <= '0';
                  c_load_P2            <= '0';
                  c_load_Q             <= '1';
                  c_load_W             <= '1';
                  c_sel                <= '0';
                  bfy0_ip0_reg_load    <= '0';
                  bfy0_ip1_reg_load    <= '0';
                  bfy0_mux_sel         <= '0';
                  bfy0_tw_reg_load     <= '0';
                  bfy0_tw_sel          <= '0';
                  bfy0_add_op_reg_load <= '1';
                  bfy0_sub_op_reg_load <= '0';                  
                  bfy1_ip0_reg_load    <= '0';
                  bfy1_ip1_reg_load    <= '0';
                  bfy1_mux_sel         <= '0';
                  bfy1_tw_reg_load     <= '0';
                  bfy1_tw_sel          <= '0';
                  bfy1_add_op_reg_load <= '1';
                  bfy1_sub_op_reg_load <= '0';                  


                  cycle_clock_instance := 1;
                when 1 =>
                  c_add_sub            <= '0';
                  c_load               <= '1';
                  c_load1              <= '0';
                  c_load_P             <= '1';
                  c_load_P2            <= '0';
                  c_load_Q             <= '0';
                  c_load_W             <= '1';
                  c_sel                <= '1';
                  bfy0_ip0_reg_load    <= '1';
                  bfy0_ip1_reg_load    <= '1';
                  bfy0_mux_sel         <= '1';
                  bfy0_tw_reg_load     <= '1';
                  bfy0_tw_sel          <= '1';
                  bfy0_add_op_reg_load <= '0';
                  bfy0_sub_op_reg_load <= '1';                  
                  bfy1_ip0_reg_load    <= '1';
                  bfy1_ip1_reg_load    <= '1';
                  bfy1_mux_sel         <= '1';
                  bfy1_tw_reg_load     <= '1';
                  bfy1_tw_sel          <= '1';
                  bfy1_add_op_reg_load <= '0';
                  bfy1_sub_op_reg_load <= '1';                  

                  cycle_clock_instance := 2;
                when 2 =>
                  c_add_sub            <= '1';
                  c_load               <= '0';
                  c_load1              <= '1';
                  c_load_P             <= '0';
                  c_load_P2            <= '0';
                  c_load_Q             <= '1';
                  c_load_W             <= '1';
                  c_sel                <= '1';
                  bfy0_ip0_reg_load    <= '0';
                  bfy0_ip1_reg_load    <= '0';
                  bfy0_mux_sel         <= '0';
                  bfy0_tw_reg_load     <= '0';
                  bfy0_tw_sel          <= '0';
                  bfy0_add_op_reg_load <= '1';
                  bfy0_sub_op_reg_load <= '0';                  
                  bfy1_ip0_reg_load    <= '0';
                  bfy1_ip1_reg_load    <= '0';
                  bfy1_mux_sel         <= '0';
                  bfy1_tw_reg_load     <= '0';
                  bfy1_tw_sel          <= '0';
                  bfy1_add_op_reg_load <= '1';
                  bfy1_sub_op_reg_load <= '0';                  
                  
                  cycle_clock_instance := 3;
                when 3 =>
                  c_add_sub            <= '0';
                  c_load               <= '1';
                  c_load1              <= '0';
                  c_load_P             <= '0';
                  c_load_P2            <= '1';
                  c_load_Q             <= '0';
                  c_load_W             <= '1';
                  c_sel                <= '0';
                  bfy0_ip0_reg_load    <= '1';
                  bfy0_ip1_reg_load    <= '1';
                  bfy0_mux_sel         <= '1';
                  bfy0_tw_reg_load     <= '1';
                  bfy0_tw_sel          <= '1';
                  bfy0_add_op_reg_load <= '0';
                  bfy0_sub_op_reg_load <= '1';                  
                  bfy1_ip0_reg_load    <= '1';
                  bfy1_ip1_reg_load    <= '1';
                  bfy1_mux_sel         <= '1';
                  bfy1_tw_reg_load     <= '1';
                  bfy1_tw_sel          <= '1';
                  bfy1_add_op_reg_load <= '0';
                  bfy1_sub_op_reg_load <= '1';                  
                  
                  cycle_clock_instance := 0;                  
                when others => null;
              end case;            

            else

              --When the pipeline is to be
              --flushed no need to read fresh
              --input values from the memory
              SetA_RW <= '0';
              SetB_RW <= '0';
              done    <= '0';

              --Perform add and subtract in the last two cycles of
              --FFT computation corresponding to last two sample values
              if pipe_line_flush = 1 then
                
                c_add_sub <= '1';

              elsif pipe_line_flush = 0 then

                c_add_sub <= '0';
                
              end if;

              --No more butterfly computations are needed hence
              --set the rest of the control signals to 0
              c_load               <= '0';
              c_load1              <= '0';
              c_load_P             <= '0';
              c_load_P2            <= '0';
              c_load_Q             <= '0';
              c_load_W             <= '0';
              c_sel                <= '0';
              bfy0_ip0_reg_load    <= '0';
              bfy0_ip1_reg_load    <= '0';
              bfy0_mux_sel         <= '0';
              bfy0_tw_reg_load     <= '0';
              bfy0_tw_sel          <= '0';
              bfy0_add_op_reg_load <= '0';
              bfy0_sub_op_reg_load <= '0';                                
              bfy1_ip0_reg_load    <= '0';
              bfy1_ip1_reg_load    <= '0';
              bfy1_mux_sel         <= '0';
              bfy1_tw_reg_load     <= '0';
              bfy1_tw_sel          <= '0';
              bfy1_add_op_reg_load <= '0';
              bfy1_sub_op_reg_load <= '0';              

              if pipe_line_flush = 0 then

                --move to the done state if all the FFT stages are completed
                next_state <= S3;

                else

                  pipe_line_flush := pipe_line_flush - 1;

                end if;

            end if;

          when S2 =>

            if flush_pipeline = false then

            --decrease iteration count by 1
            stage_iteration_count := stage_iteration_count - 1;

              if stage_iteration_count = 0 then

                --current stage is complete, go to next stage
                stage_count := SHL(stage_count, "1");
                --initialize the iteration count for the next stage
                stage_iteration_count := SHR(N,"01");

                if stage_count /= N then

                  --move to the next state after all the iterations are
                  --completed in the current state
                  next_state <= S1;

                  else

                    --for the last two cycles in the last stage of
                    --FFT there is a need to allow for the pipeline
                    --to finish its computation                    
                    flush_pipeline := true;
                    pipe_line_flush := pipe_line_flush - 1;

                end if;

              end if;

              --Set the output control signals
              SetA_RW <= '1';
              SetB_RW <= '0';
              done    <= '0';

              case cycle_clock_instance is
                when -2 =>
                  c_add_sub            <= '0';
                  c_load               <= '0';
                  c_load1              <= '0';
                  c_load_P             <= '0';
                  c_load_P2            <= '0';
                  c_load_Q             <= '0';
                  c_load_W             <= '0';
                  c_sel                <= '0';
                  bfy0_ip0_reg_load    <= '0';
                  bfy0_ip1_reg_load    <= '0';
                  bfy0_mux_sel         <= '0';
                  bfy0_tw_reg_load     <= '0';
                  bfy0_tw_sel          <= '0';
                  bfy0_add_op_reg_load <= '0';
                  bfy0_sub_op_reg_load <= '0';                                    
                  bfy1_ip0_reg_load    <= '0';
                  bfy1_ip1_reg_load    <= '0';
                  bfy1_mux_sel         <= '0';
                  bfy1_tw_reg_load     <= '0';
                  bfy1_tw_sel          <= '0';
                  bfy1_add_op_reg_load <= '0';
                  bfy1_sub_op_reg_load <= '0';                                
                  
                  cycle_clock_instance := -1;
                when -1 =>
                  c_add_sub            <= '0';
                  c_load               <= '0';
                  c_load1              <= '0';
                  c_load_P             <= '0';
                  c_load_P2            <= '0';
                  c_load_Q             <= '0';
                  c_load_W             <= '0';
                  c_sel                <= '0';
                  bfy0_ip0_reg_load    <= '1';
                  bfy0_ip1_reg_load    <= '1';
                  bfy0_mux_sel         <= '1';
                  bfy0_tw_reg_load     <= '1';
                  bfy0_tw_sel          <= '1';
                  bfy0_add_op_reg_load <= '0';
                  bfy0_sub_op_reg_load <= '0';                  
                  bfy1_ip0_reg_load    <= '1';
                  bfy1_ip1_reg_load    <= '1';
                  bfy1_mux_sel         <= '1';
                  bfy1_tw_reg_load     <= '1';
                  bfy1_tw_sel          <= '1';
                  bfy1_add_op_reg_load <= '0';
                  bfy1_sub_op_reg_load <= '0';                                

                  cycle_clock_instance := 0;                
                when 0 =>
                  c_add_sub            <= '1';
                  c_load               <= '0';
                  c_load1              <= '1';
                  c_load_P             <= '0';
                  c_load_P2            <= '0';
                  c_load_Q             <= '1';
                  c_load_W             <= '1';
                  c_sel                <= '0';
                  bfy0_ip0_reg_load    <= '0';
                  bfy0_ip1_reg_load    <= '0';
                  bfy0_mux_sel         <= '0';
                  bfy0_tw_reg_load     <= '0';
                  bfy0_tw_sel          <= '0';
                  bfy0_add_op_reg_load <= '1';
                  bfy0_sub_op_reg_load <= '0';                  
                  bfy1_ip0_reg_load    <= '0';
                  bfy1_ip1_reg_load    <= '0';
                  bfy1_mux_sel         <= '0';
                  bfy1_tw_reg_load     <= '0';
                  bfy1_tw_sel          <= '0';
                  bfy1_add_op_reg_load <= '1';
                  bfy1_sub_op_reg_load <= '0';                  

                  cycle_clock_instance := 1;
                when 1 =>
                  c_add_sub            <= '0';
                  c_load               <= '1';
                  c_load1              <= '0';
                  c_load_P             <= '1';
                  c_load_P2            <= '0';
                  c_load_Q             <= '0';
                  c_load_W             <= '1';
                  c_sel                <= '1';
                  bfy0_ip0_reg_load    <= '1';
                  bfy0_ip1_reg_load    <= '1';
                  bfy0_mux_sel         <= '1';
                  bfy0_tw_reg_load     <= '1';
                  bfy0_tw_sel          <= '1';
                  bfy0_add_op_reg_load <= '0';
                  bfy0_sub_op_reg_load <= '1';                  
                  bfy1_ip0_reg_load    <= '1';
                  bfy1_ip1_reg_load    <= '1';
                  bfy1_mux_sel         <= '1';
                  bfy1_tw_reg_load     <= '1';
                  bfy1_tw_sel          <= '1';
                  bfy1_add_op_reg_load <= '0';
                  bfy1_sub_op_reg_load <= '1';                  

                  cycle_clock_instance := 2;
                when 2 =>
                  c_add_sub            <= '1';
                  c_load               <= '0';
                  c_load1              <= '1';
                  c_load_P             <= '0';
                  c_load_P2            <= '0';
                  c_load_Q             <= '1';
                  c_load_W             <= '1';
                  c_sel                <= '1';
                  bfy0_ip0_reg_load    <= '0';
                  bfy0_ip1_reg_load    <= '0';
                  bfy0_mux_sel         <= '0';
                  bfy0_tw_reg_load     <= '0';
                  bfy0_tw_sel          <= '0';
                  bfy0_add_op_reg_load <= '1';
                  bfy0_sub_op_reg_load <= '0';                  
                  bfy1_ip0_reg_load    <= '0';
                  bfy1_ip1_reg_load    <= '0';
                  bfy1_mux_sel         <= '0';
                  bfy1_tw_reg_load     <= '0';
                  bfy1_tw_sel          <= '0';
                  bfy1_add_op_reg_load <= '1';
                  bfy1_sub_op_reg_load <= '0';                  

                  cycle_clock_instance := 3;
                when 3 =>
                  c_add_sub            <= '0';
                  c_load               <= '1';
                  c_load1              <= '0';
                  c_load_P             <= '0';
                  c_load_P2            <= '1';
                  c_load_Q             <= '0';
                  c_load_W             <= '1';
                  c_sel                <= '0';
                  bfy0_ip0_reg_load    <= '1';
                  bfy0_ip1_reg_load    <= '1';
                  bfy0_mux_sel         <= '1';
                  bfy0_tw_reg_load     <= '1';
                  bfy0_tw_sel          <= '1';
                  bfy0_add_op_reg_load <= '0';
                  bfy0_sub_op_reg_load <= '1';                  
                  bfy1_ip0_reg_load    <= '1';
                  bfy1_ip1_reg_load    <= '1';
                  bfy1_mux_sel         <= '1';
                  bfy1_tw_reg_load     <= '1';
                  bfy1_tw_sel          <= '1';
                  bfy1_add_op_reg_load <= '0';
                  bfy1_sub_op_reg_load <= '1';

                  cycle_clock_instance := 0;
                when others => null;
              end case;

            else

              --When the pipeline is to be
              --flushed no need to read fresh
              --input values from the memory              
              SetA_RW <= '0';
              SetB_RW <= '0';
              done    <= '0';

              --Perform add and subtract in the last two cycles of
              --FFT computation corresponding to last two sample values              
              if pipe_line_flush = 1 then
                
                c_add_sub <= '1';

              elsif pipe_line_flush = 0 then

                c_add_sub <= '0';
                
              end if;

              --No more butterfly computations are needed hence
              --set the rest of the control signals to 0
              c_load               <= '0';
              c_load1              <= '0';
              c_load_P             <= '0';
              c_load_P2            <= '0';
              c_load_Q             <= '0';
              c_load_W             <= '0';
              c_sel                <= '0';
              bfy0_ip0_reg_load    <= '0';
              bfy0_ip1_reg_load    <= '0';
              bfy0_mux_sel         <= '0';
              bfy0_tw_reg_load     <= '0';
              bfy0_tw_sel          <= '0';
              bfy0_add_op_reg_load <= '0';
              bfy0_sub_op_reg_load <= '0';              
              bfy1_ip0_reg_load    <= '0';
              bfy1_ip1_reg_load    <= '0';
              bfy1_mux_sel         <= '0';
              bfy1_tw_reg_load     <= '0';
              bfy1_tw_sel          <= '0';
              bfy1_add_op_reg_load <= '0';
              bfy1_sub_op_reg_load <= '0';              

              if pipe_line_flush = 0 then

                --move to the done state if all the FFT stages are completed
                next_state <= S3;

                else

                  pipe_line_flush := pipe_line_flush - 1;

                end if;

              end if;

          when others =>

            --after everything is done go to the reset state
            next_state           <= S0;
            SetA_RW              <= '0';
            SetB_RW              <= '0';
            done                 <= '1';
            c_add_sub            <= '0';
            c_load               <= '0';
            c_load1              <= '0';
            c_load_P             <= '0';
            c_load_P2            <= '0';
            c_load_Q             <= '0';
            c_load_W             <= '0';
            c_sel                <= '0';
            bfy0_ip0_reg_load    <= '0';
            bfy0_ip1_reg_load    <= '0';
            bfy0_mux_sel         <= '0';
            bfy0_tw_reg_load     <= '0';
            bfy0_tw_sel          <= '0';
            bfy0_add_op_reg_load <= '0';
            bfy0_sub_op_reg_load <= '0';                            
            bfy1_ip0_reg_load    <= '0';
            bfy1_ip1_reg_load    <= '0';
            bfy1_mux_sel         <= '0';
            bfy1_tw_reg_load     <= '0';
            bfy1_tw_sel          <= '0';
            bfy1_add_op_reg_load <= '0';
            bfy1_sub_op_reg_load <= '0';              

        end case;

        end if;

      end if;

      --update the current state
      current_state <= next_state;

    end process STATE_MACHINE;

end control_unit_arch;
