-------------------------------------------------------------------------------
-- COPYRIGHT (c) SOLECTRIX GmbH, Germany, 2015            All rights reserved
--
-- The copyright to the document(s) herein is the property of SOLECTRIX GmbH
-- The document(s) may be used and/or copied only with the written permission
-- from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
-- in the agreement/contract under which the document(s) have been supplied
-------------------------------------------------------------------------------
-- Project  : Solectrix Global Library
-- File     : wb_i2c_bridge.vhd
-- Created  : 23.11.2015
-- Standard : VHDL'93/02
-------------------------------------------------------------------------------
--*
--*  @short WB to I2C Master bridge (Byte/Word accesses; 14 Bit address)
--*
--* @author akoehler
--* @date 23.11.2015
--* @internal
--/
-------------------------------------------------------------------------------
-- Modification history :
-- Date        Author & Description
-- 23.11.2015  akoehler: Created
-- 03.05.2016  tstoehr: Update to i2c bridge / makes 8 bit i2c transfers possible
-- 13.05.2016  tstoehr: Updated signal initialisations
-- 18.05.2017  sforster: Rework according to detailed design
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY rtl_lib;

-------------------------------------------------------------------------------

ENTITY wb_i2c_bridge IS
  GENERIC(
    g_transaction_bytes : INTEGER RANGE 1 TO 2 := 1); -- 1: Byte; 2: Word
  PORT (
    -- clock/reset
    clk            : IN  STD_LOGIC;
    rst_n          : IN  STD_LOGIC;
    -- Wishbone slave
    i_wb_cyc       : IN  STD_LOGIC;
    i_wb_stb       : IN  STD_LOGIC;
    i_wb_we        : IN  STD_LOGIC;
    i_wb_sel       : IN  STD_LOGIC_VECTOR(g_transaction_bytes  -1 DOWNTO 0);
    i_wb_addr      : IN  STD_LOGIC_VECTOR(                     13 DOWNTO 0);
    i_wb_data      : IN  STD_LOGIC_VECTOR(g_transaction_bytes*8-1 DOWNTO 0);
    o_wb_data      : OUT STD_LOGIC_VECTOR(g_transaction_bytes*8-1 DOWNTO 0);
    o_wb_ack       : OUT STD_LOGIC;
    -- I2C master
    i_scl_pad      : IN  STD_LOGIC;
    o_scl_pad      : OUT STD_LOGIC;
    o_scl_padoen   : OUT STD_LOGIC;
    i_sda_pad      : IN  STD_LOGIC;
    o_sda_pad      : OUT STD_LOGIC;
    o_sda_padoen   : OUT STD_LOGIC;
    -- configuration
    i_cfg_core_en  : IN  STD_LOGIC := '1';
    i_cfg_clk_div  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    i_cfg_dev_addr : IN  STD_LOGIC_VECTOR( 6 DOWNTO 0);
    -- status/error
    o_status       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    o_err_irq      : OUT STD_LOGIC);
END ENTITY wb_i2c_bridge;

-------------------------------------------------------------------------------

