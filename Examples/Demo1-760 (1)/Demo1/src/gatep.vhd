-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- Device:          ALTERA EP1C4F400C6
-- Author:          Eltion Begteshi
-- Date:            April 5th, 2010
-- ----------------------------------------------------------------------------
-- Module:          gatep
-- Description:     data producer
-- ****************************************************************************

-- NOTE: this is just an example of interface between the user FPGA and the
-- local bus on the V1495. In this example, there are 4 registers called REG1,
-- REG2, REG3 and REG4 that can be written and read from the VME (through the
-- local bus). The registers are 32 bit wide and can be accessed in single mode.
-- There is also a FIFO for the data readout; this is also 32 bit wide and can
-- be read in either single D32 read or Block Transfer Read.

library ieee;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;

ENTITY gatep is
	port(
		LCLK					:	in	std_logic;
		A         		: in  std_logic_vector(31 downto 0);  -- in a (32 x lvds/ecl)
		B         		: in  std_logic_vector(31 downto 0);  -- in b (32 x lvds/ecl)
		C         		: out std_logic_vector(31 downto 0);
		GIN           : in  std_logic_vector( 1 downto 0);
		mask_A	      :	in	std_logic_vector(31 downto 0);
		mask_B	      :	in	std_logic_vector(31 downto 0);
		ctrl_reg			:	in	std_logic_vector(31 downto 0);
		user_value_C	: in  std_logic_vector(31 downto 0);
		REG_STATUS		:	out	std_logic_vector(31 downto 0);
		pattern				:	out	std_logic_vector(31 downto 0)
 );

END gatep ;


ARCHITECTURE RTL of gatep is
  
  alias ext_clear_in   : std_logic is GIN(0);
  alias ext_gate_in    : std_logic is GIN(1);
  signal ext_clear     : std_logic;
  signal ext_gate      : std_logic;
  
  -- Address latched from the LAD bus
	signal chann_A				: std_logic_vector(31 downto 0);
	signal chann_B				: std_logic_vector(31 downto 0);
	signal chann_A_reg		: std_logic_vector(31 downto 0);
	signal chan_AorB			: std_logic_vector(31 downto 0);
	signal clear_reg			: std_logic;
	signal gate						: std_logic;	
  signal en_gate		    : std_logic;
  signal en_gate32	    : std_logic_vector(31 downto 0);	
	signal gate32					:	std_logic_vector(31 downto 0);
	signal clk_32					:	std_logic_vector(31 downto 0);
	signal event_captured	:	std_logic_vector(31 downto 0);
	signal data_ready			:	std_logic;
	
  alias out_sel		      : std_logic_vector( 1 downto 0) is  ctrl_reg(1 DOWNTO 0);
  alias soft_gate       : std_logic	is  ctrl_reg(4);
	alias soft_clear	    : std_logic	is  ctrl_reg(5);
  
  
begin

	chann_A	  <=	A and mask_A;
	chann_B	  <=	B and mask_B;
	
	chan_AorB	<=	chann_A or chann_B;
	clear_reg	<=	ext_clear or soft_clear;
	gate			<=	ext_gate or soft_gate; -- Gate active low
	gate32		<=	(others	=> gate);
  en_gate32 <=  (others	=> en_gate);
	
	clk_32 		<= chan_AorB and gate32 and en_gate32;
	
	
  -- Updating input NIM/TTL
  ext_clear <=  ext_clear_in xnor ctrl_reg(8);
  ext_gate  <=  ext_gate_in xnor ctrl_reg(8);
	
  
  -- Updating Status Register
	process(gate, clear_reg)
	begin
		if(clear_reg = '1') then
			data_ready	 <=	'0';
		elsif(gate'event and gate = '1') then
			data_ready <= '1';
		end if;
	end process;
  
 
	process(gate, clear_reg)
	begin
		if(clear_reg = '1') then
			en_gate	 <=	'1';
		elsif(gate'event and gate = '0') then
			en_gate  <=  not data_ready;
		end if;
	end process;

  REG_STATUS(0)	<=	data_ready;
	REG_STATUS(1)	<=	ext_gate;
  REG_STATUS(2)	<=	ext_clear;
  REG_STATUS(3)	<=	soft_gate;
  REG_STATUS(4)	<=	soft_clear;
	

	gen_event_captured: for i in 0 to 31 generate
		--DFF with asynchronous reset
		capture_process: process(clk_32(i), clear_reg)
		begin
			if(clear_reg = '1') then
				event_captured(i) <= '0';
			elsif(clk_32(i)'event and clk_32(i) = '1') then
				event_captured(i) <= '1';
			end if;
		end process capture_process;
	end generate gen_event_captured;
			
	pattern	<=	event_captured;
	
	
	C <=	event_captured	when	out_sel = "00" else
				clk_32					when	out_sel = "10" else
				user_value_C;
				
END RTL;



