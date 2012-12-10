-------------------------------------------------------------------------------
-- Title      : N bit register
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : reg_n_bit.vhd
-- Author     : Deepak Revanna  <deepak.revanna@tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/12/05
-- Platform   : Altera stratix II FPGA
-------------------------------------------------------------------------------
-- Description: Register with n-bit input
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/09/13  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity reg_n_bit is
  
  generic (
    DATA_WIDTH : integer := 32);        -- Default data width is 32 bits

  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    load     : in  std_logic;
    data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));

end reg_n_bit;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

architecture rtl of reg_n_bit is

  --Register
  signal reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin  -- rtl

  data_out <= reg;
  
  REG_PROCESS: process(clk, rst)
    begin

      --On reset clear the register otherwise
      --set the output based on the load
      --control signal
      if rst = '0' then
        
          reg <= (others => '0');
          
      elsif clk'event and clk = '1' then
        
          if load = '1' or load = 'H' then
            
              reg <= data_in;
              
          end if;
              
      end if;
      
  end process REG_PROCESS;

end rtl;

