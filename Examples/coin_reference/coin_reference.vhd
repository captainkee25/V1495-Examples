-- ****************************************************************************
-- V1495 USER FPGA - NIM_DELAY_GEN (v2: mixed-level trigger-on-F0 topology)
--
-- FUNCTION:
--   Trigger enters on F channel 0 (TTL, A395D mezzanine in slot F).
--   That trigger fans out to 9 independent delay/width-gated outputs:
--     - F channels 1-7 (7x, TTL)
--     - G0, G1         (2x, NIM)
--   Each of the 9 outputs has its own delay + width register, counted in
--   FAST_CLK cycles (PLL-multiplied from the 40 MHz LCLK -- see below).
--
-- CLOCKING: everything in this file (trigger sync, all 9 channels, the
-- register interface) now runs off FAST_CLK, a PLL-multiplied version of
-- LCLK, instead of LCLK directly. Generate FAST_CLK with Quartus
-- MegaWizard (Tools -> MegaWizard Plug-In Manager -> I/O -> ALTPLL),
-- inclk0 = 40 MHz, one output c0 (this file assumes x4 -> 160 MHz,
-- 6.25 ns/tick), name the instance "sys_pll", add the generated .qip to
-- the project. This shrinks both the digital step (25 ns -> 6.25 ns) and
-- the trigger synchronizer's jitter (+-25 ns -> +-6.25 ns) for all 9
-- channels at once, since none of them use PDL/DLO in this build.
--   Putting EVERY process on FAST_CLK (not just the channels) means
-- CH_DELAY/CH_WIDTH are written and read on the same clock -- no
-- register CDC synchronizer needed. The only true async boundary left is
-- the trigger input itself (TRIG_RAW), which already has its own
-- synchronizer, and the VME bus control signals (REG_WREN/REG_RDEN/etc),
-- which are safe to sample on a faster clock since they're pulses at
-- least one LCLK period wide -- several FAST_CLK cycles at this ratio.
--
-- WHY F0 CAN BE AN INPUT WHILE F1-F7 STAY OUTPUTS:
--   F_DIR is a single bit for the whole port (hardware limit, not firmware
--   -- see V1495 manual). But the A395D output stage has a "recessive
--   state": driving a channel's DOUT bit to '0' doesn't force the line
--   low, it releases it, so an external driver can pull it. F0's DOUT bit
--   is permanently tied to '0' below, making it passively readable via
--   F_DIN even though F_CONTROL keeps the whole port in "output" mode.
--   Confirm 50-ohm termination on F0 is enabled -- you need to change one black clip on the board.
--
-- A395D CHANNEL <-> BIT MAPPING: SIMPLE 1:1 (per the manual's footnote 2 on
-- Table 5.1 -- "I/O channels of the A395D are mapped on the 8 LSB of D_DIN,
-- D_DOUT, ... F_DIN, F_DOUT" -- bench-confirmed on this board over
-- Table 5.8's non-sequential mapping, which the two disagreed on):
--   Chan 0 = bit 0 (trigger input, DIN and DOUT both bit 0)
--   Chan 1 = bit 1  (F1) ... Chan 7 = bit 7 (F7)  -- same bit for DIN/DOUT
--
-- LEVEL CONVENTION (A395D datasheet): TTL IN = direct, NIM IN = inverted,
-- both OUT = direct. F0 (TTL) needs no inversion; G is output-only here.
--
-- ----------------------------------------------------------------------------
-- REGISTER MAP (all 16-bit, D16 access)
--
--   0x1020  SCRATCH      R/W  scratch register (0x5A5A after reset)
--   0x1050  FWID         R    0xD617 (FAST_CLK/PLL version -- distinguishes
--                              this from 0xD613's plain-LCLK build)
--   0x1022  G_CONTROL    R/W  bit0: level (0=TTL,1=NIM). Write 0x0001 (NIM).
--                              G_DIR is hardwired OUTPUT in this version.
--   0x1034  F_CONTROL    R/W  bit0: level (0=TTL,1=NIM), bit1: dir (0=OUT,1=IN)
--                              Write 0x0000 (TTL, port in OUTPUT mode --
--                              F0 stays readable via the recessive trick)
--   0x1054  STATUS_TRIG  R    bit0: live raw F0 input level (unsynchronized)
--                              bit1: sticky "trigger seen" flag, latched by
--                              any TRIG_EDGE, cleared by writing this reg
--                              (any value). Diagnostic only.
--
--   Per-channel DELAY/WIDTH (FAST_CLK cycles, 6.25 ns/step at x4), 9 channels:
--   idx  Channel   DELAY addr  WIDTH addr
--    0   F1        0x1060      0x1062
--    1   F2        0x1064      0x1066
--    2   F3        0x1068      0x106A
--    3   F4        0x106C      0x106E
--    4   F5        0x1070      0x1072
--    5   F6        0x1074      0x1076
--    6   F7        0x1078      0x107A
--    7   G0        0x107C      0x107E
--    8   G1        0x1080      0x1082
--
--   G_CONTROL/F_CONTROL reset to 0x0000 every power cycle/nLBRES and must
--   be rewritten each session.
-- ****************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;  -- OR_REDUCE

ENTITY coin_reference IS
   PORT(
      nLBRES      : IN     std_logic;
      LCLK        : IN     std_logic;
      REG_WREN    : IN     std_logic;
      REG_RDEN    : IN     std_logic;
      REG_ADDR    : IN     std_logic_vector (15 DOWNTO 0);
      REG_DIN     : IN     std_logic_vector (15 DOWNTO 0);
      REG_DOUT    : OUT    std_logic_vector (15 DOWNTO 0);
      USR_ACCESS  : IN     std_logic;
      A_DIN       : IN     std_logic_vector (31 DOWNTO 0);
      B_DIN       : IN     std_logic_vector (31 DOWNTO 0);
      C_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);
      G_LEV       : OUT    std_logic;
      G_DIR       : OUT    std_logic;
      G_DOUT      : OUT    std_logic_vector (1 DOWNTO 0);
      G_DIN       : IN     std_logic_vector (1 DOWNTO 0);
      D_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);
      D_LEV       : OUT    std_logic;
      D_DIR       : OUT    std_logic;
      D_DIN       : IN     std_logic_vector (31 DOWNTO 0);
      D_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);
      E_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);
      E_LEV       : OUT    std_logic;
      E_DIR       : OUT    std_logic;
      E_DIN       : IN     std_logic_vector (31 DOWNTO 0);
      E_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);
      F_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);
      F_LEV       : OUT    std_logic;
      F_DIR       : OUT    std_logic;
      F_DIN       : IN     std_logic_vector (31 DOWNTO 0);
      F_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);
      PDL_WR      : OUT    std_logic;
      PDL_SEL     : OUT    std_logic;
      PDL_READ    : IN     std_logic_vector ( 7 DOWNTO 0);
      PDL_WRITE   : OUT    std_logic_vector ( 7 DOWNTO 0);
      PDL_DIR     : OUT    std_logic;
      PDL0_OUT    : IN     std_logic;
      PDL1_OUT    : IN     std_logic;
      DLO0_OUT    : IN     std_logic;
      DLO1_OUT    : IN     std_logic;
      PDL0_IN     : OUT    std_logic;
      PDL1_IN     : OUT    std_logic;
      DLO0_GATE   : OUT    std_logic;
      DLO1_GATE   : OUT    std_logic;
      SPARE_OUT    : OUT   std_logic_vector(11 downto 0);
      SPARE_IN     : IN    std_logic_vector(11 downto 0);
      SPARE_DIR    : OUT   std_logic_vector(11 downto 0);
      RED_PULSE       : OUT    std_logic;
      GREEN_PULSE     : OUT    std_logic
   );
