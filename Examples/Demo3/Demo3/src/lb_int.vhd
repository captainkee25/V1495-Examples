-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: v1495scaler
-- Device:          ALTERA EP1C4F400C6
-- Author:          Carlo Tintori
-- Date:            May 26th, 2009
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
use work.demo3_pkg.all;


entity lb_int IS
   PORT(
      -- Local Bus in/out signals
      nLBRES	  : IN     std_logic;
      nBLAST	  : IN     std_logic;
      WnR	      : IN     std_logic;
      nADS	    : IN     std_logic;
      LCLK	    : IN     std_logic;
      nREADY	  : OUT    std_logic;
      nINT	    : OUT    std_logic;
      LAD	      : INOUT  std_logic_vector (15 DOWNTO 0);
      
      DAC_DATA  : OUT    std_logic_vector (15 DOWNTO 0);  
      DAC_CH	  : OUT    std_logic_vector (3 DOWNTO 0);  
      DAC_TST	  : OUT    std_logic;
 
      DAC_WRD	  : OUT    std_logic;
      DAC_WRE	  : OUT    std_logic;
      DAC_WRF	  : OUT    std_logic;
      nLDACinD	: OUT    std_logic;
      nLDACinE	: OUT    std_logic;
      nLDACinF	: OUT    std_logic;
      
      nLEDG	: OUT    std_logic;
      nLEDR	: OUT    std_logic;
      
      IDD	  : IN     std_logic_vector (2 DOWNTO 0);   -- Slot D
      IDE	  : IN     std_logic_vector (2 DOWNTO 0);   -- Slot E
      IDF	  : IN     std_logic_vector (2 DOWNTO 0)    -- Slot F
    
   );

END lb_int ;


architecture rtl of lb_int is


subtype DACREG is std_logic_vector(W_DACVAL-1 downto 0);

type   BOARDDACREG_type is array(23 downto 0) of DACREG;

signal ALLDACREG : BOARDDACREG_type;


signal CTRLREG    : std_logic_vector(W_CTRL-1 downto 0);
signal UPDATE_DAC : std_logic;


signal LADoe      : std_logic;
signal DTL        : std_logic_vector(15 downto 0);

signal LADout     : std_logic_vector(15 downto 0);
signal ADDR       : std_logic_vector(15 downto 0);

type   LBSTATE_type is (LBIDLE, LBWRITEL, LBWRITEH, LBREADL, LBREADH);
signal LBSTATE : LBSTATE_type;

