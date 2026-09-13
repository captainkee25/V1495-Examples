-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: 
-- Device:          ALTERA EP1C4F400C6
-- Author:          Maura Pieracci
-- Date:            Jul 2th, 2009
-- ----------------------------------------------------------------------------
-- Module:          demo3_pkg
-- Description:     package with registers address, bits, etc...
-- ****************************************************************************

library ieee;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;


package demo3_pkg is

  -- ***************************************************************************************
  -- FIRMWARE REVISION
  -- ***************************************************************************************
  constant FWREV : std_logic_vector(31 downto 0) := X"00000031";

  -- ***************************************************************************************
  -- REGISTERS ADDRESSES (Offset only)
  -- ***************************************************************************************
  
  constant A_CTRL         : std_logic_vector(15 downto 0) := X"1000"; -- R/W - 
  constant A_CTRL_SET     : std_logic_vector(15 downto 0) := X"1004"; -- W - 
  constant A_CTRL_CLR     : std_logic_vector(15 downto 0) := X"1008"; -- W -
  
  constant A_FWREV        : std_logic_vector(15 downto 0) := X"100C"; -- R -  

  constant A_DACUPDATE    : std_logic_vector(15 downto 0) := X"1010"; -- W - 

  constant A_ID_SLOTD     : std_logic_vector(15 downto 0) := X"1014"; -- R - 

  constant A_ID_SLOTE     : std_logic_vector(15 downto 0) := X"1018"; -- R - 
  
  constant A_ID_SLOTF     : std_logic_vector(15 downto 0) := X"101C"; -- R - 
    
  constant A_DACVAL       : std_logic_vector(15 downto 0) := X"1100"; -- R/W - 
  
  -- ***************************************************************************************
  -- REGISTERS WIDTH
  -- ***************************************************************************************
  constant W_CTRL         : integer := 2;
 
  constant W_FWREV        : integer := 32;  
   
  constant W_DACVAL       : integer := 16; 
 
  constant W_ID           : integer := 3; 
 
  -- ***************************************************************************************
  -- REGISTERS DEFAULT VALUES
  -- ***************************************************************************************
  constant D_CTRL         : std_logic_vector(W_CTRL-1   downto 0)   := (others => '0');

  constant D_DACVAL       : std_logic_vector(W_DACVAL-1 downto 0)   := (others => '0');

  constant D_ID           : std_logic_vector(W_ID-1     downto 0)   := (others => '0');
      
  -- ***************************************************************************************
  -- REGISTER BIT FIELDS
  -- ***************************************************************************************
  
  -- CONTROL REGISTER
  constant CTRL_TESTMODE          : integer := 0;
  constant CTRL_USEnLADC          : integer := 1;
 
  -- ***************************************************************************************
  -- VECTORS of zeroes and ones
  -- ***************************************************************************************
  function vector_0(n : integer) return std_logic_vector;
  function vector_1(n : integer) return std_logic_vector;
  
end demo3_pkg;


package body demo3_pkg is

  function vector_0(n : integer) return std_logic_vector is
    variable q : std_logic_vector(n-1 downto 0);
    begin
      q := (others => '0');
      return q;
    end vector_0;

  function vector_1(n : integer) return std_logic_vector is
    variable q : std_logic_vector(n-1 downto 0);
    begin
      q := (others => '1');
      return q;
    end vector_1;
    

end demo3_pkg;

