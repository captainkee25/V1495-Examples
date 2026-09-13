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

			--   GIN(0)  --> ext_gate,
			--   GIN(1)  --> ext_clear,
  constant  P : time  :=  25 ns;    

begin
  
  gen_front_pannel_input:process
    
	begin
		A	<=	conv_std_logic_vector( 1024, 32);
		B	<=	conv_std_logic_vector(20, 32);
		GIN	<=	"00";		
    wait for 2*P;
    GIN	<=	"01";		-- set external reset
		wait for 5*P;
		GIN	<=	"00";
	
		wait for 5*P;
		A	<=	conv_std_logic_vector(7, 32);
    wait for 1*P;
    A	<=	conv_std_logic_vector(8, 32);
    
    wait for 45*P;
		GIN	<=	"10";   -- Start acquisition
    --wait until rising_edge(LCLK);
    --GIN	<=	"00";	 -- Stop acquisition
    
    for i in 2 to 22 loop
      A	<=	conv_std_logic_vector(i, 32);
      wait until rising_edge(LCLK);
      --GIN	<=	"00";	 -- Stop acquisition
    end loop; 
    
    wait for 5*P;
    --GIN	<=	"00";	 -- Stop acquisition    
    
    wait for 3*P;
    A	<=	conv_std_logic_vector(88, 32);
		
		wait for 5*P;
		GIN	<=	"00";	 -- Stop acquisition

		wait for 2*P;
		B	<=	conv_std_logic_vector(65, 32);
		
		wait for 50*P;
		GIN	<=	"01";		-- external reset
		wait for 2*P;
		GIN	<=	"00";
		
		wait;
	
  end process gen_front_pannel_input;
  
                   
END behav;