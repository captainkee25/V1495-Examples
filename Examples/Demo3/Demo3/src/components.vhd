-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- Device:          ALTERA EP1C4F400C6
-- Author:          Eltion Begteshi
-- Date:            April 13th, 2009
-- ----------------------------------------------------------------------------
-- Module:          components
-- Description:     This file contains declarations header of all components
-- ****************************************************************************

-- NOTE: 
-- ****************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

PACKAGE components is

  
  component dac_int is
    port(

     nLBRES     : IN     std_logic;
     LCLK       : IN     std_logic;

     DAC_DATA   : in     std_logic_vector (15 DOWNTO 0);  
     DAC_CH     : in     std_logic_vector (3 DOWNTO 0);  
     DAC_WR     : in     std_logic;
     nLDACin    : in     std_logic;
     DAC_TST    : in     std_logic;

    -- DAC SPI
     SCK        : out    std_logic;
     nCSDAC     : out    std_logic;
     SDI        : out    std_logic;
     nLDAC      : out    std_logic

    );

  end component;


  component lb_int is
   port(
    -- Local Bus in/out signals
    nLBRES     : IN     std_logic;
    nBLAST     : IN     std_logic;
    WnR        : IN     std_logic;
    nADS       : IN     std_logic;
    LCLK       : IN     std_logic;
    nREADY     : OUT    std_logic;
    nINT       : OUT    std_logic;
    LAD        : INOUT  std_logic_vector (15 DOWNTO 0);

    DAC_DATA   : OUT    std_logic_vector (15 DOWNTO 0);  
    DAC_CH     : OUT    std_logic_vector (3 DOWNTO 0);  
    DAC_TST    : OUT    std_logic;

    DAC_WRD    : OUT    std_logic;
    DAC_WRE    : OUT    std_logic;
    DAC_WRF    : OUT    std_logic;
    nLDACinD   : OUT    std_logic;
    nLDACinE   : OUT    std_logic;
    nLDACinF	  : OUT    std_logic;

    -- LED drivers
    nLEDG	: OUT    std_logic;                       -- Green (active low)
    nLEDR	: OUT    std_logic;                       -- Red (active low)

    IDD	  : IN     std_logic_vector (2 DOWNTO 0);   -- Slot D
    IDE	  : IN     std_logic_vector (2 DOWNTO 0);   -- Slot E
    IDF	  : IN     std_logic_vector (2 DOWNTO 0)   -- Slot F
   );
  end component;
  
  
  

	
	
	component V1495_Demo3 is
		port(
      -- Front Panel Ports
      A        : IN     std_logic_vector (31 DOWNTO 0);  -- In A (32 x LVDS/ECL)
      B        : IN     std_logic_vector (31 DOWNTO 0);  -- In B (32 x LVDS/ECL)
      C        : OUT    std_logic_vector (31 DOWNTO 0);  -- Out C (32 x LVDS)
      D        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out D (I/O Expansion)
      E        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out E (I/O Expansion)
      F        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out F (I/O Expansion)
      GIN      : IN     std_logic_vector (1 DOWNTO 0);   -- In G - LEMO (2 x NIM/TTL)
      GOUT     : OUT    std_logic_vector (1 DOWNTO 0);   -- Out G - LEMO (2 x NIM/TTL)
      -- Port Output Enable (0=Output, 1=Input)
      nOED     : OUT    std_logic;                       -- Output Enable Port D (only for A395D)
      nOEE     : OUT    std_logic;                       -- Output Enable Port E (only for A395D)
      nOEF     : OUT    std_logic;                       -- Output Enable Port F (only for A395D)
      nOEG     : OUT    std_logic;                       -- Output Enable Port G
      -- Port Level Select (1=NIM, 0=TTL)
      SELD     : OUT    std_logic;                       -- Output Level Select Port D (only for A395D)
      SELE     : OUT    std_logic;                       -- Output Level Select Port E (only for A395D)
      SELF     : OUT    std_logic;                       -- Output Level Select Port F (only for A395D)
      SELG     : OUT    std_logic;                       -- Output Level Select Port G

      -- Expansion Mezzanine Identifier:
      -- 000 : A395A (32 x IN LVDS/ECL)
      -- 001 : A395B (32 x OUT LVDS)
      -- 010 : A395C (32 x OUT ECL)
      -- 011 : A395D (8  x IN/OUT NIM/TTL)
      -- 100 : A395E (8  x DAC)

      IDD      : IN     std_logic_vector (2 DOWNTO 0);   -- Slot D
      IDE      : IN     std_logic_vector (2 DOWNTO 0);   -- Slot E
      IDF      : IN     std_logic_vector (2 DOWNTO 0);   -- Slot F

      -- Delay Lines
      -- 0:1 => PDL (Programmable Delay Line): Step = 0.25ns / FSR = 64ns
      -- 2:3 => FDL (Free Running Delay Line with fixed delay)
      PULSE    : IN     std_logic_vector (3 DOWNTO 0);   -- Output of the delay line (0:1 => PDL; 2:3 => FDL)
      nSTART   : OUT    std_logic_vector (3 DOWNTO 2);   -- Start of FDL (active low)
      START    : OUT    std_logic_vector (1 DOWNTO 0);   -- Input of PDL (active high)
      DDLY     : INOUT  std_logic_vector (7 DOWNTO 0);   -- R/W Data for the PDL
      WR_DLY0  : OUT    std_logic;                       -- Write signal for the PDL0
      WR_DLY1  : OUT    std_logic;                       -- Write signal for the PDL1
      DIRDDLY  : OUT    std_logic;                       -- Direction of PDL data (0 => Read Dip Switches)
                                                         --                       (1 => Write from FPGA)
      nOEDDLY0 : OUT    std_logic;                       -- Output Enable for PDL0 (active low)
      nOEDDLY1 : OUT    std_logic;                       -- Output Enable for PDL1 (active low)

      -- LED drivers
      nLEDG    : OUT    std_logic;                       -- Green (active low)
      nLEDR    : OUT    std_logic;                       -- Red (active low)

      -- Local Bus in/out signals
      nLBRES     : IN     std_logic;
      nBLAST     : IN     std_logic;
      WnR        : IN     std_logic;
      nADS       : IN     std_logic;
      LCLK       : IN     std_logic;
      nREADY     : OUT    std_logic;
      nINT       : OUT    std_logic;
      LAD        : INOUT  std_logic_vector (15 DOWNTO 0)
		);
	end component V1495_Demo3;
  
  component lbemulator is
  port(
      nLBRES     : out    std_logic;
      nBLAST     : out    std_logic;
      WnR        : out    std_logic;
      nADS       : out    std_logic;
      LCLK       : in			std_logic;
      nREADY     : in     std_logic;
      nINT       : in     std_logic;
      LAD        : inout  std_logic_vector (15 DOWNTO 0) 
	);
	end component lbemulator ;
	
	

END components;