-------------------------------------------------------------------------------
-- COPYRIGHT (c) SOLECTRIX GmbH, Germany, %TPL_YEAR%            All rights reserved
--
-- The copyright to the document(s) herein is the property of SOLECTRIX GmbH
-- The document(s) may be used and/or copied only with the written permission
-- from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
-- in the agreement/contract under which the document(s) have been supplied
-------------------------------------------------------------------------------
-- Project  : %TPL_PROJECT%
-- File     : %TPL_VHDLFILE%
-- Created  : %TPL_DATE%
-- Standard : VHDL'93/02
-------------------------------------------------------------------------------
--*
--*  @short Wishbone register module
--*         Auto-generated by '%TPL_SCRIPT%' based on '%TPL_TPLFILE%'
--*
--*   Needed Libraries and Packages:
--*   @li ieee.std_logic_1164 standard multi-value logic package
--*   @li ieee.numeric_std
--*
--* @author %TPL_USER%
--* @date %TPL_DATE%
--* @internal
--/
-------------------------------------------------------------------------------
-- Modification history :
-- Date        Author & Description
-- %TPL_DATE%  %TPL_USER%: Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
%TPL_LIBRARY%
-------------------------------------------------------------------------------

ENTITY %TPL_MODULE% IS
  GENERIC (
    g_addr_bits : INTEGER := %TPL_WBSIZE%);
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
    %TPL_PORTS%
    );
END ENTITY %TPL_MODULE%;

-------------------------------------------------------------------------------

ARCHITECTURE rtl OF %TPL_MODULE% IS

  -----------------------------------------------------------------------------
  -- Procedures
  -----------------------------------------------------------------------------

  %TPL_PROCEDURES%

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------

  %TPL_CONSTANTS%

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

  %TPL_REGISTERS%

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
    %TPL_ADDR_VALIDATION%
    '0' WHEN OTHERS;

  -----------------------------------------------------------------------------
  --* purpose : register access
  --* type    : sequential, rising edge, high active synchronous reset
  reg_access : PROCESS (clk)
  BEGIN  -- PROCESS reg_access
    IF rising_edge(clk) THEN
      -- default values / clear trigger signals
      %TPL_REG_DEFAULT%

      -- WRITE registers
      CASE to_integer(s_int_addr) IS
        %TPL_REG_WR%
        WHEN OTHERS => NULL;
      END CASE;

      -- READ-ONLY registers (override WRITE registers)
      %TPL_REG_RD%

    END IF;
  END PROCESS reg_access;

  -----------------------------------------------------------------------------
  -- WB output data multiplexer
  WITH to_integer(s_wb_addr) SELECT
    s_int_data_rb <=
    %TPL_REG_DATA_OUT%
    (OTHERS => '0')                           WHEN OTHERS;

  -----------------------------------------------------------------------------
  -- output mappings
  %TPL_PORT_REG_OUT%

END ARCHITECTURE rtl;