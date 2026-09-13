-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: v1495scaler
-- Device:          ALTERA EP1C4F400C6
-- Author:          Carlo Tintori
-- Date:            May 26th, 2010
-- ----------------------------------------------------------------------------
-- Module:          V1495_Demo4
-- Description:     Top design
-- ****************************************************************************

-- ############################################################################
-- Revision History:
-- ############################################################################


library IEEE;
use IEEE.std_Logic_1164.all;
use IEEE.std_Logic_arith.all;
use IEEE.std_Logic_unsigned.all;
use work.components.all;


entity V1495_Demo4 is
	port(
    -- Front Panel Ports
    A        : IN     std_logic_vector (31 DOWNTO 0);  -- In A (32 x LVDS/ECL)
    B        : IN     std_logic_vector (31 DOWNTO 0);  -- In B (32 x LVDS/ECL)
    C        : OUT    std_logic_vector (31 DOWNTO 0);  -- Out C (32 x LVDS)
    D        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out D (I/O Expansion)
    E        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out E (I/O Expansion)
    F        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out F (I/O Expansion)
    GIN      : IN     std_logic_vector ( 1 DOWNTO 0);   -- In G - LEMO (2 x NIM/TTL)
    GOUT     : OUT    std_logic_vector ( 1 DOWNTO 0);   -- Out G - LEMO (2 x NIM/TTL)
    -- Port Output Enable (0=Output, 1=Input)
    nOED     : OUT    std_logic;                       -- Output Enable Port D (only for A395D)
    nOEE     : OUT    std_logic;                       -- Output Enable Port E (only for A395D)
    nOEF     : OUT    std_logic;                       -- Output Enable Port F (only for A395D)
    nOEG     : OUT    std_logic;                       -- Output Enable Port G
    -- Port Level Select (0=NIM, 1=TTL)
    SELD     : OUT    std_logic;                       -- Output Level Select Port D (only for A395D)
    SELE     : OUT    std_logic;                       -- Output Level Select Port E (only for A395D)
    SELF     : OUT    std_logic;                       -- Output Level Select Port F (only for A395D)
    SELG     : OUT    std_logic;                       -- Output Level Select Port G

    -- Expansion Mezzanine Identifier:
    -- 000 : A395A (32 x IN LVDS/ECL)
    -- 001 : A395B (32 x OUT LVDS)
    -- 010 : A395C (32 x OUT ECL)
    -- 011 : A395D (8  x IN/OUT NIM/TTL)
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

    -- Spare
    SPARE    : INOUT  std_logic_vector (11 DOWNTO 0);

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

END V1495_Demo4 ;


architecture rtl of V1495_Demo4 is

	--------------------------
	------- SIGNALS ----------
	--------------------------
	signal REG_R1     			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal REG_R2     			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal REG_R3     			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal REG_R4     			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal REG_R5     			: std_logic_vector(31 downto 0) := (others => 'Z');
  signal REG_R6     			: std_logic_vector(31 downto 0) := (others => 'Z');
	
	signal REG_RW1     			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal REG_RW2     			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal REG_RW3     			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal REG_RW4     			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal REG_RW5     			: std_logic_vector(31 downto 0) := (others => 'Z');
  signal REG_RW6     			: std_logic_vector(31 downto 0) := (others => 'Z');
  signal REG_RW7     			: std_logic_vector(31 downto 0) := (others => 'Z');
  
	-- Data Producer signals
  signal wr_dly_cmd       : std_logic_vector( 1 downto 0) := (others => '0');
  signal wr_dly           : std_logic_vector( 1 downto 0) := (others => '0');
	signal input_A_mask     : std_logic_vector(31 downto 0) := (others => 'Z');
	signal input_B_mask			: std_logic_vector(31 downto 0) := (others => 'Z');
	signal ctrlreg     		  : std_logic_vector(31 downto 0) := (others => 'Z');  
  signal D_Expan     			: std_logic_vector(31 downto 0) := (others => 'Z');
  
begin
  -- Port Output Enable (0=Output, 1=Input)
  nOED  <=  '0';    -- Output Enable Port D (only for A395D)
	nOEG  <=  '1';    -- Output Enable Port G
  D     <=  D_Expan	when IDD = "011"  else (others => 'Z');
  
  
  nOEDDLY0  <=  '0';  -- Output Enable for PDL0 (active low)
  nOEDDLY1  <=  '0';  -- Output Enable for PDL1 (active low)
  
  -- Port Level Select (0=NIM, 1=TTL)
  SELD      <=  ctrlreg(0);    -- Output Level Select Port D (only for A395D)
  SELG      <=  ctrlreg(1);    -- Output Level Select Port G

  DIRDDLY   <=  ctrlreg(4);  -- Direction of PDL data (0 => Read Dip Switches)
                              --                       (1 => Write from FPGA)                           
  WR_DLY0   <=  wr_dly(0);
  WR_DLY1   <=  wr_dly(1);
  
  ctrlreg	  <= REG_RW3;
  
 
  -- REG_R6  -->  |    ------ 24 bit ------   --4bit--4bit-|       
  -- REG_R6  -->  | ... obligatory '0'  ...    |  0  |  0  |
  REG_R6(3 downto 0)   <= conv_std_logic_vector(1, 4);  -- Firmware release
  REG_R6(7 downto 4)   <= conv_std_logic_vector(4, 4);  -- Demo number
  REG_R6(31 downto 8)  <= (others => '0');
  
  
  instance_gdgen: gdgen
    port map(
      lclk     			=> LCLK,
      GIN           => GIN,
      ctrlreg       => ctrlreg,
      pulse         => pulse,
      wr_dly_cmd    => wr_dly_cmd,
      wr_dly        => wr_dly,
      ddly          => DDLY,
      start	        => START,
      nstart	      => nSTART,
      out_pgdl	    => D_Expan(29),
      out_fgdl	    => D_Expan(0),
      delay_pdl     => REG_RW6(7 downto 0),
      gate_pdl      => REG_RW7(7 downto 0),
      delay_fdl     => REG_RW4,
      gate_fdl      => REG_RW5
    );
    
    instance_LB_INT: LB_INT 
		port map (
			-- Local Bus in/out signals
			nLBRES      => nLBRES,
			nBLAST      => nBLAST,   
			WnR         => WnR,      
			nADS        => nADS,     
			LCLK        => LCLK,     
			nREADY      => nREADY,   
			nINT        => nINT,     
			LAD         => LAD,
      WR_DLY_CMD  => WR_DLY_CMD,
			-- Internal Registers
			REG_R1     => REG_R1,
			REG_R2     => REG_R2,
			REG_R3     => REG_R3,
			REG_R4     => REG_R4,
			REG_R5     => REG_R5,
      REG_R6     => REG_R6,
      
			REG_RW1    => REG_RW1,
			REG_RW2    => REG_RW2,
			REG_RW3    => REG_RW3,
			REG_RW4    => REG_RW4,
			REG_RW5    => REG_RW5,
      REG_RW6    => REG_RW6,
      REG_RW7    => REG_RW7
		);
   
 
end rtl;
   