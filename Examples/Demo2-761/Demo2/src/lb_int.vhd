-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: Demo 2
-- Device:          ALTERA EP1C4F400C6
-- Author:          Carlo Tintori
-- Date:            May 26th, 2010
-- ----------------------------------------------------------------------------
-- Module:          lb_int
-- Description:     registers and local bus interface
-- ****************************************************************************

-- ############################################################################
-- Revision History:
-- ############################################################################

library ieee;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;


entity lb_int is
   port(
      -- Local Bus in/out signals
      nLBRES     : in     std_logic;
      nBLAST     : in     std_logic;
      WnR        : in     std_logic;
      nADS       : in     std_logic;
      LCLK       : in     std_logic;
      nREADY     : out    std_logic;
      nINT       : out    std_logic;
      LAD        : inout  std_logic_vector(15 downto 0);
      REG_STATUS : in	  	std_logic_vector(31 downto 0);
      -- FIFO in/out signals
      meb_dto    : in     std_logic_vector(31 downto 0);
      meb_rd     : out    std_logic;
      meb_rdempty: in     std_logic;
      meb_rdusedw: in     std_logic_vector (11 downto 0);
      
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
      REG_RW5    : buffer std_logic_vector(31 downto 0)
   );

end lb_int ;


architecture rtl of lb_int is

  type   LBSTATE_type is (LBIDLE, LBWRITEL, LBWRITEH, LBREADL, LBREADH, LBREADMEBL, LBREADMEBH);
  signal LBSTATE : LBSTATE_type;

  signal MEB_RDi   : std_logic;
  signal MEB_AE    : std_logic;
  

	-- Output Enable of the LAD bus (from User to Vme)
	signal LADoe     : std_logic;
	-- Data Output to the local bus
	signal LADout    : std_logic_vector(15 downto 0);
	-- Lower 16 bits of the 32 bit data
	signal DTL       : std_logic_vector(15 downto 0);
	-- Address latched from the LAD bus
	signal ADDR      : std_logic_vector(15 downto 0);
  
  alias blt_ready  : std_logic is REG_STATUS(0);
  
  
  	-- Register Address Map
	constant A_REG_R1   : std_logic_vector(15 downto 0) := X"1030";
	constant A_REG_R2   : std_logic_vector(15 downto 0) := X"1034";
	constant A_REG_R3   : std_logic_vector(15 downto 0) := X"1038";
	constant A_REG_R4   : std_logic_vector(15 downto 0) := X"103C";
	constant A_REG_R5   : std_logic_vector(15 downto 0) := X"1040";
  constant A_REG_R6   : std_logic_vector(15 downto 0) := X"100C";  -- Firmware Release
	
	constant A_REG_RW1  : std_logic_vector(15 downto 0) := X"1010";
	constant A_REG_RW2  : std_logic_vector(15 downto 0) := X"1014";
	constant A_REG_RW3  : std_logic_vector(15 downto 0) := X"1018";
	constant A_REG_RW4  : std_logic_vector(15 downto 0) := X"101C";
	constant A_REG_RW5  : std_logic_vector(15 downto 0) := X"1020";
  
  constant A_MEB      : std_logic_vector(15 downto 0) := X"0000";
  
  constant A_REG_STATUS  : std_logic_vector(15 downto 0) := X"1050";

