-------------------------------------------------------------------------------
-- COPYRIGHT (c) SOLECTRIX GmbH, Germany, 2017            All rights reserved
--
-- The copyright to the document(s) herein is the property of SOLECTRIX GmbH
-- The document(s) may be used and/or copied only with the written permission
-- from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
-- in the agreement/contract under which the document(s) have been supplied
-------------------------------------------------------------------------------
-- Project  : glb_lib
-- File     : wbs_test_notify.vhd
-- Created  : 18.05.2017
-- Standard : VHDL'93/02
-------------------------------------------------------------------------------
--*
--*  @short Wishbone register module
--*         Auto-generated by 'export_wbs.tcl' based on '../../../../sxl/tpl/wb_reg_no_rst_notify.tpl.vhd'
--*
--*   Needed Libraries and Packages:
--*   @li ieee.std_logic_1164 standard multi-value logic package
--*   @li ieee.numeric_std
--*
--* @author rhallmen
--* @date 30.06.2016
--* @internal
--/
-------------------------------------------------------------------------------
-- Modification history :
-- Date        Author & Description
-- 18.05.2017  rhallmen: Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-------------------------------------------------------------------------------

ENTITY wbs_test_notify IS
  GENERIC (
    g_addr_bits : INTEGER := 8);
  PORT (
    -- Wishbone interface
    clk                       : IN  STD_LOGIC;
    i_wb_cyc                  : IN  STD_LOGIC;
    i_wb_stb                  : IN  STD_LOGIC;
    i_wb_we                   : IN  STD_LOGIC;
    i_wb_sel                  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
    i_wb_addr                 : IN  STD_LOGIC_VECTOR(g_addr_bits-1 DOWNTO 0);
    i_wb_data                 : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    o_wb_data                 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    o_wb_ack                  : OUT STD_LOGIC;
    o_wb_rty                  : OUT STD_LOGIC;
    o_wb_err                  : OUT STD_LOGIC;
    -- Custom ports
    o_rw_slice0               : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    o_rw_slice1               : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    o_rw_bit                  : OUT STD_LOGIC;
    i_ro_slice0               : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    i_ro_slice1               : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    i_ro_bit                  : IN  STD_LOGIC;
    o_wo_slice0               : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    o_wo_slice1               : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    o_wo_bit                  : OUT STD_LOGIC;
    o_tr_slice0               : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    o_tr_slice1               : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    o_tr_bit                  : OUT STD_LOGIC;
    o_en_bit                  : OUT STD_LOGIC;
    o_en_slice                : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    o_no_rw_rw_bit            : OUT STD_LOGIC;
    o_no_rw_rw_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    i_no_rw_ro_bit            : IN  STD_LOGIC;
    i_no_rw_ro_slice          : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_no_rw_wo_bit            : OUT STD_LOGIC;
    o_no_rw_wo_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_no_rw_tr_bit            : OUT STD_LOGIC;
    o_no_rw_tr_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_notify_rw_trd           : OUT STD_LOGIC;
    o_notify_rw_twr           : OUT STD_LOGIC;
    o_no_ro_rw_bit            : OUT STD_LOGIC;
    o_no_ro_rw_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    i_no_ro_ro_bit            : IN  STD_LOGIC;
    i_no_ro_ro_slice          : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_no_ro_wo_bit            : OUT STD_LOGIC;
    o_no_ro_wo_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_no_ro_tr_bit            : OUT STD_LOGIC;
    o_no_ro_tr_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_notify_ro_trd           : OUT STD_LOGIC;
    o_no_wo_rw_bit            : OUT STD_LOGIC;
    o_no_wo_rw_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    i_no_wo_ro_bit            : IN  STD_LOGIC;
    i_no_wo_ro_slice          : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_no_wo_wo_bit            : OUT STD_LOGIC;
    o_no_wo_wo_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_no_wo_tr_bit            : OUT STD_LOGIC;
    o_no_wo_tr_slice          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_notify_wo_twr           : OUT STD_LOGIC;
    o_const_bit0              : OUT STD_LOGIC;
    o_const_bit1              : OUT STD_LOGIC;
    o_const_slice0            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    o_const_slice1            : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
    );