begin
  
  nINT    <= '1';  -- no interrupt request

  nLEDG   <= '1';
  nLEDR   <= '1';
  
  LAD     <= LADout when LADoe = '1' else (others => 'Z');


  DAC_TST   <= CTRLREG(CTRL_TESTMODE);  
  
  nLDACinD  <= CTRLREG(CTRL_USEnLADC) and not UPDATE_DAC and not CTRLREG(CTRL_TESTMODE);
  nLDACinE  <= CTRLREG(CTRL_USEnLADC) and not UPDATE_DAC and not CTRLREG(CTRL_TESTMODE);
  nLDACinF  <= CTRLREG(CTRL_USEnLADC) and not UPDATE_DAC and not CTRLREG(CTRL_TESTMODE);
  
  -- Local bus FSM
  process(LCLK, nLBRES)
  variable rreg, wreg   : std_logic_vector(31 downto 0);
  begin
    if (nLBRES = '0') then

      CTRLREG		<= D_CTRL;
      
      ALLDACREG	<= (others => X"8000");
      
      DAC_DATA  <= (others => '0');
      DAC_CH		<= (others => '0');
      
      nREADY		<= '1';
      LADoe		  <= '0';
      ADDR		  <= (others => '0');
      DTL		    <= (others => '0');
      LADout    <= (others => '0');
      
      DAC_WRD 	<= '0';
      DAC_WRE 	<= '0';
      DAC_WRF		<= '0';

      UPDATE_DAC  <= '0';
      
      rreg      := (others => '0');
      wreg		  := (others => '0');
      LBSTATE		<= LBIDLE;

    elsif rising_edge(LCLK) then

      UPDATE_DAC	<= '0';
      DAC_WRD 		<= '0';
      DAC_WRE 		<= '0';
      DAC_WRF		  <= '0';

      case LBSTATE is
      
        when LBIDLE  =>  
          nREADY  <= '1';
          LADoe   <= '0';
          if (nADS = '0') then
            ADDR <= LAD;            -- Address Sampling
            if (WnR = '1') then
              nREADY   <= '0';
              LBSTATE  <= LBWRITEL;     
            else  
              nREADY    <= '1';
              LBSTATE   <= LBREADL;
            end if;
          end if;

        when LBWRITEL => 
          DTL <= LAD;
          if (nBLAST = '0') then
            LBSTATE  <= LBIDLE;
            nREADY   <= '1';
          else
            LBSTATE  <= LBWRITEH;
          end if;
                         
        when LBWRITEH =>   
          wreg  := LAD & DTL;

          if ADDR(15 downto 7) = A_DACVAL(15 downto 7) then
            
            DAC_DATA  <= wreg(D_DACVAL'range);               
                
            case ADDR(6 downto 5) is
            
              when "00" => 	DAC_WRF	<= '1';
                            DAC_CH  <=  '0'& ADDR(4 downto 2);                
              
              when "01" => 	DAC_WRE	<= '1';
                            DAC_CH  <=  '0'& ADDR(4 downto 2);                
              
              when "10" => 	DAC_WRD	<= '1';
                            DAC_CH  <=  '0'& ADDR(4 downto 2);                
                
              when "11" => 	DAC_WRD	<= '1';
                            DAC_WRE	<= '1';
                            DAC_WRF	<= '1';
                            DAC_CH  <=  "1111";
                            
              when others =>  null;
              
            end case;
                
            for i in 0 to 23 loop
              if conv_integer (ADDR(6 downto 2)) = i or ADDR (6 downto 5) = "11" then          
                        ALLDACREG(i) <= wreg(D_DACVAL'range);          
              end if;
            end loop;

          else
            case ADDR is
              when A_CTRL       => CTRLREG      <= wreg(D_CTRL'range);        
              when A_CTRL_SET   => CTRLREG      <= CTRLREG	or      wreg(D_CTRL'range);        
              when A_CTRL_CLR   => CTRLREG      <= CTRLREG	and not wreg(D_CTRL'range);
              when A_DACUPDATE  => UPDATE_DAC   <= '1';
              when others       => null;
            end case;
          end if;
          
          nREADY   <= '1';
          LBSTATE  <= LBIDLE;

        when LBREADL =>  
          nREADY    <= '0';
          rreg := (others => '0');

          if(ADDR(15 downto 7) = A_DACVAL(15 downto 7)) and (ADDR(6 downto 5) /= "11") then
            for i in 0 to 23 loop
              if conv_integer (ADDR(6 downto 2)) = i then          
                rreg(D_DACVAL'range) := ALLDACREG(i);          
              end if;
            end loop;
          else
            case ADDR is
              when A_CTRL		  => rreg(D_CTRL'range)   := CTRLREG;    
              when A_FWREV		=> rreg := FWREV;  
              when A_ID_SLOTD => rreg(D_ID'range) := IDD;  
              when A_ID_SLOTE	=> rreg(D_ID'range) := IDE;  
              when A_ID_SLOTF => rreg(D_ID'range) := IDF;  
              when others     => null;
            end case;
          end if;
        
          LBSTATE  <= LBREADH;
          LADout <= rreg(15 downto 0);
          LADoe  <= '1';

        when LBREADH =>  
          LADout  <= rreg(31 downto 16);
          LBSTATE <= LBIDLE;                              
      end case;
    end if;
  end process;

end rtl;