END coin_reference;

ARCHITECTURE rtl OF coin_reference IS

   component sys_pull
      port (
         inclk0 : in  std_logic;
         c0     : out std_logic;
         locked : out std_logic
      );
   end component;

   signal FAST_CLK   : std_logic;
   signal PLL_LOCKED : std_logic;

   constant FWID_CONST : std_logic_vector(15 downto 0) := X"D617";
   constant N_CH        : integer := 9;   -- F1-F7 (0-6), G0 (7), G1 (8)

   type state_t    is (ST_IDLE, ST_DLY, ST_WID);
   type state_arr  is array (0 to N_CH-1) of state_t;
   type reg16_arr  is array (0 to N_CH-1) of std_logic_vector(15 downto 0);

   signal SCRATCH    : std_logic_vector(15 downto 0);
   signal G_CONTROL  : std_logic_vector(15 downto 0);
   signal F_CONTROL  : std_logic_vector(15 downto 0);

   signal CH_DELAY   : reg16_arr;
   signal CH_WIDTH   : reg16_arr;
   signal CH_CNT     : reg16_arr;
   signal CH_STATE   : state_arr;
   signal CH_OUT     : std_logic_vector(N_CH-1 downto 0);

   signal TRIG_RAW   : std_logic;
   signal TRIG_SYNC  : std_logic_vector(2 downto 0);
   signal TRIG_EDGE  : std_logic;
   signal TRIG_LATCH : std_logic;   -- diagnostic: sticky, set on edge, cleared by SW

   signal TEST_MODE  : std_logic;
   signal F_RAW      : std_logic_vector(31 downto 0);

