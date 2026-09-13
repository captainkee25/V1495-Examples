-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: 
-- Device:          ALTERA EP1C4F400C6
-- Author:          Eltion Begteshi
-- Date:            April, 2010
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
		D         : inout std_logic_vector (31 DOWNTO 0);  -- In/Out D (I/O Expansion)
		E         : inout std_logic_vector (31 DOWNTO 0);  -- In/Out E (I/O Expansion)
		F         : inout std_logic_vector (31 DOWNTO 0);  -- In/Out F (I/O Expansion)
		GIN       : out   std_logic_vector ( 1 DOWNTO 0);  -- In G - LEMO (2 x NIM/TTL)
		GOUT      : out   std_logic_vector ( 1 DOWNTO 0);  -- Out G - LEMO (2 x NIM/TTL)
		IDD     	: out     std_logic_vector (2 DOWNTO 0); -- Slot D
		IDE       : out     std_logic_vector (2 DOWNTO 0); -- Slot E
		IDF       : out     std_logic_vector (2 DOWNTO 0)  -- Slot F
	);
END fpemulator ;


ARCHITECTURE behav OF fpemulator IS

begin
  
  gen_front_pannel_input:process
    
	begin
		A	<=	conv_std_logic_vector( 5, 32);
		B	<=	conv_std_logic_vector(20, 32);
		GIN	<=	"00";		-- set external clear
    wait for 20 ns;
    GIN	<=	"10";		-- set external clear
		wait for 50 ns;
		GIN	<=	"00";
		wait for 860 ns;
		GIN	<=	"01";   -- set external gate
		
		wait for 80 ns;
		A	<=	conv_std_logic_vector(7, 32);
		
		wait for 200 ns;
		GIN	<=	"00";	 -- remove external gate

		wait for 40 ns;
		B	<=	conv_std_logic_vector(65, 32);
		
		wait for 260 ns;
		GIN	<=	"10";		-- external clear
		wait for 40 ns;
		GIN	<=	"00";
		
		wait;
	
  end process gen_front_pannel_input;
  
                   
END behav;