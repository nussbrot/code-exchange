-------------------------------------------------------------------------------
-- COPYRIGHT (c) SOLECTRIX GmbH, Germany, 2017            All rights reserved
--
-- The copyright to the document(s) herein is the property of SOLECTRIX GmbH
-- The document(s) may be used AND/OR copied only with the written permission
-- from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
-- in the agreement/contract under which the document(s) have been supplied
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY wb_traffic_supervision IS
  GENERIC (
    g_priority      : INTEGER;
    g_tot_priority  : INTEGER);
  PORT (
    clk             : IN  STD_LOGIC;
    rst_n           : IN  STD_LOGIC := '1';
    i_bg            : IN  STD_LOGIC;       -- bus grant
    i_ce            : IN  STD_LOGIC;       -- clock enable
    o_traffic_limit : OUT STD_LOGIC);
END ENTITY wb_traffic_supervision;

ARCHITECTURE rtl OF wb_traffic_supervision IS
  SIGNAL s_shreg  : STD_LOGIC_VECTOR(g_tot_priority - 1 DOWNTO 0)
                    := (OTHERS => '0');
  SIGNAL s_cntr   : INTEGER RANGE 0 TO g_tot_priority;

BEGIN  -- rtl

  -- purpose: holds information of usage of latest cycles
  -- type   : sequential, no reset, rising clock edge
  sh_reg : PROCESS (clk)
  BEGIN  -- process shreg
    IF (clk'EVENT AND clk = '1') THEN
      IF (i_ce = '1') THEN
        s_shreg <= s_shreg(g_tot_priority - 2 DOWNTO 0) & i_bg;
      END IF;
    END IF;
  END PROCESS sh_reg;

  -- purpose: keeps track of used cycles
  -- type   : sequential, rising edge, mixed type reset
  counter : PROCESS (clk, rst_n)
  BEGIN  -- process counter
    IF (rst_n = '0') THEN
      s_cntr          <= 0;
      o_traffic_limit <= '0';
    ELSIF (clk'EVENT AND clk = '1') THEN
      IF (i_ce = '1') THEN
        IF ((i_bg = '1') AND (s_shreg(g_tot_priority - 1) /= '1')) THEN
          s_cntr <= s_cntr + 1;
          if (s_cntr = g_priority - 1) THEN
            o_traffic_limit <= '1';
          END IF;
        ELSIF ((i_bg = '0') AND (s_shreg(g_tot_priority - 1) = '1')) THEN
          s_cntr <= s_cntr - 1;
          IF (s_cntr = g_priority) THEN
            o_traffic_limit <= '0';
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS counter;

END ARCHITECTURE rtl;
