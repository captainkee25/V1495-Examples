-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           Scheda test ACTEL APA100
-- FPGA Proj. Name: APAtst_board
-- Device:          ACTEL APA100 PQ208
-- Author:          Annalisa Mati
-- Date:            14/09/04
-- ----------------------------------------------------------------------------
-- Module:          MONOSTABLE
-- Description:     Fixed Time Monostable for LED driving
-- ****************************************************************************

-- ############################################################################
-- $Id: monostable.vhd 14 2009-09-18 16:22:12Z Colombini $
-- ############################################################################


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY MONOSTABLE IS
   PORT( 
      CLK     : IN     std_logic;
      RESET   : IN     std_logic;
      MONIN   : IN     std_logic;
      MONOUT  : OUT    std_logic
   );

-- Declarations

END MONOSTABLE ;

  -- *****************************************************************************
  -- TICK
  -- A Tick is a pulse that lasts for 1 period of CLK and is repeated every N periods
  -- *****************************************************************************
  -- T64:  Period=Tclk*64  (about 1.6us at 40MHz)
  -- T16K: Period=Tclk*16K (about 410us at 40MHz)
  -- T2M:  Period=Tclk*4M  (about 104ms at 40MHz)

ARCHITECTURE RTL OF MONOSTABLE IS


  signal TMONOS : std_logic := '0';
  signal clkcnt : std_logic_vector(23 downto 0);
  signal TICK   : std_logic; 

begin

-- monostabile signals   
  tick_proc:process(CLK, RESET)
  begin
    if RESET = '0' then
      clkcnt  <=  (others => '0');
    elsif CLK'event and CLK='1' then
      TICK <=  '0';
      clkcnt <=  clkcnt + 1;
      if(clkcnt = 2**24 - 1) then   -- Period=Tclk*16,7M  (about 167ms at 100Mhz)
        TICK <= '1';
        --clkcnt <=  (others => '0');
      end if;   
    end if;
  end process tick_proc;
  
  -- MONOUT is set at first CLK rising edge with MONIN=0 and it is reset 
  -- after a TICK impulse (or rimain high if MONIN remains high )
  
  monostab_proc:process(CLK, RESET, MONIN)
  begin
    if RESET = '0' then
      TMONOS <= '0';
      MONOUT <= '1';
    elsif MONIN = '0' then
      TMONOS <= '1';
      MONOUT <= '0';
    elsif CLK'event and CLK='1' then
      if TICK = '1' then
        if TMONOS = '1' then
          TMONOS <= '0';
        else
          MONOUT <= '1';
        end if;
      end if;
    end if;
  end process monostab_proc;
  
END RTL;

