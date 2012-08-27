-------------------------------------------------------------------------------
-- Title      : Control unit module
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : control_unit.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/08/03
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
    N_width : integer := 4);   -- the width of number of FFT points value. Default value is 4 so that 8 point FFT is the
                               -- minimum number of FFT point computation allowed.
  
  port (
    clk     : in  std_logic;                            -- clock input
    N       : in  std_logic_vector (N_width-1 downto 0);        -- number of FFT points
    rst     : in  std_logic;                            -- reset signal
    start   : in  std_logic;                            -- enables start of FFT computation
    SetA_RW : out std_logic;                            -- interconnect A RW signal
    SetB_RW : out std_logic;                            -- interconnect B RW signal
    done    : out std_logic);                           -- indicates completion of FFT computation
end control_unit;


architecture control_unit_arch of control_unit is

  type state_type is (S0, S1, S2, S3);                  -- States required in the Moore state machine
  signal current_state : state_type := S0;              -- state variable initialized to the reset state
  signal next_state : state_type := S0;                 -- next state variable

begin  -- control_unit_arch

  STATE_MACHINE: process(clk, rst)
    variable           stage_iteration_count : std_logic_vector(N_width - 1 downto 0); --N/4 is the of iterations per stage with two butterfly units
    variable stage_count : std_logic_vector(N_width - 1 downto 0) := (others =>'0');  --keeping count of FFT computation stage, its same size as that of N
                                                        
    begin

      if rst = '1' then

        done <= '0';
        SetA_RW <= '0';
        SetB_RW <= '0';
        current_state <= S0;            --after reset begin with the initial state
        next_state <= S0;
        stage_iteration_count := SHR(N, "10");  --shifting right by 2 positions makes it N/4 which is number of iterations per FFT stage
        stage_count := stage_count(N_width-1 downto 1) & '1';

      elsif clk'event and clk = '1' then

        if N >= 8 then                  --supports only 8 or greater FFT points computation
          
        case current_state is

          when  S0 =>
            
            if stage_count /= N and start = '1' then --start the computation only after start=1
              
               next_state <= S1;
              
              else
                
                next_state <= S0;
                
            end if;
            
            SetA_RW <= '0'; --update the output signals in the reset state
            SetB_RW <= '0';
            done <= '0';
            
          when S1 =>

            stage_iteration_count := stage_iteration_count - 1; --decrease iteration count by 1
            
              if stage_iteration_count = 0 then

                stage_count := SHL(stage_count, "1"); --current stage is complete go to next stage
                stage_iteration_count := SHR(N, "10"); --initialize the iteration count for the next stage

                if stage_count /= N then
                  
                  next_state <= S2; --move to the next state after all the iterations are completed in the current state
                  
                  else

                    next_state <= S3; --move to the done state if all the FFT stages are completed
                    
                end if;

              end if;

              SetA_RW <= '1';  --Set the output signals
              SetB_RW <= '0';
              done <= '0';

          when S2 =>

            stage_iteration_count := stage_iteration_count - 1; --decrease iteration count by 1

              if stage_iteration_count = 0 then

                stage_count := SHL(stage_count, "1"); --current stage is complete go to next stage
                stage_iteration_count := SHR(N,"10"); --initialize the iteration count for the next stage

                if stage_count /= N then

                  next_state <= S1; --move to the next state after all the iterations are completed in the current state

                  else
                    
                    next_state <= S3; --move to the done state if all the FFT stages are completed
                    
                end if;
              
              end if;

              SetA_RW <= '0'; --Set the output signals
              SetB_RW <= '1';
              done <= '0';
            
          when others =>
            
            next_state <= S0; --after everything is done go to the reset state
            SetA_RW <= '0';
            SetB_RW <= '0';
            done <= '1';
                         
        end case;
        
        end if;
        
      end if;

      current_state <= next_state; --update the current state
      
    end process STATE_MACHINE;

end control_unit_arch;