ARCHITECTURE rtl OF wb_i2c_bridge IS
  -----------------------------------------------------------------------------
  -- TYPEs
  -----------------------------------------------------------------------------
  TYPE t_status_reg IS RECORD
    i2c_carrier_idle         : STD_LOGIC;
    i2c_core_idle            : STD_LOGIC;
    i2c_core_en              : STD_LOGIC;
    trx_acc_type             : STD_LOGIC;
    trx_err_nack_rep_dev_adr : STD_LOGIC;
    trx_err_nack_dat_lsb     : STD_LOGIC;
    trx_err_nack_dat_msb     : STD_LOGIC;
    trx_err_nack_adr_lsb     : STD_LOGIC;
    trx_err_nack_adr_msb     : STD_LOGIC;
    trx_err_nack_dev_adr     : STD_LOGIC;
    trx_err_arb_rep_dev_adr  : STD_LOGIC;
    trx_err_arb_restart      : STD_LOGIC;
    trx_err_arb_dat_lsb      : STD_LOGIC;
    trx_err_arb_dat_msb      : STD_LOGIC;
    trx_err_arb_adr_lsb      : STD_LOGIC;
    trx_err_arb_adr_msb      : STD_LOGIC;
    trx_err_arb_dev_adr      : STD_LOGIC;
    trx_err_arb_start        : STD_LOGIC;
    trx_adr_err              : STD_LOGIC;
  END RECORD;
  -----------------------------------------------------------------------------
  TYPE t_fsm_states IS (idle, i2c_start, dev_adr, reg_adr_msb, reg_adr_lsb,
                        tx_reg_dat_msb, tx_reg_dat_lsb, i2c_restart,
                        rep_dev_adr, rx_reg_dat_msb, rx_reg_dat_lsb,
                        abort, i2c_stop, done);
  -----------------------------------------------------------------------------
  -- SIGNALs
  -----------------------------------------------------------------------------
  SIGNAL s_fsm_state  : t_fsm_states;
  SIGNAL s_status_reg : t_status_reg;
  SIGNAL s_trx_error  : STD_LOGIC; -- I2C transmission error
  -- Wishbone
  SIGNAL s_wb_ack   : STD_LOGIC;
  SIGNAL s_wb_dat_o : STD_LOGIC_VECTOR(g_transaction_bytes*8-1 DOWNTO 0);
  -- I2C command/data signals for byte controller
  SIGNAL s_i2c_start    : STD_LOGIC;
  SIGNAL s_i2c_stop     : STD_LOGIC;
  SIGNAL s_i2c_read     : STD_LOGIC;
  SIGNAL s_i2c_write    : STD_LOGIC;
  SIGNAL s_i2c_ack_in   : STD_LOGIC;
  SIGNAL s_i2c_cmd_done : STD_LOGIC;
  SIGNAL s_i2c_ack_out  : STD_LOGIC;
  SIGNAL s_i2c_busy     : STD_LOGIC;
  SIGNAL s_i2c_al       : STD_LOGIC; -- arbitration lost
  SIGNAL s_i2c_din      : STD_LOGIC_VECTOR(7 DOWNTO 0); -- transmit register
  SIGNAL s_i2c_dout     : STD_LOGIC_VECTOR(7 DOWNTO 0); -- receive  register
  -- IRQ
  SIGNAL s_err_irq : STD_LOGIC;
