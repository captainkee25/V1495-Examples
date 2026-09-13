-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: 
-- Device:          ALTERA EP1C4F400C6
-- Author:          Maura Pieracci
-- Date:            Jul 2th, 2009
-- ----------------------------------------------------------------------------
-- Module:          densimeter_pkg
-- Description:     package with registers address, bits, etc...
-- ****************************************************************************

-- ############################################################################
-- Revision History:
-- ############################################################################

library ieee;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;
--use work.demo3_pkg.all;

entity dac_int is
   port(

    nLBRES     : in     std_logic;
    LCLK       : in     std_logic;

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
end dac_int ;


architecture rtl of dac_int is
  
function index_ch(channel : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable q : std_logic_vector(3 downto 0);
    begin
         
      case channel is       -- channel decoding
        when "0000" =>  q := "0110"; 
        when "0001" =>  q := "0100"; 
        when "0010" =>  q := "0010"; 
        when "0011" =>  q := "0000"; 
        when "0100" =>  q := "0001"; 
        when "0101" =>  q := "0011"; 
        when "0110" =>  q := "0101"; 
        when "0111" =>  q := "0111"; 
        when others =>  q := "1111"; 
      end case;
   return q;
end index_ch; 

--dac

signal SPI_CNTDATA   : std_logic_vector(5 downto 0);

signal SPI_DATA      : std_logic_vector(31 downto 0);

signal CH            : std_logic_vector(3 downto 0);
signal COMMAND       : std_logic_vector(3 downto 0);
signal WRSPI         : std_logic;
signal VALUE         : std_logic_vector(15 downto 0);

signal SPIEND        : std_logic;

signal TICK1US       : std_logic;


type STATESPI_type is  (S1DAC, S2DAC, S3DAC, S4DAC, S5DAC, S6DAC, S7DAC);
signal STATESPI  : STATESPI_type;

type STATEDACCTRL_type is  (SCTRL_PWDN, SCTRL_VREF, SCTRL_PWUP, SCTRL_WAITUP, SCTRL_VIN,SCTRL_IDLE, SCTRL_TEST, SCTRL_WAIT);
signal STATEDACCTRL  : STATEDACCTRL_type;

begin
      
nLDAC <= nLDACin;


  -- 1us tick
  process(LCLK, nLBRES)
  variable CUS : std_logic_vector(5 downto 0);
  begin
    if (nLBRES = '0') then
      CUS    := "000000";
      TICK1US <= '0';
    elsif rising_edge(LCLK) then
      TICK1US <= '0';
      CUS := CUS + 1;
      if CUS = "101000" then  -- 40 Tclk = 1us
        CUS := "000000"; 
        TICK1US <= '1';
      end if;  
    end if;
  end process;
  


-- DAC CONTROL state machine
    process(LCLK, nLBRES)
       variable T_CNT : std_logic_vector(15 downto 0);
    begin
      if (nLBRES = '0') then
        WRSPI   <='0';
        VALUE   <= (others => '0');
        COMMAND <= (others => '0');
        CH      <= "1111";
        T_CNT   := (others => '0');
        STATEDACCTRL        <= SCTRL_PWDN;
      elsif rising_edge(LCLK) then
 
      	case STATEDACCTRL is

          when SCTRL_PWDN  => 
              
              VALUE   <= X"002F"; --0....00 (don't care) 10 power down mode 1111 (dacH dacE)
              COMMAND <= "0100";  -- power down/up dac
              WRSPI <='1';
              if SPIEND = '1' then
                WRSPI <='0';
                STATEDACCTRL  <= SCTRL_VREF;
              end if;  
                              
          when SCTRL_VREF  => 
              
              VALUE   <= (others => '0'); -- don't care value
              COMMAND <= "1000";  -- setup reference
              CH      <= "1111";
              WRSPI <='1';
              if SPIEND = '1' then
                WRSPI <='0';
                STATEDACCTRL  <= SCTRL_PWUP;
              end if;  

          when SCTRL_PWUP  => 
              
              VALUE   <= X"000F"; --0....00 (don't care) 00 power up mode 1111 (dacH dacE)
              COMMAND <= "0100";  -- power down/up dac
              WRSPI <='1';
              if SPIEND = '1' then
                COMMAND <= "0000";  -- write 
                WRSPI <='0';
                T_CNT   := (others => '0');
                STATEDACCTRL  <= SCTRL_WAITUP;
              end if;  

          when SCTRL_WAITUP => if TICK1US = '1' then  
                
                T_CNT := T_CNT+1;
                end if;
                if T_CNT = X"0004" then 
                  STATEDACCTRL   <= SCTRL_VIN;
                end if;

          when SCTRL_VIN    => 
                
                VALUE   <= X"8000"; -- all dac channel setted at mid-scale
                COMMAND <= "0000";  -- write 
                CH      <= "1111";
                WRSPI <='1';
                if SPIEND = '1' then
                  WRSPI <='0';
                  STATEDACCTRL  <= SCTRL_IDLE;
                end if;  

          when SCTRL_IDLE  => 
                
                if DAC_TST = '1' then
                  VALUE   <= (others => '0');
                  CH      <= "1111";
                  STATEDACCTRL  <= SCTRL_TEST;
                elsif DAC_WR = '1' then
                  VALUE   <= DAC_DATA;
                  CH      <= index_ch(DAC_CH);
                  WRSPI <='1';
                  STATEDACCTRL  <= SCTRL_WAIT;
                end if;  
    
          when SCTRL_TEST  => 
          
                if DAC_TST = '1' then
                  VALUE <= VALUE + 1;
                  T_CNT := (others => '0');
                  WRSPI <='1';
                  STATEDACCTRL  <= SCTRL_WAIT;
                else  
                  STATEDACCTRL  <= SCTRL_IDLE;
                end if;

          when SCTRL_WAIT  => 
                if SPIEND = '1' then  
                  WRSPI   <='0';
                  if DAC_TST = '1' then
                    STATEDACCTRL  <= SCTRL_TEST;
                  else
                    STATEDACCTRL  <= SCTRL_IDLE;  
                  end if;
                end if;
                              
        end case;
                    
      end if;
    end process;
       

   
  -- DAC SPI cycle state machine
      process(LCLK, nLBRES)
      begin
        if (nLBRES = '0') then
          nCSDAC              <= '1';
          SCK                 <= '1';
          SDI                 <= '0';
          SPIEND              <= '0';
          SPI_CNTDATA         <= "000000";
          SPI_DATA            <= (others => '0');
          STATESPI            <= S1DAC;
        elsif rising_edge(LCLK) then
   
         SPIEND  <= '0';
       
          -- DAC SPI for offset setting
          case STATESPI is
    
            when S1DAC  => SCK        <= '1';
                           SDI        <= '0';
                           SPI_CNTDATA <= (others => '0');
    
                           if WRSPI = '1' then
                             SPI_DATA <= "0000" & COMMAND & CH & VALUE & "1111";  -- DB0 is don't care, it is important only for "internal reference"    
                             STATESPI <= S2DAC;
                           end if;
    
            when S2DAC  => nCSDAC <= '0';
                           STATESPI  <= S3DAC;
    
            when S3DAC  => SDI         <= SPI_DATA(31);
                           SPI_DATA    <= SPI_DATA(30 downto 0) & '0';
                           SPI_CNTDATA <= SPI_CNTDATA + 1;
                           STATESPI    <= S4DAC;
    
            when S4DAC  => SCK         <= '0';
                           STATESPI    <= S5DAC;
    
    
            when S5DAC  => SCK     <= '1';
                           if conv_integer(SPI_CNTDATA) = 32 then
                             STATESPI  <= S6DAC;
                             SPI_CNTDATA <= (others => '0');
                           else
                             STATESPI  <= S3DAC;
                           end if;
                           
            when S6DAC  => nCSDAC  <= '1';
                           SPIEND   <= '1';
                           STATESPI  <= S7DAC;

            when S7DAC  => STATESPI  <= S1DAC;

          end case;
                    
        end if;
    end process;
      
  

end rtl;
