-------------------------------------------------------------------------------
-- Title      : Test bench for the interconnect
-- Project    : N point FFT processor
-------------------------------------------------------------------------------
-- File       : interconnect_tb.vhd
-- Author     : Deepak Revanna  <revanna@pikkukeiju.cs.tut.fi>
-- Company    : Tampere University of Technology
-- Last update: 2012/08/03
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: The test bench to test the interconnect which is a link
--              between butterfly units and RAM memory banks. It tests the
--              module for different values of N(8, 16, 32 & 64 points)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012/07/30  1.0      revanna	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity interconnect_tb is
end interconnect_tb;

architecture interconnect_tb_arch of interconnect_tb is

  component interconnect
        generic (
          N_width : integer);
        port (
          clk              : in  std_logic;
          rst              : in  std_logic;
          RW               : in  std_logic;
          count0_i         : in  std_logic_vector(N_width-4 downto 0);
          count1_i         : in  std_logic_vector(N_width-4 downto 0);
          store0_i         : in  std_logic_vector(N_width-3 downto 0);
          store1_i         : in  std_logic_vector(N_width-3 downto 0);
          bfy0_add         : in  integer range -32767 to 32767;
          bfy0_sub         : in  integer range -32767 to 32767;
          bfy1_add         : in  integer range -32767 to 32767;
          bfy1_sub         : in  integer range -32767 to 32767;
          operand0_out_bfy : out integer range -32767 to 32767;
          operand1_out_bfy : out integer range -32767 to 32767;
          operand2_out_bfy : out integer range -32767 to 32767;
          operand3_out_bfy : out integer range -32767 to 32767;
          operand0_addr    : out std_logic_vector(N_width-3 downto 0);
          operand1_addr    : out std_logic_vector(N_width-3 downto 0);
          operand2_addr    : out std_logic_vector(N_width-3 downto 0);
          operand3_addr    : out std_logic_vector(N_width-3 downto 0));
  end component;
  
      --For 8 point fft
    signal tb_clk : std_logic := '0';
    signal tb_rst : std_logic := '0';
    signal tb_RW_1, tb_RW_2             : std_logic := '0';         -- read-write signal from control unit(0 = read, 1 = write)
    signal tb_count0_i_1        : std_logic_vector(0 downto 0) := (others => '0');  -- operand address from address gen unit
    signal tb_count0_i_2        : std_logic_vector(1 downto 0) := (others => '0');  -- operand address from address gen unit
                                                                                     
    signal tb_count1_i_1        : std_logic_vector(0 downto 0) := (others => '0');  -- operand address from address gen unit
    signal tb_count1_i_2        : std_logic_vector(1 downto 0) := (others => '0');  -- operand address from address gen unit
                                                                                    
    signal tb_store0_i_1        : std_logic_vector(1 downto 0) := (others => '0');  -- write operand address from address gen unit
    signal tb_store0_i_2        : std_logic_vector(2 downto 0) := (others => '0');  -- write operand address from address gen unit
                                                                                    
    signal tb_store1_i_1        : std_logic_vector(1 downto 0) := (others => '0');  -- write operand address from address gen unit
    signal tb_store1_i_2        : std_logic_vector(2 downto 0) := (others => '0');  -- write operand address from address gen unit  

    signal tb_bfy0_add_1, tb_bfy0_add_2        : integer range -32767 to 32767 := 0;  -- result of addition from butterfly0 unit
    signal tb_bfy0_sub_1, tb_bfy0_sub_2        : integer range -32767 to 32767 := 0;  -- result of subtraction from butterfly0 unit
    signal tb_bfy1_add_1, tb_bfy1_add_2        : integer range -32767 to 32767 := 0;  -- result of addition from butterfly1 unit
    signal tb_bfy1_sub_1, tb_bfy1_sub_2        : integer range -32767 to 32767 := 0;  -- result of subtraction from butterfly1 unit

    --NOTE: (NOTE:store addr is 1 bit bigger than count addr hence o/p addr of
    --interconnect is of the same size as that of store addr
    signal tb_operand0_addr_1   : std_logic_vector(1 downto 0) := (others => '0');  -- address of operand 0
    signal tb_operand0_addr_2   : std_logic_vector(2 downto 0) := (others => '0');  -- address of operand 0
                                                                                    
    signal tb_operand1_addr_1   : std_logic_vector(1 downto 0) := (others => '0');  -- address of operand 1
    signal tb_operand1_addr_2   : std_logic_vector(2 downto 0) := (others => '0');  -- address of operand 1
                                                                                    
    signal tb_operand2_addr_1   : std_logic_vector(1 downto 0) := (others => '0');  -- address of operand 2
    signal tb_operand2_addr_2   : std_logic_vector(2 downto 0) := (others => '0');  -- address of operand 2
                                                                                    
    signal tb_operand3_addr_1   : std_logic_vector(1 downto 0) := (others => '0');  -- address of operand 3
    signal tb_operand3_addr_2   : std_logic_vector(2 downto 0) := (others => '0');  -- address of operand 3  

    signal tb_operand0_out_bfy_1, tb_operand0_out_bfy_2 : integer range -32767 to 32767 := 0;  -- input operand 0 to butterfly units
    signal tb_operand1_out_bfy_1, tb_operand1_out_bfy_2 : integer range -32767 to 32767 := 0;  -- input operand 1 to butterfly units
    signal tb_operand2_out_bfy_1, tb_operand2_out_bfy_2 : integer range -32767 to 32767 := 0;  -- input operand 2 to butterfly units
    signal tb_operand3_out_bfy_1, tb_operand3_out_bfy_2 : integer range -32767 to 32767 := 0;  -- input operand 3 to butterfly units
    constant half_clk_period : time := 10 ns;
    constant end_simulation : boolean := false;
  
    --Input values to the interconnect: result from butterfly units
    constant bfy0_add : integer := 1;
    constant bfy0_sub : integer := 2;
    constant bfy1_add : integer := 3;
    constant bfy1_sub : integer := 4;

    --calculate the output of the interconnect in the scope of the test bench
    --inorder to validate the output of design under test i.e interconnect block
    signal validate_operand0_addr_1 : std_logic_vector(1 downto 0) := (others => '0');
    signal validate_operand0_addr_2 : std_logic_vector(2 downto 0) := (others => '0');  
  
    signal validate_operand1_addr_1 : std_logic_vector(1 downto 0) := (others => '0');
    signal validate_operand1_addr_2 : std_logic_vector(2 downto 0) := (others => '0');

    signal validate_operand2_addr_1 : std_logic_vector(1 downto 0) := (others => '0');
    signal validate_operand2_addr_2 : std_logic_vector(2 downto 0) := (others => '0');
  
    signal validate_operand3_addr_1 : std_logic_vector(1 downto 0) := (others => '0');
    signal validate_operand3_addr_2 : std_logic_vector(2 downto 0) := (others => '0');  

    --data output routed by the interconnect
    signal validate_operand0_out_bfy_1, validate_operand0_out_bfy_2 : integer range -32767 to 32767 := 0;
    signal validate_operand1_out_bfy_1, validate_operand1_out_bfy_2 : integer range -32767 to 32767 := 0;
    signal validate_operand2_out_bfy_1, validate_operand2_out_bfy_2 : integer range -32767 to 32767 := 0;
    signal validate_operand3_out_bfy_1, validate_operand3_out_bfy_2 : integer range -32767 to 32767 := 0;

begin  -- interconnect_tb_arch

  --instantiate the design under test for
  --8 point FFT
--     U0: interconnect
--       generic map (
--         N_width => 4)
--       port map (
--         clk              => tb_clk,
--         rst              => tb_rst,
--         RW               => tb_RW_1,
--         count0_i         => tb_count0_i_1,
--         count1_i         => tb_count1_i_1,
--         store0_i         => tb_store0_i_1,
--         store1_i         => tb_store1_i_1,
--         bfy0_add         => tb_bfy0_add_1,
--         bfy0_sub         => tb_bfy0_sub_1,
--         bfy1_add         => tb_bfy1_add_1,
--         bfy1_sub         => tb_bfy1_sub_1,
--         operand0_out_bfy => tb_operand0_out_bfy_1,
--         operand1_out_bfy => tb_operand1_out_bfy_1,
--         operand2_out_bfy => tb_operand2_out_bfy_1,
--         operand3_out_bfy => tb_operand3_out_bfy_1,
--         operand0_addr    => tb_operand0_addr_1,
--         operand1_addr    => tb_operand1_addr_1,
--         operand2_addr    => tb_operand2_addr_1,
--         operand3_addr    => tb_operand3_addr_1);

     --instantiate the design under test for
     --16 point FFT
       U1: interconnect
         generic map (
           N_width => 5)
         port map (
           clk              => tb_clk,
           rst              => tb_rst,
           RW               => tb_RW_2,
           count0_i         => tb_count0_i_2,
           count1_i         => tb_count1_i_2,
           store0_i         => tb_store0_i_2,
           store1_i         => tb_store1_i_2,
           bfy0_add         => tb_bfy0_add_2,
           bfy0_sub         => tb_bfy0_sub_2,
           bfy1_add         => tb_bfy1_add_2,
           bfy1_sub         => tb_bfy1_sub_2,
           operand0_out_bfy => tb_operand0_out_bfy_2,
           operand1_out_bfy => tb_operand1_out_bfy_2,
           operand2_out_bfy => tb_operand2_out_bfy_2,
           operand3_out_bfy => tb_operand3_out_bfy_2,
           operand0_addr    => tb_operand0_addr_2,
           operand1_addr    => tb_operand1_addr_2,
           operand2_addr    => tb_operand2_addr_2,
           operand3_addr    => tb_operand3_addr_2);
    
       --Generate the clk signal
       CLK_PROCESS: process
         begin

           tb_clk <= not tb_clk;
           wait for half_clk_period;

       end process CLK_PROCESS;

       --generate the reset signal
       tb_rst <= '1' after 40 ns, '0' after 70 ns;

     --Test for the 16 point FFT scenario           
       --create a process to generate different combinations
       --of test inputs to the interconnect
     --    TEST_8PT_PROCESS: process
     --    begin

     --        --generate different combination of test data
     --        --and test the module U0(8 point FFT)
     --        for rw in 0 to 2 loop
     --          for ct0 in 0 to 1 loop
     --            for ct1 in 0 to 1 loop
     --              for st0 in 0 to 3 loop
     --                for st1 in 0 to 3 loop

     --                  --restrict read-write signal to
     --                  --0 and 1(binary) values only
     --                  if rw /= 2 then

     --                    --generate the read-write signal
     --                    --to be fed as input to the interconnect
     --                    if rw = 0 then
     --                      tb_RW_1 <= '0';
     --                      else
     --                        tb_RW_1 <= '1';
     --                    end if;

     --                    --generate different combinations of input
     --                    --signals to be fed into the interconnect module
     --                    tb_count0_i_1 <= conv_std_logic_vector(ct0, 1);
     --                    tb_count1_i_1 <= conv_std_logic_vector(ct1, 1);
     --                    tb_store0_i_1 <= conv_std_logic_vector(st0, 2);
     --                    tb_store1_i_1 <= conv_std_logic_vector(st1, 2);
     --                    tb_bfy0_add_1 <= bfy0_add;
     --                    tb_bfy0_sub_1 <= bfy0_sub;
     --                    tb_bfy1_add_1 <= bfy1_add;
     --                    tb_bfy1_sub_1 <= bfy1_sub;

     --                    --compute the expected output values(operand addresses) from
     --                    --the interconnect which are to be validated for correctness
     --                    if rw = 0 then
     --                      validate_operand0_addr_1 <= '0' & conv_std_logic_vector(ct0, 1);
     --                      validate_operand1_addr_1 <= '0' & conv_std_logic_vector(ct0, 1);
     --                      validate_operand2_addr_1 <= '0' & conv_std_logic_vector(ct1, 1);
     --                      validate_operand3_addr_1 <= '0' & conv_std_logic_vector(ct1, 1);
     --                      else
     --                        if ct0 = 0 then
     --                          validate_operand0_addr_1 <= conv_std_logic_vector(st0, 2);
     --                          validate_operand2_addr_1 <= conv_std_logic_vector(st0, 2);
     --                          else
     --                            validate_operand0_addr_1 <= conv_std_logic_vector(st1, 2);
     --                            validate_operand2_addr_1 <= conv_std_logic_vector(st1, 2);
     --                        end if;

     --                        if ct1 = 0 then
     --                          validate_operand1_addr_1 <= conv_std_logic_vector(st0, 2);
     --                          validate_operand3_addr_1 <= conv_std_logic_vector(st0, 2);
     --                          else
     --                            validate_operand1_addr_1 <= conv_std_logic_vector(st1, 2);
     --                            validate_operand3_addr_1 <= conv_std_logic_vector(st1, 2);
     --                        end if;
                      
     --                    end if;

     --                    --compute the expected output values(operand data) from
     --                    --the interconnect which are to be validated for correctness
     --                    if ct0 = 0 then
     --                      validate_operand0_out_bfy_1 <= bfy0_add;
     --                      validate_operand2_out_bfy_1 <= bfy0_sub;
     --                      else
     --                        validate_operand0_out_bfy_1 <= bfy1_add;
     --                        validate_operand2_out_bfy_1 <= bfy1_sub;
     --                    end if;

     --                    if ct1 = 0 then
     --                      validate_operand1_out_bfy_1 <= bfy0_add;
     --                      validate_operand3_out_bfy_1 <= bfy0_sub;
     --                      else
     --                        validate_operand1_out_bfy_1 <= bfy1_add;
     --                        validate_operand3_out_bfy_1 <= bfy1_sub;
     --                    end if;

     --                    --wait for the results to be available
     --                    --at the output of the interconnect
     --                    wait for 2 * half_clk_period;

     --                    --report error if the results of the interconnect module does
     --                    --not match with the expected values computed in the scope of
     --                    --the test bench
     --                    assert tb_operand0_addr_1 = validate_operand0_addr_1 report "Error in operand0 address computation" severity FAILURE;
     --                    assert tb_operand1_addr_1 = validate_operand1_addr_1 report "Error in operand1 address computation" severity FAILURE;
     --                    assert tb_operand2_addr_1 = validate_operand2_addr_1 report "Error in operand2 address computation" severity FAILURE;
     --                    assert tb_operand3_addr_1 = validate_operand3_addr_1 report "Error in operand3 address computation" severity FAILURE;

     --                    assert tb_operand0_out_bfy_1 = validate_operand0_out_bfy_1 report "Error in operand0 output bfy value" severity FAILURE;
     --                    assert tb_operand1_out_bfy_1 = validate_operand1_out_bfy_1 report "Error in operand1 output bfy value" severity FAILURE;
     --                    assert tb_operand2_out_bfy_1 = validate_operand2_out_bfy_1 report "Error in operand2 output bfy value" severity FAILURE;
     --                    assert tb_operand3_out_bfy_1 = validate_operand3_out_bfy_1 report "Error in operand3 output bfy value" severity FAILURE;
                
     --                  end if;                

     --                end loop;  --st1
     --              end loop;  --st0
     --            end loop;  --ct1
     --          end loop;  --ct0

     --          if rw = 2 then

     --            --successful end of all the test iterations
     --            assert end_simulation report "End of simulation" severity FAILURE;
          
     --          end if;
        
     --        end loop;  --rw

     --    end process TEST_8PT_PROCESS;

  --Test for the 16 point FFT scenario
  --create a process to generate different combinations
  --of test inputs to the interconnect
  TEST_16PT_PROCESS: process
    variable var_ct0 : std_logic_vector(1 downto 0) := (others => '0');
    variable var_ct1 : std_logic_vector(1 downto 0) := (others => '0');
  begin

      --generate different combination of test data
      --and test the module U0(8 point FFT)
      for rw in 0 to 2 loop
        for ct0 in 0 to 3 loop
          for ct1 in 0 to 3 loop
            for st0 in 0 to 7 loop
              for st1 in 0 to 7 loop

                --restrict read-write signal to
                --0 and 1(binary) values only
                if rw /= 2 then

                  --generate the read-write signal
                  --to be fed as input to the interconnect
                  if rw = 0 then
                    tb_RW_2 <= '0';
                    else
                      tb_RW_2 <= '1';
                  end if;

                  --generate different combinations of input
                  --signals to be fed into the interconnect module
                  tb_count0_i_2 <= conv_std_logic_vector(ct0, 2);
                  tb_count1_i_2 <= conv_std_logic_vector(ct1, 2);
                  tb_store0_i_2 <= conv_std_logic_vector(st0, 3);
                  tb_store1_i_2 <= conv_std_logic_vector(st1, 3);
                  tb_bfy0_add_2 <= bfy0_add;
                  tb_bfy0_sub_2 <= bfy0_sub;
                  tb_bfy1_add_2 <= bfy1_add;
                  tb_bfy1_sub_2 <= bfy1_sub;

                  var_ct0 := conv_std_logic_vector(ct0,2);                  
                  var_ct1 := conv_std_logic_vector(ct1,2);
                  
                  --compute the expected output values(operand addresses) from
                  --the interconnect which are to be validated for correctness
                  if rw = 0 then
                    validate_operand0_addr_2 <= '0' & conv_std_logic_vector(ct0, 2);
                    validate_operand1_addr_2 <= '0' & conv_std_logic_vector(ct0, 2);
                    validate_operand2_addr_2 <= '0' & conv_std_logic_vector(ct1, 2);
                    validate_operand3_addr_2 <= '0' & conv_std_logic_vector(ct1, 2);
                    else

                      if var_ct0(0) = '0' then
                        validate_operand0_addr_2 <= conv_std_logic_vector(st0, 3);
                        validate_operand2_addr_2 <= conv_std_logic_vector(st0, 3);
                        else
                          validate_operand0_addr_2 <= conv_std_logic_vector(st1, 3);
                          validate_operand2_addr_2 <= conv_std_logic_vector(st1, 3);
                      end if;


                      if var_ct1(0) = '0' then
                        validate_operand1_addr_2 <= conv_std_logic_vector(st0, 3);
                        validate_operand3_addr_2 <= conv_std_logic_vector(st0, 3);
                        else
                          validate_operand1_addr_2 <= conv_std_logic_vector(st1, 3);
                          validate_operand3_addr_2 <= conv_std_logic_vector(st1, 3);
                      end if;
                      
                  end if;

                  --compute the expected output values(operand data) from
                  --the interconnect which are to be validated for correctness
                  if var_ct0(0) = '0' then
                    validate_operand0_out_bfy_2 <= bfy0_add;
                    validate_operand2_out_bfy_2 <= bfy0_sub;
                    else
                      validate_operand0_out_bfy_2 <= bfy1_add;
                      validate_operand2_out_bfy_2 <= bfy1_sub;
                  end if;

                  if var_ct1(0) = '0' then
                    validate_operand1_out_bfy_2 <= bfy0_add;
                    validate_operand3_out_bfy_2 <= bfy0_sub;
                    else
                      validate_operand1_out_bfy_2 <= bfy1_add;
                      validate_operand3_out_bfy_2 <= bfy1_sub;
                  end if;

                  --wait for the results to be available
                  --at the output of the interconnect
                  wait for 2 * half_clk_period;

                  --report error if the results of the interconnect module does
                  --not match with the expected values computed in the scope of
                  --the test bench
                  assert tb_operand0_addr_2 = validate_operand0_addr_2 report "Error in operand0 address computation" severity FAILURE;
                  assert tb_operand1_addr_2 = validate_operand1_addr_2 report "Error in operand1 address computation" severity FAILURE;
                  assert tb_operand2_addr_2 = validate_operand2_addr_2 report "Error in operand2 address computation" severity FAILURE;
                  assert tb_operand3_addr_2 = validate_operand3_addr_2 report "Error in operand3 address computation" severity FAILURE;

                  assert tb_operand0_out_bfy_2 = validate_operand0_out_bfy_2 report "Error in operand0 output bfy value" severity FAILURE;
                  assert tb_operand1_out_bfy_2 = validate_operand1_out_bfy_2 report "Error in operand1 output bfy value" severity FAILURE;
                  assert tb_operand2_out_bfy_2 = validate_operand2_out_bfy_2 report "Error in operand2 output bfy value" severity FAILURE;
                  assert tb_operand3_out_bfy_2 = validate_operand3_out_bfy_2 report "Error in operand3 output bfy value" severity FAILURE;
                
                end if;                

              end loop;  --st1
            end loop;  --st0
          end loop;  --ct1
        end loop;  --ct0

        if rw = 2 then

          --successful end of all the test iterations
          assert end_simulation report "End of simulation" severity FAILURE;
          
        end if;
        
      end loop;  --rw

  end process TEST_16PT_PROCESS;      

end interconnect_tb_arch;
