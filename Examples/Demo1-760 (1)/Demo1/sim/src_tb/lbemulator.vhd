-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: v1495scaler
-- Device:          ALTERA EP1C4F400C6
-- Author:          Carlo Tintori
-- Date:            Jan 26th, 2010
-- ----------------------------------------------------------------------------
-- Module:          lb_emulator
-- Description:     Local Bus emulator
-- ****************************************************************************

-- ############################################################################
-- Revision History:
-- ############################################################################
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;


ENTITY lbemulator IS
	PORT(
		nLBRES     : out    std_logic;
		nBLAST     : out    std_logic;
		WnR        : out    std_logic;
		nADS       : out    std_logic;
		LCLK       : in			std_logic;
		nREADY     : in     std_logic;
		nINT       : in     std_logic;
		LAD        : inout  std_logic_vector (15 DOWNTO 0)
	);
END lbemulator ;


ARCHITECTURE behav OF lbemulator IS

  type buffer_type   is array (0 to 16384) of std_logic_vector(31 downto 0);
	
	-- States of the finite state machine
	type   process_type is (init, write_MASK_A, write_MASK_B, write_CTRL_REG, write_C_USER_SET,
													read_MASK_A, read_INPUT_CHA, read_REG_STATUS, read_OUTPUT_CHC);
	signal process_step : process_type;

begin

      
  reading_writing_prcs: process
  
    variable rdata      : std_logic_vector(31 downto 0);
    variable mem_buffer : buffer_type;
		variable quit : boolean := false;

    -- **************************************************************************
    -- Procedure to access to Local Bus (lb)
    -- **************************************************************************

    -- -------------------------------------------------------------
    -- Init
    -- -------------------------------------------------------------
    procedure lb_init is
    begin
      nLBRES   <= '0';
      nBLAST   <= '1';
      nADS     <= '1';
      WnR      <= '1';
      LAD      <= (others => 'Z');
      wait for 100 ns;
      nLBRES   <= '1';
      wait for 200 ns;
    end;

    -- -------------------------------------------------------------
    -- Write Cycle (single 32bit word)
    -- -------------------------------------------------------------
    procedure lb_write32   (ADDR 		: in std_logic_vector(15 downto 0);
                            DATA  	: in std_logic_vector(31 downto 0) ) is
			--variable DATA	:  std_logic_vector(31 downto 0);
    begin
			--DATA := conv_std_logic_vector(DATA32, 32);
      wait until rising_edge(LCLK);
      WnR   <= '1';
      nADS  <= '0';
      LAD   <= ADDR;
      wait until rising_edge(LCLK);
      nADS    <= '1';
      LAD     <= DATA(15 downto 0);
      wait until rising_edge(LCLK);
      while nREADY /= '0' loop
        wait until rising_edge(LCLK);
      end loop;
      nBLAST  <= '0';
      LAD     <= DATA(31 downto 16);
      wait until rising_edge(LCLK);
      nBLAST <= '1';      
      LAD    <= (others => 'Z');
      wait for 25 ns;

    end;

    -- -------------------------------------------------------------
    -- Read Cycle (ciclo singolo)
    -- -------------------------------------------------------------
    procedure lb_read32  (ADDR : in    std_logic_vector(15 downto 0);
                          DATA : out   std_logic_vector(31 downto 0) ) is
    begin
      wait until rising_edge(LCLK);
      WnR    <= '0';
      nADS   <= '0';
      LAD    <= ADDR;
      wait until rising_edge(LCLK);
      nADS     <= '1';
      LAD      <= (others => 'Z');
      wait until rising_edge(LCLK);  
      while nREADY /= '0' loop
        wait until rising_edge(LCLK);
      end loop;    
      DATA(15 downto 0) := LAD;
      nBLAST <= '0';
      wait until rising_edge(LCLK);
      nBLAST <= '1';
      WnR    <= '1';      
      DATA(31 downto 16) := LAD;
			wait for 25 ns;
			
    end;


  begin

		process_step	<=	init;
    lb_init;
    process_step	<=	write_CTRL_REG;
		lb_write32(X"1018", X"00000120");   -- soft clear
    process_step	<=	write_CTRL_REG;
		lb_write32(X"1018", X"00000100");   -- remove soft clear
		
		process_step	<=	write_MASK_A;	
    lb_write32(X"1010", X"0000FFFF");
		
		process_step	<=	write_MASK_B;
		lb_write32(X"1014", X"0000FFFF");
		
		process_step	<=	write_CTRL_REG;
		lb_write32(X"1018", X"00000103");
		
		process_step	<=	write_C_USER_SET;
		lb_write32(X"101C", X"00000022");  --decimal = 34
		
		wait for 100 ns;

		process_step	<=	read_MASK_A;
    lb_read32(X"1010", rdata); -- reading input channel A mask
		process_step	<=	read_INPUT_CHA;
		lb_read32(X"1030", rdata); -- reading input channel A
		
		wait for 10 ns; 
		wait until rising_edge(LCLK);
		

		
		while not quit loop
			process_step	<=	read_REG_STATUS;
			lb_read32(X"1040", rdata); -- reading status register
        
			if( rdata(0) = '1' ) then
				process_step	<=	write_CTRL_REG;
				lb_write32(X"1018", X"00000100");
				process_step	<=	read_OUTPUT_CHC;
				lb_read32(X"1038", rdata);	-- reading the triggerd acquisition output channel C
				
				wait for 40 ns;
				
				process_step	<=	write_CTRL_REG;
				lb_write32(X"1008", X"00000120");		-- reset the output channel C via software (11 --> "1011")
				
				quit := true;
			end if;	
    end loop;
	
    wait;

  end process reading_writing_prcs;
  
                   
END behav;
