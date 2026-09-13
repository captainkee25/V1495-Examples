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
	type   process_type is (init, write_MASK_A, write_MASK_B, write_CTRL_reg, write_C_USER_SET, write_ndiv_length_reg,
													read_MASK_A, read_INPUT_CHA, read_CTRL_REG, read_REG_STATUS, read_block_transfer, end_block_transfer);
	signal process_step : process_type;
  signal rec_length   : integer;
  
  constant P			    : time	 	:= 25 ns;
  

begin

      
  reading_writing_prcs: process
  
    variable rdata      : std_logic_vector(31 downto 0);
    variable mem_buffer : buffer_type;
		variable quit : boolean := false;
    variable letti_NW   : integer;
    --signal   rec_length : integer;
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
      wait for 5 *P;
      nLBRES   <= '1';
      wait for 5 *P;
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
      wait for 1 *P;

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
			wait for 1 *P;
			
    end;

    -- -------------------------------------------------------------
    -- Read Block
    -- -------------------------------------------------------------
    procedure lb_read_block  (ADDR 		: in    std_logic_vector(15 downto 0);
                              DATA 		: out   buffer_type;
                              REQ_NW 	: in    integer;
                              ACT_NW 	: out   integer) is
			variable i 		: integer := 0;
			variable quit : boolean := false;
			variable D32 	: std_logic_vector(31 downto 0);
    begin
    
      wait until rising_edge(LCLK);
      WnR   <= '0';
      nADS  <= '0';
      LAD   <= ADDR;
      wait until rising_edge(LCLK);
      nADS    <= '1';
      LAD     <= (others => 'Z');
      while nREADY /= '0' loop
        wait until rising_edge(LCLK);
      end loop;    
      while not quit loop
        D32(15 downto 0) := LAD;
        if nREADY = '1' then
          nBLAST <= '0';
          quit := true;
        else
          wait until rising_edge(LCLK);
          if (i = (REQ_NW - 1)) or (nREADY = '1') then
            nBLAST <= '0';
            quit := true;
          end if;
          D32(31 downto 16) := LAD;
          DATA(i) := D32;
          i := i + 1;
        end if;  
        wait until rising_edge(LCLK);
      end loop;
      nBLAST <= '1';
      WnR    <= '1';
      ACT_NW := i;
      
    end;


  begin

		process_step	<=	init;
    lb_init;
    process_step	<=	write_CTRL_reg;
		lb_write32(X"1018", X"00000001");   -- set control register
    
    process_step	<=	write_ndiv_length_reg;
		lb_write32(X"1020", X"000000F1");   -- set freq divider and length of data to write in FIFO
		
		process_step	<=	write_MASK_A;	
    lb_write32(X"1010", X"FFFFFFFF");
		
		process_step	<=	write_MASK_B;
		lb_write32(X"1014", X"FFFFFFFF");
		
		
		process_step	<=	write_C_USER_SET;
		lb_write32(X"101C", X"00000022");  --34
		
		wait for 5*P;

		process_step	<=	read_MASK_A;
    lb_read32(X"1010", rdata); -- reading channel A mask
		process_step	<=	read_INPUT_CHA;
		lb_read32(X"1030", rdata); -- reading input channel A
		
		wait for 5*P; 


    lb_read32(X"1020", rdata);
    rec_length  <=  conv_integer(unsigned(rdata(15 downto 4)));  	
        
		while not quit loop
			
      if( nREADY = '0' ) then

        process_step	<=	read_block_transfer;
        lb_read_block(X"0000", mem_buffer, rec_length, letti_NW);
        
				wait for 2*P;
				quit := true;
			end if;
      
      wait for 1 ns;
    end loop;
    
		process_step	<=	end_block_transfer;
    
    wait;

  end process reading_writing_prcs;
  
                   
END behav;