BEGIN
  -----------------------------------------------------------------------------
  -- output assignments
  -----------------------------------------------------------------------------
  o_wb_ack  <= s_wb_ack;
  o_wb_data <= s_wb_dat_o;
  o_err_irq <= s_err_irq;
  --
  o_status(28 DOWNTO 25) <= (OTHERS => '0');
  o_status(23 DOWNTO 15) <= (OTHERS => '0');
  o_status          (31) <= s_status_reg.i2c_carrier_idle;
  o_status          (30) <= s_status_reg.i2c_core_idle;
  o_status          (29) <= s_status_reg.i2c_core_en;
  o_status          (24) <= s_status_reg.trx_acc_type;
  o_status          (14) <= s_status_reg.trx_err_nack_rep_dev_adr;
  o_status          (13) <= s_status_reg.trx_err_nack_dat_lsb;
  o_status          (12) <= s_status_reg.trx_err_nack_dat_msb;
  o_status          (11) <= s_status_reg.trx_err_nack_adr_lsb;
  o_status          (10) <= s_status_reg.trx_err_nack_adr_msb;
  o_status          ( 9) <= s_status_reg.trx_err_nack_dev_adr;
  o_status          ( 8) <= s_status_reg.trx_err_arb_rep_dev_adr;
  o_status          ( 7) <= s_status_reg.trx_err_arb_restart;
  o_status          ( 6) <= s_status_reg.trx_err_arb_dat_lsb;
  o_status          ( 5) <= s_status_reg.trx_err_arb_dat_msb;
  o_status          ( 4) <= s_status_reg.trx_err_arb_adr_lsb;
  o_status          ( 3) <= s_status_reg.trx_err_arb_adr_msb;
  o_status          ( 2) <= s_status_reg.trx_err_arb_dev_adr;
  o_status          ( 1) <= s_status_reg.trx_err_arb_start;
  o_status          ( 0) <= s_status_reg.trx_adr_err;
  -----------------------------------------------------------------------------
  --* purpose : Register
  --* type    : sequential, rising edge, no reset
  -----------------------------------------------------------------------------
  p_reg_data : PROCESS (clk)
  BEGIN
    IF (rising_edge(clk)) THEN
      s_status_reg.i2c_core_en      <= i_cfg_core_en;
      s_status_reg.i2c_core_idle    <= NOT s_i2c_busy;
      s_status_reg.i2c_carrier_idle <= i_scl_pad AND i_sda_pad;
    END IF;
  END PROCESS p_reg_data;
  -----------------------------------------------------------------------------
  --* purpose : I2C core control
  --* type    : sequential, rising edge, low active synchronous reset
  -----------------------------------------------------------------------------
  p_i2c_core_ctrl : PROCESS (clk, rst_n)
  BEGIN
    IF (rst_n = '0') THEN
      s_fsm_state  <= idle;
      s_err_irq    <= '0';
      s_i2c_start  <= '0';
      s_i2c_stop   <= '0';
      s_i2c_write  <= '0';
      s_i2c_read   <= '0';
      s_i2c_ack_in <= '0';
      s_i2c_din    <= (OTHERS => '0');
      s_wb_ack     <= '0';
      s_wb_dat_o   <= (OTHERS => '0');
      s_trx_error  <= '0';
      s_status_reg.trx_acc_type             <= '0';
      s_status_reg.trx_err_nack_rep_dev_adr <= '0';
      s_status_reg.trx_err_nack_dat_lsb     <= '0';
      s_status_reg.trx_err_nack_dat_msb     <= '0';
      s_status_reg.trx_err_nack_adr_lsb     <= '0';
      s_status_reg.trx_err_nack_adr_msb     <= '0';
      s_status_reg.trx_err_nack_dev_adr     <= '0';
      s_status_reg.trx_err_arb_rep_dev_adr  <= '0';
      s_status_reg.trx_err_arb_restart      <= '0';
      s_status_reg.trx_err_arb_dat_lsb      <= '0';
      s_status_reg.trx_err_arb_dat_msb      <= '0';
      s_status_reg.trx_err_arb_adr_lsb      <= '0';
      s_status_reg.trx_err_arb_adr_msb      <= '0';
      s_status_reg.trx_err_arb_dev_adr      <= '0';
      s_status_reg.trx_err_arb_start        <= '0';
      s_status_reg.trx_adr_err              <= '0';
    ELSIF (rising_edge(clk)) THEN
      -- default values
      s_err_irq    <= '0';
      s_wb_ack     <= '0';
      s_i2c_start  <= '0';
      s_i2c_stop   <= '0';
      s_i2c_write  <= '0';
      s_i2c_read   <= '0';
      s_i2c_ack_in <= '0';
      -- FSM
      CASE s_fsm_state IS
        ---------------------------------------------------------------------
        WHEN idle =>
        ---------------------------------------------------------------------
          IF (i_wb_cyc = '1' AND i_wb_stb = '1' AND s_wb_ack = '0') THEN
            -- check WB address: aligned and Byte-select(s) "complete"
            IF ( (SIGNED(i_wb_sel) /= -1) OR
                 (g_transaction_bytes = 2 AND i_wb_addr(0) = '1') ) THEN
              s_fsm_state              <= done;
              s_status_reg.trx_adr_err <= '1';
              s_trx_error              <= '1';
            ELSE
              s_fsm_state              <= i2c_start;
              s_status_reg.trx_adr_err <= '0';
              s_trx_error              <= '0';
            END IF;
            s_wb_dat_o                            <= (OTHERS => '0');
            s_status_reg.trx_acc_type             <= i_wb_we;
            s_status_reg.trx_err_nack_rep_dev_adr <= '0';
            s_status_reg.trx_err_nack_dat_lsb     <= '0';
            s_status_reg.trx_err_nack_dat_msb     <= '0';
            s_status_reg.trx_err_nack_adr_lsb     <= '0';
            s_status_reg.trx_err_nack_adr_msb     <= '0';
            s_status_reg.trx_err_nack_dev_adr     <= '0';
            s_status_reg.trx_err_arb_rep_dev_adr  <= '0';
            s_status_reg.trx_err_arb_restart      <= '0';
            s_status_reg.trx_err_arb_dat_lsb      <= '0';
            s_status_reg.trx_err_arb_dat_msb      <= '0';
            s_status_reg.trx_err_arb_adr_lsb      <= '0';
            s_status_reg.trx_err_arb_adr_msb      <= '0';
            s_status_reg.trx_err_arb_dev_adr      <= '0';
            s_status_reg.trx_err_arb_start        <= '0';
          END IF;
        ---------------------------------------------------------------------
        WHEN i2c_start =>  -- TX I2C start signal
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_start <= '1';
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                    <= done;
              s_status_reg.trx_err_arb_start <= '1';
              s_trx_error                    <= '1';
            ELSE
              s_fsm_state <= dev_adr;
            END IF;
          END IF;
        ---------------------------------------------------------------------
        WHEN dev_adr =>  -- TX device address & write command
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_write <= '1';
            s_i2c_din   <= i_cfg_dev_addr & '0'; -- & '0': write access
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                      <= done;
              s_status_reg.trx_err_arb_dev_adr <= '1';
              s_trx_error                      <= '1';
            ELSIF (s_i2c_ack_out = '1') THEN
              s_fsm_state <= abort;
            ELSE
              s_fsm_state <= reg_adr_msb;
            END IF;
            s_status_reg.trx_err_nack_dev_adr <= s_i2c_ack_out;
          END IF;
        ---------------------------------------------------------------------
        WHEN reg_adr_msb =>  -- TX register address MSB
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_write <= '1';
            s_i2c_din   <= "00" & i_wb_addr(13 DOWNTO 8);
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                      <= done;
              s_status_reg.trx_err_arb_adr_msb <= '1';
              s_trx_error                      <= '1';
            ELSIF (s_i2c_ack_out = '1') THEN
              s_fsm_state <= abort;
            ELSE
              s_fsm_state <= reg_adr_lsb;
            END IF;
            s_status_reg.trx_err_nack_adr_msb <= s_i2c_ack_out;
          END IF;
        ---------------------------------------------------------------------
        WHEN reg_adr_lsb =>  -- TX register address LSB
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_write <= '1';
            s_i2c_din   <= i_wb_addr(7 DOWNTO 0);
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                      <= done;
              s_status_reg.trx_err_arb_adr_lsb <= '1';
              s_trx_error                      <= '1';
            ELSIF (s_i2c_ack_out = '1') THEN
              s_fsm_state <= abort;
            ELSE
              IF (i_wb_we = '1') THEN
                -- transmit 1 Byte
                IF(g_transaction_bytes = 1) THEN
                  s_fsm_state <= tx_reg_dat_lsb;
                -- transmit 2 Bytes
                ELSIF(g_transaction_bytes = 2) THEN
                  s_fsm_state <= tx_reg_dat_msb;
                END IF;
              ELSE
                s_fsm_state <= i2c_restart;
              END IF;
            END IF;
            s_status_reg.trx_err_nack_adr_lsb <= s_i2c_ack_out;
          END IF;
        ---------------------------------------------------------------------
        WHEN tx_reg_dat_msb =>  -- TX device register data MSB
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_write  <= '1';
            s_i2c_din <= i_wb_data(((g_transaction_bytes * 8) - 1) DOWNTO (g_transaction_bytes * 8) - 8);
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                      <= done;
              s_status_reg.trx_err_arb_dat_msb <= '1';
              s_trx_error                      <= '1';
            ELSIF (s_i2c_ack_out = '1') THEN
              s_fsm_state <= abort;
            ELSE
              s_fsm_state <= tx_reg_dat_lsb;
            END IF;
            s_status_reg.trx_err_nack_dat_msb <= s_i2c_ack_out;
          END IF;
        ---------------------------------------------------------------------
        WHEN tx_reg_dat_lsb =>  -- TX device register data LSB
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_write <= '1';
            s_i2c_din   <= i_wb_data(7 DOWNTO 0);
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                      <= done;
              s_status_reg.trx_err_arb_dat_lsb <= '1';
              s_trx_error                      <= '1';
            ELSIF (s_i2c_ack_out = '1') THEN
              s_fsm_state <= abort;
            ELSE
              s_fsm_state <= i2c_stop;
            END IF;
            s_status_reg.trx_err_nack_dat_lsb <= s_i2c_ack_out;
          END IF;
        ---------------------------------------------------------------------
        WHEN i2c_restart =>  -- TX repeat I2C START signal
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_start <= '1';
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                      <= done;
              s_status_reg.trx_err_arb_restart <= '1';
              s_trx_error                      <= '1';
            ELSE
              s_fsm_state <= rep_dev_adr;
            END IF;
          END IF;
        ---------------------------------------------------------------------
        WHEN rep_dev_adr =>  -- TX device address & read command
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_write <= '1';
            s_i2c_din   <= i_cfg_dev_addr & '1'; -- & '1': read access
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                          <= done;
              s_status_reg.trx_err_arb_rep_dev_adr <= '1';
              s_trx_error                      <= '1';
            ELSIF (s_i2c_ack_out = '1') THEN
              s_fsm_state <= abort;
            ELSE
              -- receive 1 Byte
              IF(g_transaction_bytes = 1) THEN
                s_fsm_state <= rx_reg_dat_lsb;
              -- receive 2 Bytes
              ELSIF(g_transaction_bytes = 2) THEN
                s_fsm_state <= rx_reg_dat_msb;
              END IF;
            END IF;
            s_status_reg.trx_err_nack_rep_dev_adr <= s_i2c_ack_out;
          END IF;
        ---------------------------------------------------------------------
        WHEN rx_reg_dat_msb =>  -- RX register data MSB
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_read <= '1';
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                      <= done;
              s_status_reg.trx_err_arb_dat_msb <= '1';
              s_trx_error                      <= '1';
            ELSIF (s_i2c_ack_out = '1') THEN
              s_fsm_state <= abort;
            ELSE
              s_fsm_state <= rx_reg_dat_lsb;
              s_wb_dat_o((g_transaction_bytes*8-1) DOWNTO g_transaction_bytes*8-8) <= s_i2c_dout;
            END IF;
            s_status_reg.trx_err_nack_dat_msb <= s_i2c_ack_out;
          END IF;
        ---------------------------------------------------------------------
        WHEN rx_reg_dat_lsb =>  -- RX register data LSB
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0' AND s_i2c_al = '0') THEN
            s_i2c_read   <= '1';
            s_i2c_ack_in <= '1';
          ELSE
            IF (s_i2c_al = '1') THEN
              s_fsm_state                      <= done;
              s_status_reg.trx_err_arb_dat_lsb <= '1';
              s_trx_error                      <= '1';
