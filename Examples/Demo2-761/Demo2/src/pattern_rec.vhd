-- ========================================================================
-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- Device:          ALTERA EP1C4F400C6
-- Author:          Eltion Begteshi
-- Date:            April 13th, 2009
-- ----------------------------------------------------------------------------
-- Module:          pattern_rec
-- Description:     data producer
-- ****************************************************************************

-- NOTE: this is just a simple example of a circuit that perform sampling of input 
-- data, coming from A or B port, and store them into a local user FIFO. When all 
-- the requested data are recorded, they are read then from the VME using block 
-- transfer mode.

library ieee;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;


ENTITY pattern_rec is
	port(
		clk   				:	in	std_logic;
		A         		: in  std_logic_vector(31 downto 0);  -- in a (32 x lvds/ecl)
		B         		: in  std_logic_vector(31 downto 0);  -- in b (32 x lvds/ecl)
		output_C   		: out std_logic_vector(31 downto 0);
    GIN           : in  std_logic_vector( 1 DOWNTO 0);  -- In G - LEMO (2 x NIM/TTL)
    nLBRES        : in  std_logic;
    areset        : buffer std_logic;
    meb_wrfull    : in  std_logic;
    meb_wr        : out std_logic;
    meb_wrusedw   : in  std_logic_vector(11 downto 0);
		
		mask_A	      :	in	std_logic_vector(31 downto 0);
		mask_B	      :	in	std_logic_vector(31 downto 0);
		ctrlreg			  :	in	std_logic_vector(31 downto 0);
		user_output_C	: in  std_logic_vector(31 downto 0);
    ndiv_length   : in  std_logic_vector(31 downto 0);
    reg_status    : out std_logic_vector(31 downto 0)
 );

END pattern_rec ;


ARCHITECTURE RTL of pattern_rec is

  type ACQ_STATE_TYPE is (IDLE, ACQ, WAIT_END);
  signal STATE    : ACQ_STATE_TYPE;



	-- Address latched from the LAD bus
	signal chann_A				: std_logic_vector(31 downto 0);
	signal chann_B				: std_logic_vector(31 downto 0);
	signal chann_A_reg		: std_logic_vector(31 downto 0);
  signal chann_B_reg		: std_logic_vector(31 downto 0);

  signal start_acq      : std_logic;
  signal start_reg      : std_logic;
  signal start_aux_reg  : std_logic;
  
  signal wcnt           : std_logic_vector(11 downto 0);
  signal clkcnt         : std_logic_vector( 3 downto 0);
  
  signal aux            : std_logic;
  signal reset_start    : std_logic;
  signal areset_1       : std_logic;
  alias out_sel         : std_logic_vector( 1 downto 0) is ctrlreg( 5 downto 4);
  alias soft_clear	    : std_logic is  ctrlreg(8);
	alias soft_start			: std_logic is  ctrlreg(9);
  alias ndiv            : std_logic_vector( 3 downto 0) is ndiv_length( 3 downto 0);
  alias rec_length      : std_logic_vector(11 downto 0) is ndiv_length(15 downto 4);
  
  alias blt_ready       : std_logic is REG_STATUS(0);
  alias nLEDG           : std_logic is REG_STATUS(1);
  alias nLEDR           : std_logic is REG_STATUS(2);
  
  alias ext_clear_in    : std_logic is GIN(0);
  alias ext_start_in    : std_logic is GIN(1);
  signal ext_clear      : std_logic;
  signal ext_start      : std_logic;
  
  signal ext_clear_probe : std_logic;

begin

  chann_A	<=	A and mask_A;
	chann_B	<=  B and mask_B;
  
  areset  <=  soft_clear  or  ext_clear or (not nLBRES);
  start_acq   <=  soft_start  or  ext_start;
  ext_clear_probe <= ext_clear;

  ASSERT (conv_integer(ndiv) < 16)    
            REPORT "Out of Range: ndiv GREATER THAN 7"
	         	SEVERITY ERROR;
             
	
  -- Updating input NIM/TTL
  ext_clear <=  ext_clear_in xnor ctrlreg(0);
  ext_start <=  ext_start_in xnor ctrlreg(0);
  
  --DFF with asynchronous reset
  dff_process: process(clk, areset)
    variable count  : integer:= 0;
  begin
    if(areset = '1') then
      chann_A_reg <= (others => '0');
      chann_B_reg <= (others => '0');

    elsif(clk'event and clk = '1') then
      chann_A_reg <=  chann_A;
      chann_B_reg <=  chann_B;
    end if;
  end process dff_process;

  
  areset_1  <= areset or reset_start;
  
  start_capture_proc: process(start_acq, areset_1)
  begin
    if areset_1 = '1' then
      start_aux_reg   <= '0';
    elsif start_acq'event and start_acq = '1' then
      start_aux_reg   <= '1';
    end if;
  end process start_capture_proc;
  
  start_reg_proc: process(clk, areset_1)
  begin
    if areset_1 = '1' then
      start_reg   <= '0';
    elsif clk'event and clk = '1' then
      start_reg   <= start_aux_reg;
    end if;
  end process start_reg_proc;
  
  
  
  -- FSM
  fsm_process: process(clk, areset)
  begin
    if (areset = '1') then
 
      STATE <=  IDLE;
      wcnt    <= (others => '0');
      clkcnt  <= (others => '0');
      meb_wr  <= '0';
      nLEDG <= '1';  --  GREEN OFF
      nLEDR <= '0';  --  RED ON
      reset_start   <= '1';
    
    elsif(clk'event and clk = '1') then
      
      meb_wr  <= '0';
      
      case STATE is
        when IDLE =>
          reset_start   <= '0';
          nLEDG <= '0';  --  GREEN ON
          nLEDR <= '1';  --  RED OFF
          blt_ready <= '0';
          if (start_reg = '1' and (meb_wrusedw < conv_std_logic_vector(4087, 12) - rec_length)) then  --4086
            wcnt    <= (others => '0');
            clkcnt  <= (others => '0');
            STATE   <= ACQ;
          end if;
        
        when ACQ =>
          nLEDG <= '0';  --  GREEN ON
          nLEDR <= '0';  --  RED ON
          clkcnt <= clkcnt + 1;
          if(clkcnt = ndiv - 1) then
            meb_wr  <= '1';
            wcnt    <= wcnt + 1;
            if(wcnt = rec_length - 1) then
              blt_ready <= '1';     -- start BLT request
              STATE <= WAIT_END;
            end if;
            clkcnt  <=  (others => '0');   
          end if;
          
        when WAIT_END =>
          nLEDG <= '1';  --  GREEN OFF
          nLEDR <= '1';  --  RED OFF
          if (meb_wrusedw = conv_std_logic_vector(0, 12)) then
            blt_ready <= '0';
            reset_start   <= '1';
            STATE <= IDLE;
          end if;

      end case;
    end if;
  end process fsm_process;
  
	output_C <=	chann_A_reg 	when	out_sel = "00" else
              chann_B_reg		when	out_sel = "01" else
              user_output_C;		
   
END RTL;


