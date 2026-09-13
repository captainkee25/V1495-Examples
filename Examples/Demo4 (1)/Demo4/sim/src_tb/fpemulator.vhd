-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: v1495scaler
-- Device:          ALTERA EP1C4F400C6
-- Author:          Eltion Begteshi
-- Date:            Jan 26th, 2010
-- ----------------------------------------------------------------------------
-- Module:          fpemulator
-- Description:     Front Pannel I/O emulator
-- ****************************************************************************

-- ############################################################################
-- Revision History:
-- ############################################################################

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;

ENTITY fpemulator IS
	PORT(
		-- Front Panel Ports
		LCLK			: in std_logic;
		A         : out		std_logic_vector (31 DOWNTO 0);  -- In A (32 x LVDS/ECL)
		B         : out 	std_logic_vector (31 DOWNTO 0);  -- In B (32 x LVDS/ECL)	
		GIN       : out   std_logic_vector ( 1 DOWNTO 0)   -- In G - LEMO (2 x NIM/TTL)
	);
END fpemulator ;


ARCHITECTURE behav OF fpemulator IS

	alias ext_areset      : std_logic is GIN(0);
  alias start_gdl       : std_logic is GIN(1);

  constant  P : time  :=  10 ns;    

begin
  
  gen_front_pannel_input:process
    
	begin
 
 
    start_gdl      <= '0';
    ext_areset <= '1';

    wait for 1 ns;
    ext_areset <= '0';
    
    wait for 10*P;

   
    start_gdl <= '1';  -- 1st pulse
    wait for 30 ns; --2
    start_gdl <= '0';

    wait for 8 ns;    -- 2nd pulse
    start_gdl <= '1';
    wait for 8 ns;
    start_gdl <= '0';

    wait for 7 ns;    -- 3rd pulse
    start_gdl <= '1';
    wait for 2 ns;
    start_gdl <= '0';
   
    -- wait for 2 ns;
    -- ext_areset <= '1';
    -- wait for 1 ns;
    -- ext_areset <= '0';
    
    wait for 25 ns;    -- 4th pulse
    start_gdl <= '1';
    wait for 4 ns;
    start_gdl <= '0';
    
    wait for 20 ns;    -- 5th pulse
    start_gdl <= '1';
    wait for 15 ns;
    start_gdl <= '0';
    
     wait for 18 ns;    -- 6th pulse
    start_gdl <= '1';
    wait for 10 ns;
    start_gdl <= '0';
     
    wait;
	
  end process gen_front_pannel_input;
  
                   
END behav;