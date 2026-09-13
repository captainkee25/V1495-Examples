-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- Device:          ALTERA EP1C4F400C6
-- Author:          Carlo Tintori
-- Date:            May 26th, 2010
-- ----------------------------------------------------------------------------
-- Module:          lb_int
-- Description:     Local Bus interface
-- ****************************************************************************

-- NOTE: this is just an example of interface between the user FPGA and the
-- local bus on the V1495. In this example, there are 5 registers called REG_R1,
-- REG_R2, REG_R3, REG_R4 and REG_R5 that can be only read and there are 5 registers 
-- called REG_RW1, REG_RW2, REG_RW3, REG_RW4 and REG_RW5 that can be written and 
-- read from the VME (through the local bus). The registers are 32 bit wide and can
-- be accessed in single mode.
-- There is also a FIFO for the data readout; this is also 32 bit wide and can
-- be read in either single D32 read or Block Transfer Read.

library ieee;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;

ENTITY LB_INT is
	port(
		-- Local Bus in/out signals
		nLBRES     : in   	std_logic;
		nBLAST     : in   	std_logic;
		WnR        : in   	std_logic;
		nADS       : in   	std_logic;
		LCLK       : in   	std_logic;
		nREADY     : out 	 	std_logic;
		nINT       : out	  std_logic;
		LAD        : inout  std_logic_vector(15 DOWNTO 0);
    WR_DLY_CMD : out	  std_logic_vector( 1 DOWNTO 0);
		
		-- Internal Registers
		REG_R1     : in std_logic_vector(31 downto 0);
		REG_R2     : in std_logic_vector(31 downto 0);
		REG_R3     : in std_logic_vector(31 downto 0);
		REG_R4     : in std_logic_vector(31 downto 0);
		REG_R5     : in std_logic_vector(31 downto 0);
    REG_R6     : in std_logic_vector(31 downto 0);
    
    REG_RW1    : buffer std_logic_vector(31 downto 0);
		REG_RW2    : buffer std_logic_vector(31 downto 0);
		REG_RW3    : buffer std_logic_vector(31 downto 0);
		REG_RW4    : buffer std_logic_vector(31 downto 0);
		REG_RW5    : buffer std_logic_vector(31 downto 0);
    REG_RW6    : buffer std_logic_vector(31 downto 0);
    REG_RW7    : buffer std_logic_vector(31 downto 0)
	);

END LB_INT ;


ARCHITECTURE rtl of LB_INT is

	-- States of the finite state machine
	type   LBSTATE_type is (LBIDLE, LBWRITEL, LBWRITEH, LBREADL, LBREADH);
	signal LBSTATE : LBSTATE_type;
	
	-- Output Enable of the LAD bus (from User to Vme)
	signal LADoe     : std_logic;
	-- Data Output to the local bus
	signal LADout    : std_logic_vector(15 downto 0);
	-- Lower 16 bits of the 32 bit data
	signal DTL       : std_logic_vector(15 downto 0);
	-- Address latched from the LAD bus
	signal ADDR      : std_logic_vector(15 downto 0);

	
	
	-- Register Address Map

	constant A_REG_R1   : std_logic_vector(15 downto 0) := X"1030";
	constant A_REG_R2   : std_logic_vector(15 downto 0) := X"1034";
	constant A_REG_R3   : std_logic_vector(15 downto 0) := X"1038";
	constant A_REG_R4   : std_logic_vector(15 downto 0) := X"103C";
	constant A_REG_R5   : std_logic_vector(15 downto 0) := X"1040"; 
  constant A_REG_R6   : std_logic_vector(15 downto 0) := X"100C"; 
  
	constant A_REG_RW1  : std_logic_vector(15 downto 0) := X"1010";
	constant A_REG_RW2  : std_logic_vector(15 downto 0) := X"1014";
	constant A_REG_RW3  : std_logic_vector(15 downto 0) := X"1018";
	constant A_REG_RW4  : std_logic_vector(15 downto 0) := X"101C";
	constant A_REG_RW5  : std_logic_vector(15 downto 0) := X"1020";
  constant A_REG_RW6  : std_logic_vector(15 downto 0) := X"1024";
  constant A_REG_RW7  : std_logic_vector(15 downto 0) := X"1028";