BEGIN

   --*************************************************
   -- PLL: multiplies LCLK (40 MHz) up to FAST_CLK (x4 -> 160 MHz here)
   --*************************************************
   u_pll : sys_pull
      port map (
         inclk0 => LCLK,
         c0     => FAST_CLK,
         locked => PLL_LOCKED
      );

   --*************************************************
   -- UNUSED PORTS: tied off safely
   --*************************************************
   SPARE_OUT <= (others => '0');
   SPARE_DIR <= (others => '1');
   RED_PULSE <= '0';
   GREEN_PULSE <= OR_REDUCE(CH_OUT);

   C_DOUT <= (others => '0');

   D_LEV  <= '0';
   D_DIR  <= '0';
   D_DOUT <= (others => '0');
   E_LEV  <= '0';
   E_DIR  <= '0';
   E_DOUT <= (others => '0');

   PDL_WR    <= '0';
   PDL_SEL   <= '0';
   PDL_WRITE <= (others => '0');
   PDL_DIR   <= '1';
   PDL0_IN   <= '0';
   PDL1_IN   <= '0';
   DLO0_GATE <= '0';
   DLO1_GATE <= '0';

   --*************************************************
   -- PORT G: 2x independent NIM outputs (G0=idx7, G1=idx8)
   --*************************************************
   G_LEV  <= G_CONTROL(0);   -- write 0x0001 for NIM
   G_DIR  <= '0';            -- output (manual: 0=>Output, 1=>Input)
   G_DOUT(0) <= CH_OUT(7);   -- G0
   G_DOUT(1) <= CH_OUT(8);   -- G1

   --*************************************************
   -- PORT F: ch0 = TTL trigger input, ch1-7 = independent TTL outputs
   --*************************************************
   F_LEV  <= F_CONTROL(0);   -- write 0x0000 for TTL
   F_DIR  <= '0';            -- whole port OUTPUT; ch0 stays readable via
                              -- the A395D's recessive output stage below

   -- F0 (DOUT bit 0) permanently released -- makes it a passive input
   process(TEST_MODE, F_RAW, CH_OUT)
   begin
      if TEST_MODE = '1' then
         F_DOUT <= F_RAW;
      else
         F_DOUT <= (others => '0');
         F_DOUT(0) <= '0';        -- F0 released (trigger input)
         F_DOUT(1) <= CH_OUT(0);  -- F1
         F_DOUT(2) <= CH_OUT(1);  -- F2
         F_DOUT(3) <= CH_OUT(2);  -- F3
         F_DOUT(4) <= CH_OUT(3);  -- F4
         F_DOUT(5) <= CH_OUT(4);  -- F5
         F_DOUT(6) <= CH_OUT(5);  -- F6
         F_DOUT(7) <= CH_OUT(6);  -- F7
      end if;
   end process;

   -- F0 trigger input, DIN bit 0 (1:1 mapping). TTL IN = direct, no invert.
   TRIG_RAW <= F_DIN(0);

   --*************************************************
   -- Trigger synchronizer + rising-edge detect (now FAST_CLK domain)
   --*************************************************
   process(FAST_CLK, nLBRES)
   begin
      if nLBRES = '0' or PLL_LOCKED = '0' then
         TRIG_SYNC <= (others => '0');
      elsif FAST_CLK'event and FAST_CLK = '1' then
         TRIG_SYNC <= TRIG_SYNC(1 downto 0) & TRIG_RAW;
      end if;
   end process;
   TRIG_EDGE <= TRIG_SYNC(1) and not TRIG_SYNC(2);

   --*************************************************
   -- DIAGNOSTIC: sticky trigger-seen latch (FAST_CLK domain)
   --*************************************************
   process(FAST_CLK, nLBRES)
   begin
      if nLBRES = '0' or PLL_LOCKED = '0' then
         TRIG_LATCH <= '0';
      elsif FAST_CLK'event and FAST_CLK = '1' then
         if TRIG_EDGE = '1' then
            TRIG_LATCH <= '1';
         elsif (REG_WREN = '1') and (USR_ACCESS = '1') and (REG_ADDR = X"1054") then
            TRIG_LATCH <= '0';
         end if;
      end if;
   end process;

   --*************************************************
   -- Per-channel delay + width generator (9x, fully independent, FAST_CLK)
   --*************************************************
   gen_ch : for i in 0 to N_CH-1 generate
      process(FAST_CLK, nLBRES)
      begin
         if nLBRES = '0' or PLL_LOCKED = '0' then
            CH_STATE(i) <= ST_IDLE;
            CH_CNT(i)   <= (others => '0');
            CH_OUT(i)   <= '0';
         elsif FAST_CLK'event and FAST_CLK = '1' then
            case CH_STATE(i) is

               when ST_IDLE =>
                  CH_OUT(i) <= '0';
                  if TRIG_EDGE = '1' then
                     CH_STATE(i) <= ST_DLY;
                     CH_CNT(i)   <= (others => '0');
                  end if;

               when ST_DLY =>
                  if (CH_DELAY(i) = X"0000") or (CH_CNT(i) = CH_DELAY(i) - 1) then
                     CH_STATE(i) <= ST_WID;
                     CH_CNT(i)   <= (others => '0');
                     CH_OUT(i)   <= '1';
                  else
                     CH_CNT(i) <= CH_CNT(i) + 1;
                  end if;

               when ST_WID =>
                  if (CH_WIDTH(i) = X"0000") or (CH_CNT(i) = CH_WIDTH(i) - 1) then
                     CH_STATE(i) <= ST_IDLE;
                     CH_OUT(i)   <= '0';
                  else
                     CH_CNT(i) <= CH_CNT(i) + 1;
                  end if;

            end case;
         end if;
      end process;
   end generate;

   --*************************************************
   -- REGISTER WRITE (FAST_CLK domain -- same clock the channels read on,
   -- so no CDC synchronizer needed for CH_DELAY/CH_WIDTH)
   --*************************************************
   P_WREG : process(FAST_CLK, nLBRES)
   begin
      if nLBRES = '0' or PLL_LOCKED = '0' then
         SCRATCH     <= X"5A5A";
         G_CONTROL   <= X"0000";
         F_CONTROL   <= X"0000";
         TEST_MODE   <= '0';
         F_RAW       <= (others => '0');
         for i in 0 to N_CH-1 loop
            CH_DELAY(i) <= X"0000";
            CH_WIDTH(i) <= X"0004";
         end loop;
      elsif FAST_CLK'event and FAST_CLK = '1' then
         if (REG_WREN = '1') and (USR_ACCESS = '1') then
            case REG_ADDR is
               when X"1020" => SCRATCH   <= REG_DIN;
               when X"1022" => G_CONTROL <= REG_DIN;
               when X"1034" => F_CONTROL <= REG_DIN;
               when X"1090" => F_RAW(15 downto 0)  <= REG_DIN;
               when X"1092" => F_RAW(31 downto 16) <= REG_DIN;
               when X"1094" => TEST_MODE <= REG_DIN(0);
               when X"1060" => CH_DELAY(0) <= REG_DIN;  -- F1
               when X"1062" => CH_WIDTH(0) <= REG_DIN;
               when X"1064" => CH_DELAY(1) <= REG_DIN;  -- F2
               when X"1066" => CH_WIDTH(1) <= REG_DIN;
               when X"1068" => CH_DELAY(2) <= REG_DIN;  -- F3
               when X"106A" => CH_WIDTH(2) <= REG_DIN;
               when X"106C" => CH_DELAY(3) <= REG_DIN;  -- F4
               when X"106E" => CH_WIDTH(3) <= REG_DIN;
               when X"1070" => CH_DELAY(4) <= REG_DIN;  -- F5
               when X"1072" => CH_WIDTH(4) <= REG_DIN;
               when X"1074" => CH_DELAY(5) <= REG_DIN;  -- F6
               when X"1076" => CH_WIDTH(5) <= REG_DIN;
               when X"1078" => CH_DELAY(6) <= REG_DIN;  -- F7
               when X"107A" => CH_WIDTH(6) <= REG_DIN;
               when X"107C" => CH_DELAY(7) <= REG_DIN;  -- G0
               when X"107E" => CH_WIDTH(7) <= REG_DIN;
               when X"1080" => CH_DELAY(8) <= REG_DIN;  -- G1
               when X"1082" => CH_WIDTH(8) <= REG_DIN;
               when others  => null;
            end case;
         end if;
      end if;
   end process;

   --*************************************************
   -- REGISTER READ (FAST_CLK domain)
   --*************************************************
   P_RREG : process(FAST_CLK, nLBRES)
   begin
      if nLBRES = '0' or PLL_LOCKED = '0' then
         REG_DOUT <= (others => '0');
      elsif FAST_CLK'event and FAST_CLK = '1' then
         if (REG_RDEN = '1') and (USR_ACCESS = '1') then
            case REG_ADDR is
               when X"1020" => REG_DOUT <= SCRATCH;
               when X"1050" => REG_DOUT <= FWID_CONST;
               when X"1022" => REG_DOUT <= G_CONTROL;
               when X"1034" => REG_DOUT <= F_CONTROL;
               when X"1054" => REG_DOUT <= X"000" & "00" & TRIG_LATCH & TRIG_RAW;
               when X"1090" => REG_DOUT <= F_RAW(15 downto 0);
               when X"1092" => REG_DOUT <= F_RAW(31 downto 16);
               when X"1094" => REG_DOUT <= X"000" & "000" & TEST_MODE;
               when X"1096" => REG_DOUT <= F_DIN(15 downto 0);
               when X"1098" => REG_DOUT <= F_DIN(31 downto 16);
               when X"1060" => REG_DOUT <= CH_DELAY(0);
               when X"1062" => REG_DOUT <= CH_WIDTH(0);
               when X"1064" => REG_DOUT <= CH_DELAY(1);
               when X"1066" => REG_DOUT <= CH_WIDTH(1);
               when X"1068" => REG_DOUT <= CH_DELAY(2);
               when X"106A" => REG_DOUT <= CH_WIDTH(2);
               when X"106C" => REG_DOUT <= CH_DELAY(3);
               when X"106E" => REG_DOUT <= CH_WIDTH(3);
               when X"1070" => REG_DOUT <= CH_DELAY(4);
               when X"1072" => REG_DOUT <= CH_WIDTH(4);
               when X"1074" => REG_DOUT <= CH_DELAY(5);
               when X"1076" => REG_DOUT <= CH_WIDTH(5);
               when X"1078" => REG_DOUT <= CH_DELAY(6);
               when X"107A" => REG_DOUT <= CH_WIDTH(6);
               when X"107C" => REG_DOUT <= CH_DELAY(7);
               when X"107E" => REG_DOUT <= CH_WIDTH(7);
               when X"1080" => REG_DOUT <= CH_DELAY(8);
               when X"1082" => REG_DOUT <= CH_WIDTH(8);
               when others  => REG_DOUT <= (others => '0');
            end case;
         end if;
      end if;
   end process;

END rtl;