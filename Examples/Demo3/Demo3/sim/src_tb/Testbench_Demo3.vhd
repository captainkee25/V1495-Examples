-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- Device:          ALTERA EP1C4F400C6
-- Author:          Eltion Begteshi
-- Date:            April, 2010
-- ----------------------------------------------------------------------------
-- Module:          Testbench_Demo3
-- Description:     Testbench top design
-- ****************************************************************************

-- ############################################################################
-- Revision History:
-- ############################################################################


library IEEE;
use IEEE.std_Logic_1164.all;
use IEEE.std_Logic_arith.all;
use IEEE.std_Logic_unsigned.all;
use work.components.all;

entity Testbench_Demo3 IS
end entity Testbench_Demo3;


architecture bhv of Testbench_Demo3 is

	---------------------
	------ Constants ----
	---------------------	
	constant SYS_CLK_PERIOD			: time	 	:= 25 ns;
	constant SIM_LENGTH					: integer := 950;
	constant RESET_CYCLE 				: integer := 2;
	
	
	---------------------
	------ Signals ------
	---------------------
	-- Front Panel Ports
  signal A        : std_logic_vector (31 DOWNTO 0);  -- In A (32 x LVDS/ECL)
  signal B        : std_logic_vector (31 DOWNTO 0);  -- In B (32 x LVDS/ECL)
  signal C        : std_logic_vector (31 DOWNTO 0);  -- Out C (32 x LVDS)
  signal D        : std_logic_vector (31 DOWNTO 0);  -- In/Out D (I/O Expansion)
  signal E        : std_logic_vector (31 DOWNTO 0);  -- In/Out E (I/O Expansion)
  signal F        : std_logic_vector (31 DOWNTO 0);  -- In/Out F (I/O Expansion)
  signal GIN      : std_logic_vector ( 1 DOWNTO 0);   -- In G - LEMO (2 x NIM/TTL)
  signal GOUT     : std_logic_vector ( 1 DOWNTO 0);   -- Out G - LEMO (2 x NIM/TTL)
    -- Port Output Enable (0=Output, 1=Input)
  signal nOED     : std_logic;                       -- Output Enable Port D (only for A395D)
  signal nOEE     : std_logic;                       -- Output Enable Port E (only for A395D)
  signal nOEF     : std_logic;                       -- Output Enable Port F (only for A395D)
  signal nOEG     : std_logic;                       -- Output Enable Port G
    -- Port Level Select (0=NIM, 1=TTL)
  signal SELD     : std_logic;                       -- Output Level Select Port D (only for A395D)
  signal SELE     : std_logic;                       -- Output Level Select Port E (only for A395D)
  signal SELF     : std_logic;                       -- Output Level Select Port F (only for A395D)
  signal SELG     : std_logic;                       -- Output Level Select Port G

    -- Expansion Mezzanine Identifier:
    -- 000 : A395A (32 x IN LVDS/ECL)
    -- 001 : A395B (32 x OUT LVDS)
    -- 010 : A395C (32 x OUT ECL)
    -- 011 : A395D (8  x IN/OUT NIM/TTL)
  signal IDD      : std_logic_vector (2 DOWNTO 0);   -- Slot D
  signal IDE      : std_logic_vector (2 DOWNTO 0);   -- Slot E
  signal IDF      : std_logic_vector (2 DOWNTO 0);   -- Slot F

    -- Delay Lines
    -- 0:1 => PDL (Programmable Delay Line): Step = 0.25ns / FSR = 64ns
    -- 2:3 => FDL (Free Running Delay Line with fixed delay)
  signal PULSE    : std_logic_vector (3 DOWNTO 0) := (others => '0');   -- Output of the delay line (0:1 => PDL; 2:3 => FDL)
  signal nSTART   : std_logic_vector (3 DOWNTO 2);   -- Start of FDL (active low)
  signal START    : std_logic_vector (1 DOWNTO 0);   -- Input of PDL (active high)
  signal DDLY     : std_logic_vector (7 DOWNTO 0);   -- R/W Data for the PDL
  signal WR_DLY0  : std_logic;                       -- Write signal for the PDL0
  signal WR_DLY1  : std_logic;                       -- Write signal for the PDL1
  signal DIRDDLY  : std_logic;                       -- Direction of PDL data (0 => Read Dip Switches)
                                                            --                       (1 => Write from FPGA)
  signal nOEDDLY0 : std_logic;                       -- Output Enable for PDL0 (active low)
  signal nOEDDLY1 : std_logic;                       -- Output Enable for PDL1 (active low)

    -- LED drivers
  signal  nLEDG    : std_logic;                       -- Green (active low)
  signal  nLEDR    : std_logic;                       -- Red (active low)

	-- Local Bus in/out signals
	signal nLBRES    : std_logic := '1';
	signal nBLAST    : std_logic := '1';
	signal WnR       : std_logic := '1';
	signal nADS      : std_logic := '1';
	signal nREADY    : std_logic := '1';
	signal nINT      : std_logic := '1';
	signal LAD       : std_logic_vector (15 DOWNTO 0);
	
	
  -- DAC interface signals
  
  -- signal DAC_DATA   : std_logic_vector (15 DOWNTO 0);  
  -- signal DAC_CH     : std_logic_vector (3 DOWNTO 0);  
  -- signal DAC_WR     : std_logic;
  -- signal nLDACin    : std_logic;
  -- signal DAC_TST    : std_logic;

  -- -- DAC SPI
  -- signal SCK        : std_logic;
  -- signal nCSDAC     : std_logic;
  -- signal SDI        : std_logic;
  -- signal nLDAC      : std_logic
  
  
	-- Control signals --
	signal LCLK								: std_logic	:= '1';
	signal go									: boolean	:= True;
	signal clk_counter				: integer 	:= 0;
	signal clk_double_counter	: integer 	:= 0;
  
  
  
		
	