begin

  meb_rd  <= MEB_RDi and not meb_rdempty;

  LAD    <= LADout when LADoe = '1' else (others => 'Z');
  

  -- Local bus FSM
  process(LCLK, nLBRES)
  variable rreg, wreg   : std_logic_vector(31 downto 0);
  begin
    if (nLBRES = '0') then
      REG_RW1     <= (others => '1'); --Default value 
      REG_RW2     <= (others => '0');
      REG_RW3     <= X"00000001";     --Default value 
			REG_RW4     <= X"DEADBEEF";     --Default value 
			REG_RW5     <=  X"00000402";    --Default value
      MEB_RDi     <= '0';
      nREADY      <= '1';
      LADoe       <= '0';
      ADDR        <= (others => '0');
      DTL         <= (others => '0');
      LADout      <= (others => '0');
      rreg        := (others => '0');
      wreg        := (others => '0');
      LBSTATE     <= LBIDLE;
    elsif rising_edge(LCLK) then
      
      REG_RW3(8) <= '0';  -- generate the software clear pulse
      REG_RW3(9) <= '0';  -- generate the software start pulse
      
      if (meb_rdusedw < conv_std_logic_vector(3, 12)) then
        MEB_AE    <= '1';
      else
        MEB_AE    <= '0';
      end if;   
      
      MEB_RDi     <= '0';
      case LBSTATE is
        when LBIDLE  =>  
          if (blt_ready  = '1' and   meb_rdempty = '0') then
            nREADY  <= '0';
          else  
            nREADY  <= '1';
          end if;  
          
          LADoe   <= '0';
          if (nADS = '0') then
            ADDR <= LAD;            -- Address Sampling
            if (WnR = '1') then
              nREADY   <= '0';
              LBSTATE  <= LBWRITEL;     
            elsif LAD = A_MEB then 
              if meb_rdempty = '0' then
                nREADY   <= MEB_AE;
                MEB_RDi  <= '1';
                LADout   <= meb_dto(15 downto 0); --"0000" & MEB_USEDW;
                LADoe    <= '1';
                LBSTATE  <= LBREADMEBH;
              end if;  
            else  
              nREADY    <= '1';
              LBSTATE   <= LBREADL;
            end if;
          end if;

        when LBWRITEL => 
          DTL <= LAD;     -- Save the lower 16 bits of the data
          if (nBLAST = '0') then
            LBSTATE  <= LBIDLE;
            nREADY   <= '1';
          else
            LBSTATE  <= LBWRITEH;
          end if;
                         
        when LBWRITEH =>   -- Get the higher 16 bits and create the 32 bit data
          wreg  := LAD & DTL;
          case ADDR is
            when A_REG_RW1          => REG_RW1       <= wreg;
            when A_REG_RW2          => REG_RW2       <= wreg;
            when A_REG_RW3          => REG_RW3       <= wreg;
            when A_REG_RW4          => REG_RW4       <= wreg;
						when A_REG_RW5          => REG_RW5       <= wreg;
            when others          => null;
          end case;
          nREADY   <= '1';
          LBSTATE  <= LBIDLE;

        when LBREADL =>  
          
          nREADY    <= '0';
          case ADDR is
            when A_REG_R1          => rreg := REG_R1;
            when A_REG_R2          => rreg := REG_R2;
            when A_REG_R3          => rreg := REG_R3;
            when A_REG_R4          => rreg := REG_R4;
						when A_REG_R5          => rreg := REG_R5;
            when A_REG_R6          => rreg := REG_R6;
						when A_REG_RW1         => rreg := REG_RW1;
						when A_REG_RW2				 => rreg := REG_RW2;
						when A_REG_RW3         => rreg := REG_RW3;
						when A_REG_RW4         => rreg := REG_RW4;
						when A_REG_RW5         => rreg := REG_RW5;
						when A_REG_STATUS      => rreg := REG_STATUS;
            when others          => null;
          end case;
          LBSTATE  <= LBREADH;
          LADout <= rreg(15 downto 0);    -- Save the lower 16 bits of the data
          LADoe  <= '1';    -- Enable the output on the Local Bus
          
        when LBREADH =>  
          LADout  <= rreg(31 downto 16);    -- Put the higher 16 bits
          LBSTATE <= LBIDLE;

        when LBREADMEBL =>  
          if nBLAST = '0' then
            LBSTATE <= LBIDLE;
            LADoe   <= '0';
          else
            nREADY   <= MEB_AE;
            MEB_RDi  <= '1';
            LADout   <= meb_dto(15 downto 0);
            LBSTATE  <= LBREADMEBH;
          end if;  

        when LBREADMEBH =>  
          LADout   <= meb_dto(31 downto 16);
          if nBLAST = '0' then
            LBSTATE  <= LBIDLE;
          else
            LBSTATE  <= LBREADMEBL;
          end if;  

      end case;
      
    end if;
  end process;

end rtl;



