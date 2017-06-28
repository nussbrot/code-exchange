-------------------------------------------------------------------------------
-- COPYRIGHT (c) SOLECTRIX GmbH, Germany, 2017            All rights reserved
--
-- The copyright to the document(s) herein is the property of SOLECTRIX GmbH
-- The document(s) may be used and/or copied only with the written permission
-- from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
-- in the agreement/contract under which the document(s) have been supplied
-------------------------------------------------------------------------------
-- Project  : glb_lib
-- File     : wbs_cfg_i2c_bridge.vhd
-- Created  : 09.06.2017
-- Standard : VHDL'93/02
-------------------------------------------------------------------------------
--*
--*  @short Wishbone register module
--*         Auto-generated by 'export_wbs.tcl' based on '../../../../sxl/tpl/wb_reg_no_rst.tpl.vhd'
--*
--*   Needed Libraries and Packages:
--*   @li ieee.std_logic_1164 standard multi-value logic package
--*   @li ieee.numeric_std
--*
--* @author sforster
--* @date 30.06.2016
--* @internal
--/
-------------------------------------------------------------------------------
-- Modification history :
-- Date        Author & Description
-- 09.06.2017  sforster: Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-------------------------------------------------------------------------------

ENTITY wbs_cfg_i2c_bridge IS
  GENERIC (
    g_addr_bits : INTEGER := 7);
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
    o_dev_addr                : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_clk_div                 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    i_status                  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY wbs_cfg_i2c_bridge;

-------------------------------------------------------------------------------

ARCHITECTURE rtl OF wbs_cfg_i2c_bridge IS

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

  CONSTANT c_addr_config                : INTEGER := 16#0000#;
  CONSTANT c_addr_status                : INTEGER := 16#0004#;
  CONSTANT c_has_read_notifies          : BOOLEAN := FALSE;

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

  -----------------------------------------------------------------------------
  -- Custom registers
  -----------------------------------------------------------------------------

  SIGNAL s_reg_config                   : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00200010";
  SIGNAL s_reg_status                   : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
  

BEGIN  -- ARCHITECTURE rtl

  -----------------------------------------------------------------------------
  --* purpose : Wishbone Bus Control
  --* type    : sequential, rising edge, no reset
  wb_ctrl : PROCESS (clk)
  BEGIN  -- PROCESS wb_ctrl
    IF rising_edge(clk) THEN
      s_wb_ack   <= '0';
      s_wb_err   <= '0';
      s_int_data <= i_wb_data;
      s_int_addr <= s_wb_addr;
      s_int_we   <= (OTHERS => '0');
      s_int_trd  <= '0';
      s_int_twr  <= '0';
      -- check if anyone requests access
      IF (s_wb_ack = '0' AND s_wb_err = '0' AND i_wb_cyc = '1' AND i_wb_stb = '1') THEN
        s_wb_ack <=     s_int_addr_valid;
        s_wb_err <= NOT s_int_addr_valid;
        IF (i_wb_we = '1') THEN
          s_int_we  <= i_wb_sel;
          s_int_twr <= '1';
        ELSE
          s_int_trd <= '1';
        END IF;
      END IF;
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
    '1' WHEN c_addr_config,
    '1' WHEN c_addr_status,
    '0' WHEN OTHERS;

  -----------------------------------------------------------------------------
  --* purpose : register access
  --* type    : sequential, rising edge, high active synchronous reset
  reg_access : PROCESS (clk)
  BEGIN  -- PROCESS reg_access
    IF rising_edge(clk) THEN
      -- default values / clear trigger signals
      

      -- WRITE registers
      CASE to_integer(s_int_addr) IS
        WHEN c_addr_config            => set_reg(s_int_data, s_int_we, x"FFFF007F", s_reg_config);
        WHEN OTHERS => NULL;
      END CASE;

      -- READ-ONLY registers (override WRITE registers)
      s_reg_status(31 DOWNTO 0)               <= i_status;

    END IF;
  END PROCESS reg_access;

  -----------------------------------------------------------------------------
  -- WB output data multiplexer
  WITH to_integer(s_wb_addr) SELECT
    s_int_data_rb <=
    s_reg_config              AND x"FFFF007F" WHEN c_addr_config,
    s_reg_status              AND x"FFFFFFFF" WHEN c_addr_status,
    (OTHERS => '0')                           WHEN OTHERS;

  -----------------------------------------------------------------------------
  -- output mappings
  o_dev_addr                <= s_reg_config(6 DOWNTO 0);
  o_clk_div                 <= s_reg_config(31 DOWNTO 16);

END ARCHITECTURE rtl;