begin
	
	-------------------------------
	-- Building Clock Signals -----
	-------------------------------
	LCLK	<=	NOT LCLK	AFTER	(SYS_CLK_PERIOD/2)	WHEN	(go = true)	ELSE LCLK;
	go		<=	false WHEN (clk_counter = SIM_LENGTH);
	
	-- counting the number of elapsed clock cycles --
	counting_cycles : PROCESS (LCLK)
	BEGIN
		IF (LCLK'event) THEN
			clk_double_counter <= clk_double_counter + 1;
			IF (LCLK = '1') THEN
				clk_counter <= clk_counter + 1;
			END IF;
		END IF;
	END PROCESS counting_cycles;
	

	
	
	
	instance_top_level: V1495_Demo3
	port map(
    -- Front Panel Ports
		A        => A,  												-- In A (32 x LVDS/ECL)
		B        => B,  												-- In B (32 x LVDS/ECL)
		C        => C,  												-- Out C (32 x LVDS)
		D        => D, 												 	-- In/Out D (I/O Expansion)
		E        => E,  												-- In/Out E (I/O Expansion)
		F        => F,  												-- In/Out F (I/O Expansion)
		GIN      => GIN,   											-- In G - LEMO (2 x NIM/TTL)
		GOUT     => GOUT,   										-- Out G - LEMO (2 x NIM/TTL)
		-- Port Output Enable (0=Output, 1=Input)
		nOED     => nOED,                       -- Output Enable Port D (only for A395D)
		nOEE     => nOEE,                       -- Output Enable Port E (only for A395D)
		nOEF     => nOEF,                       -- Output Enable Port F (only for A395D)
		nOEG     => nOEG,                      	-- Output Enable Port G
		-- -- Port Level Select (0=NIM, 1=TTL)
		SELD     => SELD,                       -- Output Level Select Port D (only for A395D)
		SELE     => SELE,                       -- Output Level Select Port E (only for A395D)
		SELF     => SELF,                       -- Output Level Select Port F (only for A395D)
		SELG     => SELG,                       -- Output Level Select Port G

		-- Expansion Mezzanine Identifier:
		-- 000 : A395A (32 x IN LVDS/ECL)
		-- 001 : A395B (32 x OUT LVDS)
		-- 010 : A395C (32 x OUT ECL)
		-- 011 : A395D (8  x IN/OUT NIM/TTL)
		IDD      => IDD,   -- Slot D
		IDE      => IDE,   -- Slot E
		IDF      => IDF,   -- Slot F

    -- Delay Lines
    -- 0:1 => PDL (Programmable Delay Line): Step = 0.25ns / FSR = 64ns
    -- 2:3 => FDL (Free Running Delay Line with fixed delay)
    PULSE    => PULSE,    -- Output of the delay line (0:1 => PDL; 2:3 => FDL)
    nSTART   => nSTART,   -- Start of FDL (active low)
    START    => START,    -- Input of PDL (active high)
    DDLY     => DDLY,     -- R/W Data for the PDL
    WR_DLY0  => WR_DLY0,                  -- Write signal for the PDL0
    WR_DLY1  => WR_DLY1,                  -- Write signal for the PDL1
    DIRDDLY  => DIRDDLY,                  -- Direction of PDL data (0 => Read Dip Switches)
                                          --                       (1 => Write from FPGA)
    nOEDDLY0 => nOEDDLY0,                 -- Output Enable for PDL0 (active low)
    nOEDDLY1 => nOEDDLY1,                 -- Output Enable for PDL1 (active low)

		-- -- LED drivers
		nLEDG    => nLEDG,                    -- Green (active low)
		nLEDR    => nLEDR,                    -- Red (active low)

		-- Local Bus in/out signals
		nLBRES			=> nLBRES,
		nBLAST      => nBLAST,
		WnR         => WnR,
		nADS        => nADS,
		LCLK        => LCLK,
		nREADY      => nREADY,
		nINT        => nINT,
		LAD         => LAD
	);
	
	
	-- instance_fpemulator: fpemulator
	-- port map(
		-- -- Front Panel Ports
		-- LCLK				=> LCLK,
		-- A         	=> A,  		-- In A (32 x LVDS/ECL)
		-- B         	=> B,  		-- In B (32 x LVDS/ECL)
		-- GIN      		=> GIN    -- In G - LEMO (2 x NIM/TTL)
	-- );

	instance_lbemulator: lbemulator
  port map(
		nLBRES			=> nLBRES,
		nBLAST      => nBLAST,
		WnR         => WnR,
		nADS        => nADS,
		LCLK        => LCLK,
		nREADY      => nREADY,
		nINT        => nINT,
		LAD         => LAD
	);


end architecture bhv;