END ENTITY wbs_test_notify;

-------------------------------------------------------------------------------

ARCHITECTURE rtl OF wbs_test_notify IS

  -----------------------------------------------------------------------------
  -- Procedures
  -----------------------------------------------------------------------------

  -- Write access to 32bit register
  PROCEDURE set_reg (
    i_wr_data     : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_wr_en       : IN    STD_LOGIC_VECTOR(3 DOWNTO 0);
    i_wr_mask     : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s_reg  : INOUT STD_LOGIC_VECTOR) IS
  BEGIN
    FOR i IN s_reg'RANGE LOOP
      IF (i_wr_mask(i) = '1' AND i_wr_en(i/8) = '1') THEN
        s_reg(i) <= i_wr_data(i);
      END IF;
    END LOOP;
  END PROCEDURE set_reg;

  -- Write access to single bit register.
  -- Since the index is lost, we rely on the mask to set the correct value.
  PROCEDURE set_reg (
    i_wr_data     : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_wr_en       : IN    STD_LOGIC_VECTOR(3 DOWNTO 0);
    i_wr_mask     : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s_reg  : INOUT STD_LOGIC) IS
  BEGIN
    FOR i IN i_wr_mask'RANGE LOOP
      IF (i_wr_mask(i) = '1' AND i_wr_en(i/8) = '1') THEN
        s_reg <= i_wr_data(i);
      END IF;
    END LOOP;
  END PROCEDURE set_reg;

  -- Write access to single trigger signal
  PROCEDURE set_trg (
    i_wr_data          : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_wr_en            : IN    STD_LOGIC_VECTOR(3 DOWNTO 0);
    CONSTANT c_wr_mask : IN    NATURAL RANGE 0 TO 31;
    SIGNAL   s_flag    : INOUT STD_LOGIC) IS
  BEGIN
    IF (i_wr_en(c_wr_mask/8) = '1' AND i_wr_data(c_wr_mask) = '1') THEN
      s_flag <= '1';
    ELSE
      s_flag <= '0';
    END IF;
  END PROCEDURE set_trg;

  -- Write access to trigger signal vector
  PROCEDURE set_trg (
    i_wr_data          : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_wr_en            : IN    STD_LOGIC_VECTOR(3 DOWNTO 0);
    CONSTANT c_wr_mask : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL   s_flag    : INOUT STD_LOGIC_VECTOR) IS
  BEGIN
    FOR i IN 0 TO 31 LOOP
      IF (c_wr_mask(i) = '1') THEN
        IF (i_wr_en(i/8) = '1' AND i_wr_data(i) = '1') THEN
          s_flag(i) <= '1';
        ELSE
          s_flag(i) <= '0';
        END IF;
      END IF;
    END LOOP;
  END PROCEDURE set_trg;

  -- Drive Trigger On Write signal
  PROCEDURE set_twr (
    i_wr_en       : IN  STD_LOGIC;
    SIGNAL s_flag : OUT STD_LOGIC) IS
  BEGIN  -- PROCEDURE set_twr
    IF (i_wr_en = '1') THEN
      s_flag <= '1';
    ELSE
      s_flag <= '0';
    END IF;
  END PROCEDURE set_twr;

  -- Drive Trigger On Read signal
  PROCEDURE set_trd (
    i_rd_en       : IN  STD_LOGIC;
    SIGNAL s_flag : OUT STD_LOGIC) IS
  BEGIN  -- PROCEDURE set_trd
    IF (i_rd_en = '1') THEN
      s_flag <= '1';
    ELSE
      s_flag <= '0';
    END IF;
  END PROCEDURE set_trd;

  -- helper to cast integer to slv
  FUNCTION f_reset_cast(number : NATURAL; len : POSITIVE)
      RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN STD_LOGIC_VECTOR(to_unsigned(number, len));
  END FUNCTION f_reset_cast;
  

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------

  CONSTANT c_addr_read_write            : INTEGER := 16#0000#;
  CONSTANT c_addr_read_only             : INTEGER := 16#0004#;
  CONSTANT c_addr_write_only            : INTEGER := 16#0008#;
  CONSTANT c_addr_trigger               : INTEGER := 16#000C#;
  CONSTANT c_addr_enum                  : INTEGER := 16#0010#;
  CONSTANT c_addr_notify_rw             : INTEGER := 16#0014#;
  CONSTANT c_addr_notify_ro             : INTEGER := 16#0018#;
  CONSTANT c_addr_notify_wo             : INTEGER := 16#001C#;
  CONSTANT c_addr_const                 : INTEGER := 16#0020#;
  CONSTANT c_has_read_notifies          : BOOLEAN := TRUE;

  -----------------------------------------------------------------------------
  -- WB interface signals
  -----------------------------------------------------------------------------

  SIGNAL s_wb_ack         : STD_LOGIC;
  SIGNAL s_wb_err         : STD_LOGIC;
  SIGNAL s_wb_addr        : UNSIGNED(i_wb_addr'HIGH DOWNTO 0);
  SIGNAL s_int_addr       : UNSIGNED(i_wb_addr'HIGH DOWNTO 0);
  SIGNAL s_int_data       : STD_LOGIC_VECTOR(i_wb_data'RANGE);
  SIGNAL s_int_we         : STD_LOGIC_VECTOR(i_wb_sel'RANGE);
  SIGNAL s_int_trd        : STD_LOGIC;
  SIGNAL s_int_twr        : STD_LOGIC;
  SIGNAL s_int_addr_valid : STD_LOGIC;
  SIGNAL s_int_data_rb    : STD_LOGIC_VECTOR(i_wb_data'RANGE);
  SIGNAL s_wb_data        : STD_LOGIC_VECTOR(o_wb_data'RANGE);

  TYPE t_wb_state IS (e_idle, e_delay, e_ack);
  SIGNAL s_wb_state : t_wb_state := e_idle;

  -----------------------------------------------------------------------------
  -- Custom registers
  -----------------------------------------------------------------------------

  SIGNAL s_rw_rw_slice0                 : STD_LOGIC_VECTOR(31 DOWNTO 16) := f_reset_cast(0, 16);
  SIGNAL s_rw_rw_slice1                 : STD_LOGIC_VECTOR(15 DOWNTO 8) := f_reset_cast(0, 8);
  SIGNAL s_rw_rw_bit                    : STD_LOGIC := '0';
  SIGNAL s_wo_wo_slice0                 : STD_LOGIC_VECTOR(31 DOWNTO 16) := f_reset_cast(0, 16);
  SIGNAL s_wo_wo_slice1                 : STD_LOGIC_VECTOR(15 DOWNTO 8) := f_reset_cast(0, 8);
  SIGNAL s_wo_wo_bit                    : STD_LOGIC := '0';
  SIGNAL s_trg_tr_slice0                : STD_LOGIC_VECTOR(31 DOWNTO 16) := f_reset_cast(0, 16);
  SIGNAL s_trg_tr_slice1                : STD_LOGIC_VECTOR(15 DOWNTO 8) := f_reset_cast(0, 8);
  SIGNAL s_trg_tr_bit                   : STD_LOGIC := '0';
  SIGNAL s_rw_en_bit                    : STD_LOGIC := '1';
  SIGNAL s_rw_en_slice                  : STD_LOGIC_VECTOR(13 DOWNTO 12) := f_reset_cast(2, 2);
  SIGNAL s_rw_no_rw_rw_bit              : STD_LOGIC := '0';
  SIGNAL s_rw_no_rw_rw_slice            : STD_LOGIC_VECTOR(30 DOWNTO 24) := f_reset_cast(111, 7);
  SIGNAL s_wo_no_rw_wo_bit              : STD_LOGIC := '0';
  SIGNAL s_wo_no_rw_wo_slice            : STD_LOGIC_VECTOR(14 DOWNTO 8) := f_reset_cast(111, 7);
  SIGNAL s_trg_no_rw_tr_bit             : STD_LOGIC := '0';
  SIGNAL s_trg_no_rw_tr_slice           : STD_LOGIC_VECTOR(6 DOWNTO 0) := f_reset_cast(111, 7);
  SIGNAL s_rw_no_ro_rw_bit              : STD_LOGIC := '0';
  SIGNAL s_rw_no_ro_rw_slice            : STD_LOGIC_VECTOR(30 DOWNTO 24) := f_reset_cast(111, 7);
  SIGNAL s_wo_no_ro_wo_bit              : STD_LOGIC := '0';
  SIGNAL s_wo_no_ro_wo_slice            : STD_LOGIC_VECTOR(14 DOWNTO 8) := f_reset_cast(111, 7);
  SIGNAL s_trg_no_ro_tr_bit             : STD_LOGIC := '0';
  SIGNAL s_trg_no_ro_tr_slice           : STD_LOGIC_VECTOR(6 DOWNTO 0) := f_reset_cast(111, 7);
  SIGNAL s_rw_no_wo_rw_bit              : STD_LOGIC := '0';
  SIGNAL s_rw_no_wo_rw_slice            : STD_LOGIC_VECTOR(30 DOWNTO 24) := f_reset_cast(111, 7);
  SIGNAL s_wo_no_wo_wo_bit              : STD_LOGIC := '0';
  SIGNAL s_wo_no_wo_wo_slice            : STD_LOGIC_VECTOR(14 DOWNTO 8) := f_reset_cast(111, 7);
  SIGNAL s_trg_no_wo_tr_bit             : STD_LOGIC := '0';
  SIGNAL s_trg_no_wo_tr_slice           : STD_LOGIC_VECTOR(6 DOWNTO 0) := f_reset_cast(111, 7);
  SIGNAL s_const_const_bit0             : STD_LOGIC := '1';
  SIGNAL s_const_const_bit1             : STD_LOGIC := '0';
  SIGNAL s_const_const_slice0           : STD_LOGIC_VECTOR(31 DOWNTO 24) := f_reset_cast(113, 8);
  SIGNAL s_const_const_slice1           : STD_LOGIC_VECTOR(13 DOWNTO 9) := f_reset_cast(17, 5);

BEGIN  -- ARCHITECTURE rtl

  -----------------------------------------------------------------------------
  --* purpose : Wishbone Bus Control
  --* type    : sequential, rising edge, no reset
  wb_ctrl : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      s_wb_ack   <= '0';
      s_wb_err   <= '0';
      s_int_data <= i_wb_data;
      s_int_addr <= s_wb_addr;
      s_int_we   <= (OTHERS => '0');
      s_int_trd  <= '0';
      s_int_twr  <= '0';

      CASE s_wb_state IS
        WHEN e_idle =>
          -- check if anyone requests access
          IF (i_wb_cyc = '1' AND i_wb_stb = '1') THEN
            -- ack is delayed because we need 3 cycles
            IF (i_wb_we = '1') THEN
              s_wb_ack   <=     s_int_addr_valid;
              s_wb_err   <= NOT s_int_addr_valid;
              s_wb_state <= e_ack;
              s_int_we   <= i_wb_sel;
              s_int_twr  <= '1';
            ELSE
              IF c_has_read_notifies THEN
                s_wb_state <= e_delay;
                s_int_trd <= '1';
              ELSE
                s_wb_ack   <=     s_int_addr_valid;
                s_wb_err   <= NOT s_int_addr_valid;
                s_wb_state <= e_ack;
              END IF;
            END IF;
          END IF;

        WHEN e_delay =>
          s_wb_ack   <=     s_int_addr_valid;
          s_wb_err   <= NOT s_int_addr_valid;
          s_wb_state <= e_ack;

        WHEN e_ack =>
          s_wb_state <= e_idle;

      END CASE;

      s_wb_data  <= s_int_data_rb;
    END IF;
  END PROCESS wb_ctrl;

  s_wb_addr <= UNSIGNED(i_wb_addr);
  o_wb_data <= s_wb_data;
  o_wb_ack  <= s_wb_ack;
  o_wb_err  <= s_wb_err;
  o_wb_rty  <= '0';

  -----------------------------------------------------------------------------
  -- WB address validation
  WITH to_integer(s_wb_addr) SELECT
    s_int_addr_valid <=
    '1' WHEN c_addr_read_write,
    '1' WHEN c_addr_read_only,
    '1' WHEN c_addr_write_only,
    '1' WHEN c_addr_trigger,
    '1' WHEN c_addr_enum,
    '1' WHEN c_addr_notify_rw,
    '1' WHEN c_addr_notify_ro,
    '1' WHEN c_addr_notify_wo,
    '1' WHEN c_addr_const,
    '0' WHEN OTHERS;

  -----------------------------------------------------------------------------
  --* purpose : register access
  --* type    : sequential, rising edge, high active synchronous reset
  reg_access : PROCESS (clk)
  BEGIN  -- PROCESS reg_access
    IF rising_edge(clk) THEN
      -- default values / clear trigger signals
      s_trg_tr_slice0                <= (OTHERS => '0');
      s_trg_tr_slice1                <= (OTHERS => '0');
      s_trg_tr_bit                   <= '0';
      s_trg_no_rw_tr_bit             <= '0';
      s_trg_no_rw_tr_slice           <= (OTHERS => '0');
      s_trg_no_ro_tr_bit             <= '0';
      s_trg_no_ro_tr_slice           <= (OTHERS => '0');
      s_trg_no_wo_tr_bit             <= '0';
      s_trg_no_wo_tr_slice           <= (OTHERS => '0');
      o_notify_rw_trd                <= '0';
      o_notify_rw_twr                <= '0';
      o_notify_ro_trd                <= '0';
      o_notify_wo_twr                <= '0';

      -- WRITE registers
      CASE to_integer(s_int_addr) IS
        WHEN c_addr_read_write        => set_reg(s_int_data, s_int_we, x"FFFF0000", s_rw_rw_slice0);
                                         set_reg(s_int_data, s_int_we, x"0000FF00", s_rw_rw_slice1);
                                         set_reg(s_int_data, s_int_we, x"00000008", s_rw_rw_bit);
        WHEN c_addr_write_only        => set_reg(s_int_data, s_int_we, x"FFFF0000", s_wo_wo_slice0);
                                         set_reg(s_int_data, s_int_we, x"0000FF00", s_wo_wo_slice1);
                                         set_reg(s_int_data, s_int_we, x"00000008", s_wo_wo_bit);
        WHEN c_addr_trigger           => set_trg(s_int_data, s_int_we, x"FFFF0000", s_trg_tr_slice0);
                                         set_trg(s_int_data, s_int_we, x"0000FF00", s_trg_tr_slice1);
                                         set_trg(s_int_data, s_int_we, 3, s_trg_tr_bit);
        WHEN c_addr_enum              => set_reg(s_int_data, s_int_we, x"80000000", s_rw_en_bit);
                                         set_reg(s_int_data, s_int_we, x"00003000", s_rw_en_slice);
        WHEN c_addr_notify_rw         => set_reg(s_int_data, s_int_we, x"80000000", s_rw_no_rw_rw_bit);
                                         set_reg(s_int_data, s_int_we, x"7F000000", s_rw_no_rw_rw_slice);
                                         set_reg(s_int_data, s_int_we, x"00008000", s_wo_no_rw_wo_bit);
                                         set_reg(s_int_data, s_int_we, x"00007F00", s_wo_no_rw_wo_slice);
                                         set_trg(s_int_data, s_int_we, 7, s_trg_no_rw_tr_bit);
                                         set_trg(s_int_data, s_int_we, x"0000007F", s_trg_no_rw_tr_slice);
                                         set_trd(s_int_trd, o_notify_rw_trd);
                                         set_twr(s_int_twr, o_notify_rw_twr);
        WHEN c_addr_notify_ro         => set_reg(s_int_data, s_int_we, x"80000000", s_rw_no_ro_rw_bit);
                                         set_reg(s_int_data, s_int_we, x"7F000000", s_rw_no_ro_rw_slice);
                                         set_reg(s_int_data, s_int_we, x"00008000", s_wo_no_ro_wo_bit);
                                         set_reg(s_int_data, s_int_we, x"00007F00", s_wo_no_ro_wo_slice);
                                         set_trg(s_int_data, s_int_we, 7, s_trg_no_ro_tr_bit);
                                         set_trg(s_int_data, s_int_we, x"0000007F", s_trg_no_ro_tr_slice);
                                         set_trd(s_int_trd, o_notify_ro_trd);
        WHEN c_addr_notify_wo         => set_reg(s_int_data, s_int_we, x"80000000", s_rw_no_wo_rw_bit);
                                         set_reg(s_int_data, s_int_we, x"7F000000", s_rw_no_wo_rw_slice);
                                         set_reg(s_int_data, s_int_we, x"00008000", s_wo_no_wo_wo_bit);
                                         set_reg(s_int_data, s_int_we, x"00007F00", s_wo_no_wo_wo_slice);
                                         set_trg(s_int_data, s_int_we, 7, s_trg_no_wo_tr_bit);
                                         set_trg(s_int_data, s_int_we, x"0000007F", s_trg_no_wo_tr_slice);
                                         set_twr(s_int_twr, o_notify_wo_twr);
        WHEN OTHERS => NULL;
      END CASE;
    END IF;
  END PROCESS reg_access;

  -----------------------------------------------------------------------------
  p_comb_read_mux : PROCESS(s_wb_addr, s_rw_rw_slice0, s_rw_rw_slice1, s_rw_rw_bit, i_ro_slice0, i_ro_slice1, i_ro_bit, s_rw_en_bit, s_rw_en_slice, s_rw_no_rw_rw_bit, s_rw_no_rw_rw_slice, i_no_rw_ro_bit, i_no_rw_ro_slice, s_rw_no_ro_rw_bit, s_rw_no_ro_rw_slice, i_no_ro_ro_bit, i_no_ro_ro_slice, s_rw_no_wo_rw_bit, s_rw_no_wo_rw_slice, i_no_wo_ro_bit, i_no_wo_ro_slice)
    VARIABLE v_tmp_read_write               : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_tmp_read_only                : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_tmp_enum                     : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_tmp_notify_rw                : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_tmp_notify_ro                : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_tmp_notify_wo                : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_tmp_const                    : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

    -- helper to ease template generation
    PROCEDURE set(
        l_input : STD_LOGIC_VECTOR(31 DOWNTO 0);
        l_mask  : STD_LOGIC_VECTOR(31 DOWNTO 0)) IS
    BEGIN
      s_int_data_rb <= l_input AND l_mask;
    END PROCEDURE;
  BEGIN
    -- READ registers assignments
    v_tmp_read_write(31 DOWNTO 16)          := s_rw_rw_slice0;
    v_tmp_read_write(15 DOWNTO 8)           := s_rw_rw_slice1;
    v_tmp_read_write(3)                     := s_rw_rw_bit;
    v_tmp_read_only(31 DOWNTO 16)           := i_ro_slice0;
    v_tmp_read_only(15 DOWNTO 8)            := i_ro_slice1;
    v_tmp_read_only(3)                      := i_ro_bit;
    v_tmp_enum(31)                          := s_rw_en_bit;
    v_tmp_enum(13 DOWNTO 12)                := s_rw_en_slice;
    v_tmp_notify_rw(31)                     := s_rw_no_rw_rw_bit;
    v_tmp_notify_rw(30 DOWNTO 24)           := s_rw_no_rw_rw_slice;
    v_tmp_notify_rw(23)                     := i_no_rw_ro_bit;
    v_tmp_notify_rw(22 DOWNTO 16)           := i_no_rw_ro_slice;
    v_tmp_notify_ro(31)                     := s_rw_no_ro_rw_bit;
    v_tmp_notify_ro(30 DOWNTO 24)           := s_rw_no_ro_rw_slice;
    v_tmp_notify_ro(23)                     := i_no_ro_ro_bit;
    v_tmp_notify_ro(22 DOWNTO 16)           := i_no_ro_ro_slice;
    v_tmp_notify_wo(31)                     := s_rw_no_wo_rw_bit;
    v_tmp_notify_wo(30 DOWNTO 24)           := s_rw_no_wo_rw_slice;
    v_tmp_notify_wo(23)                     := i_no_wo_ro_bit;
    v_tmp_notify_wo(22 DOWNTO 16)           := i_no_wo_ro_slice;
    v_tmp_const(7)                          := s_const_const_bit0;
    v_tmp_const(6)                          := s_const_const_bit1;
    v_tmp_const(31 DOWNTO 24)               := s_const_const_slice0;
    v_tmp_const(13 DOWNTO 9)                := s_const_const_slice1;

    -- WB output data multiplexer
    CASE to_integer(s_wb_addr) IS
      WHEN c_addr_read_write => set(v_tmp_read_write, x"FFFFFF08");
      WHEN c_addr_read_only => set(v_tmp_read_only, x"FFFFFF08");
      WHEN c_addr_enum => set(v_tmp_enum, x"80003000");
      WHEN c_addr_notify_rw => set(v_tmp_notify_rw, x"FFFF0000");
      WHEN c_addr_notify_ro => set(v_tmp_notify_ro, x"FFFF0000");
      WHEN c_addr_notify_wo => set(v_tmp_notify_wo, x"FFFF0000");
      WHEN c_addr_const => set(v_tmp_const, x"FF003EC0");
      WHEN OTHERS => set((OTHERS => '0'), (OTHERS => '1'));
    END CASE;
  END PROCESS p_comb_read_mux;
  -----------------------------------------------------------------------------

  -- output mappings
  o_rw_slice0               <= s_rw_rw_slice0(31 DOWNTO 16);
  o_rw_slice1               <= s_rw_rw_slice1(15 DOWNTO 8);
  o_rw_bit                  <= s_rw_rw_bit;
  o_wo_slice0               <= s_wo_wo_slice0(31 DOWNTO 16);
  o_wo_slice1               <= s_wo_wo_slice1(15 DOWNTO 8);
  o_wo_bit                  <= s_wo_wo_bit;
  o_tr_slice0               <= s_trg_tr_slice0(31 DOWNTO 16);
  o_tr_slice1               <= s_trg_tr_slice1(15 DOWNTO 8);
  o_tr_bit                  <= s_trg_tr_bit;
  o_en_bit                  <= s_rw_en_bit;
  o_en_slice                <= s_rw_en_slice(13 DOWNTO 12);
  o_no_rw_rw_bit            <= s_rw_no_rw_rw_bit;
  o_no_rw_rw_slice          <= s_rw_no_rw_rw_slice(30 DOWNTO 24);
  o_no_rw_wo_bit            <= s_wo_no_rw_wo_bit;
  o_no_rw_wo_slice          <= s_wo_no_rw_wo_slice(14 DOWNTO 8);
  o_no_rw_tr_bit            <= s_trg_no_rw_tr_bit;
  o_no_rw_tr_slice          <= s_trg_no_rw_tr_slice(6 DOWNTO 0);
  o_no_ro_rw_bit            <= s_rw_no_ro_rw_bit;
  o_no_ro_rw_slice          <= s_rw_no_ro_rw_slice(30 DOWNTO 24);
  o_no_ro_wo_bit            <= s_wo_no_ro_wo_bit;
  o_no_ro_wo_slice          <= s_wo_no_ro_wo_slice(14 DOWNTO 8);
  o_no_ro_tr_bit            <= s_trg_no_ro_tr_bit;
  o_no_ro_tr_slice          <= s_trg_no_ro_tr_slice(6 DOWNTO 0);
  o_no_wo_rw_bit            <= s_rw_no_wo_rw_bit;
  o_no_wo_rw_slice          <= s_rw_no_wo_rw_slice(30 DOWNTO 24);
  o_no_wo_wo_bit            <= s_wo_no_wo_wo_bit;
  o_no_wo_wo_slice          <= s_wo_no_wo_wo_slice(14 DOWNTO 8);
  o_no_wo_tr_bit            <= s_trg_no_wo_tr_bit;
  o_no_wo_tr_slice          <= s_trg_no_wo_tr_slice(6 DOWNTO 0);
  o_const_bit0              <= s_const_const_bit0;
  o_const_bit1              <= s_const_const_bit1;
  o_const_slice0            <= s_const_const_slice0(31 DOWNTO 24);
  o_const_slice1            <= s_const_const_slice1(13 DOWNTO 9);

END ARCHITECTURE rtl;