begin
	
	LAD	<= LADout when LADoe = '1' else (others => 'Z');
	
  -- Local bus FSM
  process(LCLK, nLBRES)
		variable rreg, wreg   : std_logic_vector(31 downto 0);
  begin
    if (nLBRES = '0') then
      REG_RW1     <= (others => '1');
      REG_RW2     <= (others => '0');
      REG_RW3     <= X"00000013";    --Default value
			REG_RW4     <= X"0000004F";    --Default value
			REG_RW5     <= X"0000000F";    --Default value
      REG_RW6     <= X"00000000";    --Default value
      REG_RW7     <= X"00000000";    --Default value
      nREADY      <= '1';
      LADoe       <= '0';
      ADDR        <= (others => '0');
      DTL         <= (others => '0');
      LADout      <= (others => '0');
      rreg        := (others => '0');
      wreg        := (others => '0');
      LBSTATE     <= LBIDLE;
    elsif rising_edge(LCLK) then

      case LBSTATE is
      
        when LBIDLE  =>  
          LADoe   <= '0';
					nREADY  <= '1';
          WR_DLY_CMD  <= (others => '0');
          if (nADS = '0') then        -- Start cycle
            ADDR <= LAD;              -- Address Sampling
            if (WnR = '1') then       -- Write Access to the registers
              nREADY   <= '0';
              LBSTATE  <= LBWRITEL;     
            else                      -- Read Access to the registers
              nREADY   <= '1';
              LBSTATE  <= LBREADL;
            end if;
          end if;

        when LBWRITEL => 
          DTL <= LAD;  -- Save the lower 16 bits of the data
          if (nBLAST = '0') then
            LBSTATE  <= LBIDLE;
            nREADY   <= '1';
          else
            LBSTATE  <= LBWRITEH;
          end if;
                         
        when LBWRITEH =>   
          wreg  := LAD & DTL;  -- Get the higher 16 bits and create the 32 bit data
          case ADDR is
            when A_REG_RW1          => REG_RW1       <= wreg;
            when A_REG_RW2          => REG_RW2       <= wreg;
            when A_REG_RW3          => REG_RW3       <= wreg;
            when A_REG_RW4          => REG_RW4       <= wreg;
						when A_REG_RW5          => REG_RW5       <= wreg;
            when A_REG_RW6          => REG_RW6       <= wreg;
                                       WR_DLY_CMD(0) <= '1';
            when A_REG_RW7          => REG_RW7       <= wreg;
                                       WR_DLY_CMD(1) <= '1';
            when others          => null;
          end case;
          nREADY   <= '1';
          LBSTATE  <= LBIDLE;

        when LBREADL =>  
          nREADY    <= '0';  -- Assuming that the register is ready for reading
          case ADDR is
            when A_REG_R6          => rreg := REG_R6;
						when A_REG_RW1         => rreg := REG_RW1;
						when A_REG_RW2				 => rreg := REG_RW2;
						when A_REG_RW3         => rreg := REG_RW3;
						when A_REG_RW4         => rreg := REG_RW4;
						when A_REG_RW5         => rreg := REG_RW5;
            when A_REG_RW6         => rreg := REG_RW6;
            when A_REG_RW7         => rreg := REG_RW7;
            when others          => null;
          end case;
          LBSTATE  <= LBREADH;
          LADout <= rreg(15 downto 0);  -- Save the lower 16 bits of the data
          LADoe  <= '1';  -- Enable the output on the Local Bus
          
        when LBREADH =>  
          LADout  <= rreg(31 downto 16);  -- put the higher 16 bits
          LBSTATE <= LBIDLE;
     
		 end case;

    end if;
  end process;

END rtl;



