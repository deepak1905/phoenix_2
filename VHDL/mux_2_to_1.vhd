-------------------------------------------------------------------------------
-- Title      : 2 to 1 multiplexer
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : 2_to_1_mux.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : 
-- Last update: 2012/09/12
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Multiplexer with two inputs, one select input and an output
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/09/12  1.0      revanna	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity mux_2_to_1 is

  generic (
    DATA_WIDTH : integer := 32); -- by default width of the mux input is
                                 -- 32 bits(16 bit real and 16 bit imag value)
  
  port (
    input0 : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- first input line
    input1 : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- second input line
    sel    : in  std_logic;                                -- select line
    output : out std_logic_vector(DATA_WIDTH-1 downto 0)); -- output line

end mux_2_to_1;

architecture rtl of mux_2_to_1 is

begin  -- rtl

  MUX_PROCESS: process(input0, input1, sel)
    begin

      --Based on the select line assign
      --input lines to the output line
      if sel = '0' then
        
        output <= input0;
        
        else
          
          output <= input1;
          
      end if;
      
    end process MUX_PROCESS;

end rtl;