--            ELSIF (s_i2c_ack_out = '1') THEN
--              s_fsm_state <= abort;
            ELSE
              s_fsm_state                       <= i2c_stop;
              s_wb_dat_o(7 DOWNTO 0)            <= s_i2c_dout;
            END IF;
            s_status_reg.trx_err_nack_dat_lsb <= NOT s_i2c_ack_out; -- TBD
            s_trx_error                       <= NOT s_i2c_ack_out; -- TBD
          END IF;
        ---------------------------------------------------------------------
        WHEN abort =>  -- TX I2C stop signal
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0') THEN
            s_i2c_stop <= '1';
          ELSE
            s_fsm_state <= done;
          END IF;
          s_trx_error <= '1';
        ---------------------------------------------------------------------
        WHEN i2c_stop =>  -- TX I2C stop signal
        ---------------------------------------------------------------------
          IF (s_i2c_cmd_done = '0') THEN
            s_i2c_stop <= '1';
          ELSE
            s_fsm_state <= done;
          END IF;
        ---------------------------------------------------------------------
        WHEN done =>  -- transfer done
        ---------------------------------------------------------------------
          s_fsm_state <= idle;
          s_err_irq   <= s_trx_error;
          s_wb_ack    <= '1';
      END CASE;
    END IF;
  END PROCESS p_i2c_core_ctrl;
  -----------------------------------------------------------------------------
  -- I2C core (I2C master; Byte transactions)
  -----------------------------------------------------------------------------
  wb_i2c_master_byte_ctrl_1 : ENTITY rtl_lib.wb_i2c_master_byte_ctrl
    PORT MAP (
      clk       => clk,
      rst_n     => rst_n,
      --
      i_ena     => i_cfg_core_en,
      i_clk_cnt => i_cfg_clk_div,
      -- input signals
      i_start   => s_i2c_start,
      i_stop    => s_i2c_stop,
      i_read    => s_i2c_read,
      i_write   => s_i2c_write,
      i_ack_in  => s_i2c_ack_in,
      i_din     => s_i2c_din,
      -- output signals
      o_cmd_done=> s_i2c_cmd_done,
      o_ack_out => s_i2c_ack_out,
      o_i2c_busy=> s_i2c_busy,
      o_i2c_al  => s_i2c_al,
      o_dout    => s_i2c_dout,
      -- i2c lines
      i_scl     => i_scl_pad,
      o_scl     => o_scl_pad,
      o_scl_oen => o_scl_padoen,
      i_sda     => i_sda_pad,
      o_sda     => o_sda_pad,
      o_sda_oen => o_sda_padoen);
  -----------------------------------------------------------------------------

END ARCHITECTURE rtl;
