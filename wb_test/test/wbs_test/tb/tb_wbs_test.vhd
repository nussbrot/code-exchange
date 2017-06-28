-------------------------------------------------------------------------------
-- COPYRIGHT (c) SOLECTRIX GmbH, Germany, 2013            All rights reserved
--
-- The copyright to the document(s) herein is the property of SOLECTRIX GmbH
-- The document(s) may be used and/or copied only with the written permission
-- from SOLECTRIX GmbH or in accordance with the terms/conditions stipulated
-- in the agreement/contract under which the document(s) have been supplied
-------------------------------------------------------------------------------
-- Project  :
-- File     : tb_wbs_test.vhd
-- Created  : 23.11.2016
-- Standard : VHDL 2008
-------------------------------------------------------------------------------
--*
--* @short wbs_test Testbench
--* TestBench for sxl wb generator (tcl)
--*
--* @author mgoertz
--* @date 23.11.2016
--* @internal
--/
-------------------------------------------------------------------------------
-- Modification history :
-- Date        Author & Description
-- 23.11.2016  mgoertz: Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

LIBRARY osvvm;
USE osvvm.RandomPkg.all;

LIBRARY vunit_lib;
CONTEXT vunit_lib.vunit_context;

LIBRARY fun_lib;
USE fun_lib.math_pkg.ALL;

LIBRARY sim_lib;
USE sim_lib.sim_pkg.ALL;
USE sim_lib.wbs_drv_pkg.ALL;

LIBRARY rtl_lib;
LIBRARY tb_lib;

USE STD.textio.ALL;
-------------------------------------------------------------------------------

ENTITY tb_wbs_test IS
  GENERIC(
    runner_cfg       : runner_cfg_t;
    g_system_clk     : REAL     := 150.0E6;
    g_nr_of_writes   : NATURAL  := 10;
    g_data_bits      : POSITIVE := 32;
    g_addr_bits      : INTEGER  := 16;
    g_use_notify_wbs : BOOLEAN := FALSE);

BEGIN
  -- to be checked ...
  ASSERT g_addr_bits MOD 8 = 0
    REPORT "g_addr_bits has to be a multiple of 4!"
    SEVERITY FAILURE;
END ENTITY tb_wbs_test;
-------------------------------------------------------------------------------

ARCHITECTURE tb OF tb_wbs_test IS

  -----------------------------------------------------------------------------
  --
  -----------------------------------------------------------------------------
  SIGNAL clk                  : STD_LOGIC := '0';
  --
  SHARED VARIABLE sv_gen_rdm_writes_start   : sim_lib.sim_pkg.shared_boolean;
  SHARED VARIABLE sv_gen_rdm_writes_done    : sim_lib.sim_pkg.shared_boolean;
  --
  SUBTYPE t_data_word  IS STD_LOGIC_VECTOR(g_data_bits-1 DOWNTO 0);
  PACKAGE array_pkg IS NEW sim_lib.array_pkg
    GENERIC MAP (data_type => t_data_word);

  SHARED VARIABLE sv_memory_array : array_pkg.t_array;


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
  CONSTANT c_addr_invalid               : INTEGER := 16#0088#;
  --
  CONSTANT c_addr_invalid_slv           : STD_LOGIC_VECTOR(g_addr_bits  -1 DOWNTO 0) := std_logic_vector(to_unsigned(c_addr_invalid, g_addr_bits));
  CONSTANT c_wb_sel_max                 : STD_LOGIC_VECTOR(g_data_bits/8-1 DOWNTO 0) := (OTHERS => '1');
  CONSTANT c_wb_dat_max                 : STD_LOGIC_VECTOR(g_data_bits  -1 DOWNTO 0) := (OTHERS => '1');
  CONSTANT c_wb_we_write                : STD_LOGIC := '1';
  CONSTANT c_wb_we_read                 : STD_LOGIC := '0';


  -----------------------------------------------------------------------------
  -- Wishbone driver interface signals
  -----------------------------------------------------------------------------
  SIGNAL s_wbs_drv_out        : t_wbs_drv_out(addr(g_addr_bits-1 DOWNTO 0),
                                                   data(g_data_bits-1 DOWNTO 0),
                                                   sel(g_data_bits/8-1 DOWNTO 0));
  SIGNAL s_wbs_drv_in         : t_wbs_drv_in(data(g_data_bits-1 DOWNTO 0));


  -----------------------------------------------------------------------------
  -- Custom registers Signals
  -----------------------------------------------------------------------------

  SIGNAL s_reg_read_write               : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
  SIGNAL s_reg_read_only                : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
  SIGNAL s_reg_write_only               : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
  SIGNAL s_reg_trigger                  : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
  SIGNAL s_reg_enum                     : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"80002000";
  SIGNAL s_reg_notify_rw                : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"6F6F6F6F";
  SIGNAL s_reg_notify_ro                : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"6F6F6F6F";
  SIGNAL s_reg_notify_wo                : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"6F6F6F6F";


  -----------------------------------------------------------------------------
  -- Custom registers IO Signals
  -----------------------------------------------------------------------------

  SIGNAL s_o_rw_slice0      : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL s_o_rw_slice1      : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_o_rw_bit         : STD_LOGIC;
  SIGNAL s_i_ro_slice0      : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL s_i_ro_slice1      : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_i_ro_bit         : STD_LOGIC;
  SIGNAL s_o_wo_slice0      : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL s_o_wo_slice1      : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_o_wo_bit         : STD_LOGIC;
  SIGNAL s_o_tr_slice0      : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL s_o_tr_slice1      : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_o_tr_bit         : STD_LOGIC;
  SIGNAL s_o_en_bit         : STD_LOGIC;
  SIGNAL s_o_en_slice       : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL s_o_no_rw_rw_bit   : STD_LOGIC;
  SIGNAL s_o_no_rw_rw_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_i_no_rw_ro_bit   : STD_LOGIC;
  SIGNAL s_i_no_rw_ro_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_no_rw_wo_bit   : STD_LOGIC;
  SIGNAL s_o_no_rw_wo_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_no_rw_tr_bit   : STD_LOGIC;
  SIGNAL s_o_no_rw_tr_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_notify_rw_trd  : STD_LOGIC;
  SIGNAL s_o_notify_rw_twr  : STD_LOGIC;
  SIGNAL s_o_no_ro_rw_bit   : STD_LOGIC;
  SIGNAL s_o_no_ro_rw_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_i_no_ro_ro_bit   : STD_LOGIC;
  SIGNAL s_i_no_ro_ro_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_no_ro_wo_bit   : STD_LOGIC;
  SIGNAL s_o_no_ro_wo_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_no_ro_tr_bit   : STD_LOGIC;
  SIGNAL s_o_no_ro_tr_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_notify_ro_trd  : STD_LOGIC;
  SIGNAL s_o_no_wo_rw_bit   : STD_LOGIC;
  SIGNAL s_o_no_wo_rw_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_i_no_wo_ro_bit   : STD_LOGIC;
  SIGNAL s_i_no_wo_ro_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_no_wo_wo_bit   : STD_LOGIC;
  SIGNAL s_o_no_wo_wo_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_no_wo_tr_bit   : STD_LOGIC;
  SIGNAL s_o_no_wo_tr_slice : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL s_o_notify_wo_twr  : STD_LOGIC;


  -----------------------------------------------------------------------------
  -- TB Signals
  -----------------------------------------------------------------------------
  SIGNAL s_golden           : STD_LOGIC_VECTOR(g_data_bits-1 DOWNTO 0);
  SIGNAL s_sample           : STD_LOGIC_VECTOR(g_data_bits-1 DOWNTO 0);


  -----------------------------------------------------------------------------
  -- FUNCTIONs
  -----------------------------------------------------------------------------

  PROCEDURE wait_for(VARIABLE flag : INOUT sim_lib.sim_pkg.shared_boolean) IS
  BEGIN
    LOOP
      WAIT UNTIL rising_edge(clk);
      IF flag.get THEN
        EXIT;
      END IF;
    END LOOP;
  END PROCEDURE;
  --
  FUNCTION byte_2_word_addr(byte_addr : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE word_addr : STD_LOGIC_VECTOR(g_addr_bits-1 DOWNTO 0);
  BEGIN
    word_addr := byte_addr(byte_addr'HIGH DOWNTO ceil_log2(g_data_bits/8));
    RETURN word_addr;
  END FUNCTION;
  -----------------------------------------------------------------------------


BEGIN

  f_create_clock(clk, g_system_clk);

  -----------------------------------------------------------------------------
  -- MAIN
  -----------------------------------------------------------------------------
  main : PROCESS
    --
    VARIABLE v_app_done_flag : BOOLEAN := FALSE;
    VARIABLE v_spi_done_flag : BOOLEAN := FALSE;
    --
    VARIABLE RndA        : RandomPType;
    VARIABLE v_byte_addr : STD_LOGIC_VECTOR(g_addr_bits-1 DOWNTO 0);
    VARIABLE v_data      : STD_LOGIC_VECTOR(g_data_bits-1 DOWNTO 0);
    VARIABLE v_reset     : STD_LOGIC_VECTOR(g_data_bits-1 DOWNTO 0);
    VARIABLE v_mask      : STD_LOGIC_VECTOR(g_data_bits-1 DOWNTO 0);
    VARIABLE v_be        : STD_LOGIC_VECTOR(g_data_bits/8-1 DOWNTO 0);
    VARIABLE pass        : BOOLEAN;
    VARIABLE v_wb_result : t_wbs_drv_in(data(g_data_bits-1 DOWNTO 0));

    -- generate random vector of length nr_bits
    IMPURE FUNCTION f_gen_rdm_vec(nr_bits : POSITIVE) RETURN STD_LOGIC_VECTOR IS
      VARIABLE v_return : STD_LOGIC_VECTOR(nr_bits-1 DOWNTO 0);
    BEGIN
      v_return := RndA.Randslv(0, NATURAL'HIGH , nr_bits);
      RETURN v_return;
    END FUNCTION;

    -- signals or variables ...
    VARIABLE v_sample : STD_LOGIC_VECTOR(g_data_bits-1 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_golden : STD_LOGIC_VECTOR(g_data_bits-1 DOWNTO 0) := (OTHERS => '0');

  -----------------------------------------------------------------------------
  -- MAIN process body
  -----------------------------------------------------------------------------
  BEGIN -- p_main

    -- Initialize
    test_runner_setup(runner, runner_cfg);
    RndA.InitSeed(RndA'instance_name);
    checker_init(display_format => verbose,
                 file_format    => verbose_csv,
                 file_name      => "vunit_out/log.csv");

    -- VUINIT Main Loop
    WHILE test_suite LOOP

      -- wbs idle state for some time...
      wbs_idle(s_wbs_drv_out);
      -- no rst_n !!!
      WAIT FOR 100 ns;

      IF run("Test") THEN

        -- Generate some random Tests for all registers

        -- Check ReadWrite register
        info("Checking Register: ReadWrite");
        -- check reset value
        -- TODO: adapt for each register!
        v_byte_addr := std_logic_vector(to_unsigned(c_addr_read_write, v_byte_addr'length));
        v_mask      := x"FFFFFF08";
        v_reset     := x"00000000";
        -- DONE
        wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
        s_sample <= v_sample;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_golden <= v_reset;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        check_equal(s_sample, s_golden, "wrong register reset value!");
        -- write LOOP
        FOR i IN 0 TO g_nr_of_writes-1 LOOP
            -- Genereate Random Data
            -- TODO change register
            v_data := f_gen_rdm_vec(s_reg_read_write'LENGTH);
            -- DONE
            s_golden <= v_data AND v_mask;      -- AND mask for slices
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- Write to Wishbone
            report "Write to Wishbone";
            wbs_write_reg(v_byte_addr, v_data, clk, s_wbs_drv_out, s_wbs_drv_in);
            -- use vunit check_equal check_api to
            -- check register value
            report "Read from Wishbone";
            wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
            s_sample <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            check_equal(s_sample, s_golden, "wrong register value read back");
            report "Sampling register output pins";
            -- check pin/vector value, combine slices
            -- TODO: adapt for each register!
            v_sample               := (OTHERS => '0');
            v_sample(31 DOWNTO 16) := s_o_rw_slice0;
            v_sample(15 DOWNTO 8)  := s_o_rw_slice1;
            v_sample(3)            := s_o_rw_bit;
            s_sample               <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- DONE
            check_equal(s_sample, s_golden, "wrong IO pin/vector value");
        END LOOP;   -- g_nr_of_writes


        -- Check ReadOnly register
        info("Checking Register: ReadOnly");
        -- check reset value
        -- this is only possible before first rising_edge of clk!
        -- TODO! adapt for each register!
        v_byte_addr := std_logic_vector(to_unsigned(c_addr_read_only, v_byte_addr'length));
        v_mask      := x"FFFFFF08";
        v_reset     := b"UUUU_UUUU_UUUU_UUUU_UUUU_UUUU_0000_U000";      -- if input pins are not driven, then undefined!
        report "Read from Wishbone";
        wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
        s_sample <= v_sample;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_golden <= v_reset;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        check_equal(s_sample, s_golden, "wrong register reset value!");v_reset     := x"00000000";
        -- after first rising_edge of clk register is set by IO pins
        -- drive pin/vector values, combine slices
        report "Driving IO inputs with reset value";
        s_i_ro_slice0   <= v_reset(31 DOWNTO 16);
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_i_ro_slice1   <= v_reset(15 DOWNTO 8);
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_i_ro_bit      <= v_reset(3);
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        -- DONE!
        report "Read from Wishbone";
        wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
        s_sample <= v_sample;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_golden <= v_reset;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        check_equal(s_sample, s_golden, "wrong register reset value!");
        -- write LOOP
        FOR i IN 0 TO g_nr_of_writes-1 LOOP
            -- Genereate Random Data
            -- TODO change register
            v_data := f_gen_rdm_vec(s_reg_read_only'LENGTH);
            -- DONE
            s_golden <= v_data AND v_mask;      -- AND mask for slices
            WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
            -- drive pin/vector values, combine slices
            -- TODO: adapt for each register!
            report "Driving IO inputs with random value";
            s_i_ro_slice0          <= v_data(31 DOWNTO 16);
            WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
            s_i_ro_slice1          <= v_data(15 DOWNTO 8);
            WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
            s_i_ro_bit             <= v_data(3);
            WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
            -- DONE
            report "Read from Wishbone";
            wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
            s_sample <= v_sample;
            WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
            check_equal(s_sample, s_golden, "wrong register value read");
            -- Write to Wishbone, check if register is really ro!
            report "Write reset value to Wishbone";
            wbs_write_reg(v_byte_addr, v_reset, clk, s_wbs_drv_out, s_wbs_drv_in);
            -- use vunit check_equal check_api to
            -- check register value, should not change for ro!
            report "Read from Wishbone";
            wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
            s_sample <= v_sample;
            WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
            check_equal(s_sample, s_golden, "wrong register value read back");
        END LOOP;   -- g_nr_of_writes


        -- Check WriteOnly register
        -- seems as if the value is only stored for one clk cycle ...
        -- no register ??? only a trigger! Not the expexted behavior...
        -- ERROR reported! Fix will come...
        info("Checking Register: WriteOnly");
        -- check reset value, read should not work, bur pins...
        -- TODO: adapt for each register!
        v_byte_addr := std_logic_vector(to_unsigned(c_addr_write_only, v_byte_addr'length));
        v_mask      := x"FFFFFF08";
        v_reset     := x"00000000";
        -- DONE
        report "Sampling register output pins";
        -- check pin/vector reset value, combine slices
        -- TODO: adapt for each register!
        v_sample               := (OTHERS => '0');
        v_sample(31 DOWNTO 16) := s_o_wo_slice0;
        v_sample(15 DOWNTO 8)  := s_o_wo_slice1;
        v_sample(3)            := s_o_wo_bit;
        s_sample               <= v_sample;
        WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
        -- DONE
        s_golden <= v_reset;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        check_equal(s_sample, s_golden, "wrong IO pin/vector reset value");
        -- check to read WriteOnly register, should fail!
        --report "Read from Wishbone, expecting to fail...";
        --wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
        --s_sample <= v_sample;
        --WAIT FOR 0 ns;                            --  wait one Delta cycle to update signal
        --IF (check_equal(s_sample, s_golden, "Expected: register read reset value not working!", level => info)) THEN
        --  info("Read Reset value matches... This was not expected!");
        --ELSE
        --  info("Expected to be here.");
        --END IF;
        -- write LOOP
        FOR i IN 0 TO g_nr_of_writes-1 LOOP
            -- Genereate Random Data
            -- TODO change register
            v_data := f_gen_rdm_vec(s_reg_write_only'LENGTH);
            -- DONE
            s_golden <= v_data AND v_mask;      -- AND mask for slices
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- Write to Wishbone
            report "Write to Wishbone";
            wbs_write_reg(v_byte_addr, v_data, clk, s_wbs_drv_out, s_wbs_drv_in);
            -- use vunit check_equal check_api to
            -- check register value
            -- check pin/vector value, combine slices
            -- TODO: adapt for each register!
            WAIT FOR 1 ns;                      --  wait for 1 ns (one Delta cycle) for update of output signals
            report "Sampling register output pins";
            v_sample               := (OTHERS => '0');
            v_sample(31 DOWNTO 16) := s_o_wo_slice0;
            v_sample(15 DOWNTO 8)  := s_o_wo_slice1;
            v_sample(3)            := s_o_wo_bit;
            s_sample               <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- DONE
            check_equal(s_sample, s_golden, "wrong IO pin/vector value");
            report "Read from Wishbone, expecting to fail...";
            -- check to read WriteOnly register, should fail!
            wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
            s_sample <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            check_false( (s_sample=s_golden), "Not expected: register read value matching!");
            report "Sampling register output pins again";
            v_sample               := (OTHERS => '0');
            v_sample(31 DOWNTO 16) := s_o_wo_slice0;
            v_sample(15 DOWNTO 8)  := s_o_wo_slice1;
            v_sample(3)            := s_o_wo_bit;
            s_sample               <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- DONE
            check_equal(s_sample, s_golden, "wrong IO pin/vector value");
        END LOOP;   -- g_nr_of_writes


        -- Check Trigger register
        -- seems as if the value is only stored for one clk cycle ...
        -- no register ??? only a trigger! Not the expexted behavior...
        info("Checking Register: Trigger");
        -- check reset value, read should not work, bur pins...
        -- TODO: adapt for each register!
        v_byte_addr := std_logic_vector(to_unsigned(c_addr_trigger, v_byte_addr'length));
        v_mask      := x"FFFFFF08";
        v_reset     := x"00000000";
        -- DONE
        report "Sampling register output pins";
        -- check pin/vector reset value, combine slices
        -- TODO: adapt for each register!
        v_sample               := (OTHERS => '0');
        v_sample(31 DOWNTO 16) := s_o_tr_slice0;
        v_sample(15 DOWNTO 8)  := s_o_tr_slice1;
        v_sample(3)            := s_o_tr_bit;
        s_sample               <= v_sample;
        WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
        -- DONE
        s_golden <= v_reset;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        check_equal(s_sample, s_golden, "wrong IO pin/vector reset value");
        -- check to read WriteOnly register, should fail!
        --report "Read from Wishbone, expecting to fail...";
        --wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
        --s_sample <= v_sample;
        --WAIT FOR 0 ns;                            --  wait one Delta cycle to update signal
        --IF (check_equal(s_sample, s_golden, "Expected: register read reset value not working!", level => info)) THEN
        --  info("Read Reset value matches... This was not expected!");
        --ELSE
        --  info("Expected to be here.");
        --END IF;
        -- write LOOP
        FOR i IN 0 TO g_nr_of_writes-1 LOOP
            -- Genereate Random Data
            -- TODO change register
            v_data := f_gen_rdm_vec(s_reg_trigger'LENGTH);
            -- DONEv_data := f_gen_rdm_vec(s_reg_trigger'LENGTH);
            s_golden <= v_data AND v_mask;      -- AND mask for slices
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- Write to Wishbone
            report "Write to Wishbone";
            wbs_write_reg(v_byte_addr, v_data, clk, s_wbs_drv_out, s_wbs_drv_in);
            -- use vunit check_equal check_api to
            -- check register value
            -- check pin/vector value, combine slices
            -- TODO: adapt for each register!
            WAIT FOR 1 ns;                      --  wait for 1 ns (one Delta cycle) for update of output signals
            report "Sampling register output pins";
            v_sample               := (OTHERS => '0');
            v_sample(31 DOWNTO 16) := s_o_tr_slice0;
            v_sample(15 DOWNTO 8)  := s_o_tr_slice1;
            v_sample(3)            := s_o_tr_bit;
            s_sample               <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- DONE
            check_equal(s_sample, s_golden, "wrong IO pin/vector value");
            report "Read from Wishbone, expecting to fail...";
            -- check to read WriteOnly register, should fail!
            wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
            s_sample <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            check_false( (s_sample=s_golden), "Not expected: register read value matching!");
            report "Sampling register output pins again with reset value";
            s_golden <= v_reset;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            v_sample               := (OTHERS => '0');
            v_sample(31 DOWNTO 16) := s_o_tr_slice0;
            v_sample(15 DOWNTO 8)  := s_o_tr_slice1;
            v_sample(3)            := s_o_tr_bit;
            s_sample               <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- DONE
            check_equal(s_sample, s_golden, "wrong IO pin/vector value");
        END LOOP;   -- g_nr_of_writes

        -- Check Enum register
        info("Checking Register: Enum");
        -- check reset value
        -- TODO: adapt for each register!
        v_byte_addr := std_logic_vector(to_unsigned(c_addr_enum, v_byte_addr'length));
        v_mask      := x"80003000";
        v_reset     := x"80002000";
        -- DONE
        wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
        s_sample <= v_sample;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_golden <= v_reset;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        check_equal(s_sample, s_golden, "wrong register reset value!");
        -- write LOOP
        FOR i IN 0 TO g_nr_of_writes-1 LOOP
            -- Genereate Random Data
            -- TODO change register
            v_data := f_gen_rdm_vec(s_reg_enum'LENGTH);
            -- DONE
            s_golden <= v_data AND v_mask;      -- AND mask for slices
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- Write to Wishbone
            report "Write to Wishbone";
            wbs_write_reg(v_byte_addr, v_data, clk, s_wbs_drv_out, s_wbs_drv_in);
            -- use vunit check_equal check_api to
            -- check register value
            report "Read from Wishbone";
            wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
            s_sample <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            check_equal(s_sample, s_golden, "wrong register value read back");
            report "Sampling register output pins";
            -- check pin/vector value, combine slices
            -- TODO: adapt for each register!
            v_sample               := (OTHERS => '0');
            v_sample(13 DOWNTO 12) := s_o_en_slice;
            v_sample(31)           := s_o_en_bit;
            s_sample               <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- DONE
            check_equal(s_sample, s_golden, "wrong IO pin/vector value");
        END LOOP;   -- g_nr_of_writes

        -- Notify Registers
        -- same as above, with addional notify signals.

        -- Check NotifyRw register
        -- the following signals are generated:
        --   s_o_no_rw_rw_bit       rw      checked
        --   s_o_no_rw_rw_slice     rw      checked
        --   s_i_no_rw_ro_bit       ro      checked
        --   s_i_no_rw_ro_slice     ro      checked
        --   s_o_no_rw_wo_bit       trg     write only trigger
        --   s_o_no_rw_wo_slice     trg     write only trigger
        --   s_o_no_rw_tr_bit       trg     ???
        --   s_o_no_rw_tr_slice     trg     ???
        -- additinal
        -- s_o_notify_rw_trd        trg     read  trigger
        -- s_o_notify_rw_twr        trg     write trigger
        -- TODO: check notify triggers !
        info("Checking Register: NotifyRw");
        -- check reset value
        -- TODO: adapt for each register!
        v_byte_addr := std_logic_vector(to_unsigned(c_addr_notify_rw, v_byte_addr'length));
        v_mask      := x"FFFF0000";
        v_reset     := x"6FUU6F6F";     -- ro bits 23 downto 16 are U (undefined), if not driven !!!
        -- bits 15 downto 0 are wo/trg !!! No read possible!
        -- DONE
        report "Read Reset Value from Wishbone (with undefined RO pins)";
        wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
        --> as far as I can see the read wbs_read_reg doen't create a trigger...
        s_sample <= v_sample;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_golden <= v_reset AND v_mask;     -- AND mask for slices;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        check_equal(s_sample, s_golden, "wrong register reset value!");
        report "Driving ReadOnly IO inputs with reset value";
        v_reset     := x"6F6F6F6F";     -- ro bits 23 downto 16 are U (undefined), if not driven !!!
        s_i_no_rw_ro_bit   <= v_reset(23);
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_i_no_rw_ro_slice <= v_reset(22 DOWNTO 16);
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        --> as far as I can see this creates a trigger o_notify_rw_trd
        report "Read Reset Value from Wishbone";
        wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
        s_sample <= v_sample;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        s_golden <= v_reset AND v_mask;     -- AND mask for slices;
        WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
        check_equal(s_sample, s_golden, "wrong register reset value!");

        -- write LOOP
        FOR i IN 0 TO g_nr_of_writes-1 LOOP
            -- Genereate Random Data
            -- TODO change register
            v_data := f_gen_rdm_vec(s_reg_notify_rw'LENGTH);
            -- DONE
            s_golden <= v_data AND v_mask;      -- AND mask for slices
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- Write to Wishbone
            report "Write to Wishbone";
            wbs_write_reg(v_byte_addr, v_data, clk, s_wbs_drv_out, s_wbs_drv_in);
            -- TODO: adapt for each register!
            report "Driving IO inputs with random value";
            WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
            s_i_no_rw_ro_bit   <= v_data(23);
            WAIT FOR 0 ns;                          --  wait one Delta cycle to update signal
            s_i_no_rw_ro_slice <= v_data(22 DOWNTO 16);
            WAIT FOR 0 ns;                              --  wait one Delta cycle to update signal
            -- DONE
            -- use vunit check_equal check_api to
            -- check register value
            report "Read from Wishbone";
            wbs_read_reg(v_byte_addr, v_sample, clk, s_wbs_drv_out, s_wbs_drv_in);
            s_sample <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            check_equal(s_sample, s_golden, "wrong register value read back");
            report "Sampling register output pins";
            -- check pin/vector value, combine slices
            -- TODO: adapt for each register!
            v_sample               := (OTHERS => '0');
            v_sample(31)           := s_o_no_rw_rw_bit;
            v_sample(30 DOWNTO 24) := s_o_no_rw_rw_slice;
            v_sample(23)           := s_i_no_rw_ro_bit;
            v_sample(22 DOWNTO 16) := s_i_no_rw_ro_slice;
            s_sample               <= v_sample;
            WAIT FOR 0 ns;                      --  wait one Delta cycle to update signal
            -- DONE
            check_equal(s_sample, s_golden, "wrong IO pin/vector value");
        END LOOP;   -- g_nr_of_writes

        -- write to invalid address
        WAIT FOR 100 ns;
        report "Write to invalid address -> check error assignment";
        wbs_transmit(c_addr_invalid_slv, c_wb_dat_max, v_sample, c_wb_we_write, c_wb_sel_max, clk, s_wbs_drv_out, s_wbs_drv_in, v_wb_result);
        check_equal(v_wb_result.ack, '0', "erroneous ACK assignment @ write access to invalid address");
        check_equal(v_wb_result.err, '1', "erroneous ERR assignment @ write access to invalid address");
        check_equal(v_wb_result.rty, '0', "erroneous RTY assignment @ write access to invalid address");

        -- read from invalid address
        WAIT FOR 100 ns;
        report "Read from invalid address -> check error assignment";
        wbs_transmit(c_addr_invalid_slv, c_wb_dat_max, v_sample, c_wb_we_read, c_wb_sel_max, clk, s_wbs_drv_out, s_wbs_drv_in, v_wb_result);
        check_equal(v_wb_result.ack, '0', "erroneous ACK assignment @ read access to invalid address");
        check_equal(v_wb_result.err, '1', "erroneous ERR assignment @ read access to invalid address");
        check_equal(v_wb_result.rty, '0', "erroneous RTY assignment @ read access to invalid address");
      END IF;

      REPORT "TB Done";

    END LOOP;
    test_runner_cleanup(runner);
  END PROCESS main;
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- DUT (wbs_test)
  -----------------------------------------------------------------------------
  gen_dut_std : IF (g_use_notify_wbs = FALSE) GENERATE
  BEGIN
   dut : ENTITY tb_lib.wbs_test
      GENERIC MAP (
                   g_addr_bits => g_addr_bits)
      PORT MAP (
                -- SYSCON, no rst, rst_n
                clk               => clk,
                -- Wishbone
                i_wb_cyc          => s_wbs_drv_out.cyc,
                i_wb_stb          => s_wbs_drv_out.stb,
                i_wb_we           => s_wbs_drv_out.we,
                i_wb_sel          => s_wbs_drv_out.sel,
                i_wb_addr         => s_wbs_drv_out.addr,
                i_wb_data         => s_wbs_drv_out.data,
                o_wb_data         => s_wbs_drv_in.data,
                o_wb_ack          => s_wbs_drv_in.ack,
                o_wb_rty          => s_wbs_drv_in.rty,
                o_wb_err          => s_wbs_drv_in.err,
                -- IO Signals
                o_rw_slice0      => s_o_rw_slice0,
                o_rw_slice1      => s_o_rw_slice1,
                o_rw_bit         => s_o_rw_bit,
                i_ro_slice0      => s_i_ro_slice0,
                i_ro_slice1      => s_i_ro_slice1,
                i_ro_bit         => s_i_ro_bit,
                o_wo_slice0      => s_o_wo_slice0,
                o_wo_slice1      => s_o_wo_slice1,
                o_wo_bit         => s_o_wo_bit,
                o_tr_slice0      => s_o_tr_slice0,
                o_tr_slice1      => s_o_tr_slice1,
                o_tr_bit         => s_o_tr_bit,
                o_en_bit         => s_o_en_bit,
                o_en_slice       => s_o_en_slice,
                o_no_rw_rw_bit   => s_o_no_rw_rw_bit,
                o_no_rw_rw_slice => s_o_no_rw_rw_slice,
                i_no_rw_ro_bit   => s_i_no_rw_ro_bit,
                i_no_rw_ro_slice => s_i_no_rw_ro_slice,
                o_no_rw_wo_bit   => s_o_no_rw_wo_bit,
                o_no_rw_wo_slice => s_o_no_rw_wo_slice,
                o_no_rw_tr_bit   => s_o_no_rw_tr_bit,
                o_no_rw_tr_slice => s_o_no_rw_tr_slice,
                o_notify_rw_trd  => s_o_notify_rw_trd,
                o_notify_rw_twr  => s_o_notify_rw_twr,
                o_no_ro_rw_bit   => s_o_no_ro_rw_bit,
                o_no_ro_rw_slice => s_o_no_ro_rw_slice,
                i_no_ro_ro_bit   => s_i_no_ro_ro_bit,
                i_no_ro_ro_slice => s_i_no_ro_ro_slice,
                o_no_ro_wo_bit   => s_o_no_ro_wo_bit,
                o_no_ro_wo_slice => s_o_no_ro_wo_slice,
                o_no_ro_tr_bit   => s_o_no_ro_tr_bit,
                o_no_ro_tr_slice => s_o_no_ro_tr_slice,
                o_notify_ro_trd  => s_o_notify_ro_trd,
                o_no_wo_rw_bit   => s_o_no_wo_rw_bit,
                o_no_wo_rw_slice => s_o_no_wo_rw_slice,
                i_no_wo_ro_bit   => s_i_no_wo_ro_bit,
                i_no_wo_ro_slice => s_i_no_wo_ro_slice,
                o_no_wo_wo_bit   => s_o_no_wo_wo_bit,
                o_no_wo_wo_slice => s_o_no_wo_wo_slice,
                o_no_wo_tr_bit   => s_o_no_wo_tr_bit,
                o_no_wo_tr_slice => s_o_no_wo_tr_slice,
                o_notify_wo_twr  => s_o_notify_wo_twr);
  END GENERATE gen_dut_std;
  -----------------------------------------------------------------------------
  -- DUT (wbs_test_notify)
  -----------------------------------------------------------------------------
  gen_dut_notify : IF (g_use_notify_wbs = TRUE) GENERATE
  BEGIN
    dut : ENTITY tb_lib.wbs_test_notify
      GENERIC MAP (
                   g_addr_bits => g_addr_bits)
      PORT MAP (
                -- SYSCON, no rst, rst_n
                clk               => clk,
                -- Wishbone
                i_wb_cyc          => s_wbs_drv_out.cyc,
                i_wb_stb          => s_wbs_drv_out.stb,
                i_wb_we           => s_wbs_drv_out.we,
                i_wb_sel          => s_wbs_drv_out.sel,
                i_wb_addr         => s_wbs_drv_out.addr,
                i_wb_data         => s_wbs_drv_out.data,
                o_wb_data         => s_wbs_drv_in.data,
                o_wb_ack          => s_wbs_drv_in.ack,
                o_wb_rty          => s_wbs_drv_in.rty,
                o_wb_err          => s_wbs_drv_in.err,
                -- IO Signals
                o_rw_slice0      => s_o_rw_slice0,
                o_rw_slice1      => s_o_rw_slice1,
                o_rw_bit         => s_o_rw_bit,
                i_ro_slice0      => s_i_ro_slice0,
                i_ro_slice1      => s_i_ro_slice1,
                i_ro_bit         => s_i_ro_bit,
                o_wo_slice0      => s_o_wo_slice0,
                o_wo_slice1      => s_o_wo_slice1,
                o_wo_bit         => s_o_wo_bit,
                o_tr_slice0      => s_o_tr_slice0,
                o_tr_slice1      => s_o_tr_slice1,
                o_tr_bit         => s_o_tr_bit,
                o_en_bit         => s_o_en_bit,
                o_en_slice       => s_o_en_slice,
                o_no_rw_rw_bit   => s_o_no_rw_rw_bit,
                o_no_rw_rw_slice => s_o_no_rw_rw_slice,
                i_no_rw_ro_bit   => s_i_no_rw_ro_bit,
                i_no_rw_ro_slice => s_i_no_rw_ro_slice,
                o_no_rw_wo_bit   => s_o_no_rw_wo_bit,
                o_no_rw_wo_slice => s_o_no_rw_wo_slice,
                o_no_rw_tr_bit   => s_o_no_rw_tr_bit,
                o_no_rw_tr_slice => s_o_no_rw_tr_slice,
                o_notify_rw_trd  => s_o_notify_rw_trd,
                o_notify_rw_twr  => s_o_notify_rw_twr,
                o_no_ro_rw_bit   => s_o_no_ro_rw_bit,
                o_no_ro_rw_slice => s_o_no_ro_rw_slice,
                i_no_ro_ro_bit   => s_i_no_ro_ro_bit,
                i_no_ro_ro_slice => s_i_no_ro_ro_slice,
                o_no_ro_wo_bit   => s_o_no_ro_wo_bit,
                o_no_ro_wo_slice => s_o_no_ro_wo_slice,
                o_no_ro_tr_bit   => s_o_no_ro_tr_bit,
                o_no_ro_tr_slice => s_o_no_ro_tr_slice,
                o_notify_ro_trd  => s_o_notify_ro_trd,
                o_no_wo_rw_bit   => s_o_no_wo_rw_bit,
                o_no_wo_rw_slice => s_o_no_wo_rw_slice,
                i_no_wo_ro_bit   => s_i_no_wo_ro_bit,
                i_no_wo_ro_slice => s_i_no_wo_ro_slice,
                o_no_wo_wo_bit   => s_o_no_wo_wo_bit,
                o_no_wo_wo_slice => s_o_no_wo_wo_slice,
                o_no_wo_tr_bit   => s_o_no_wo_tr_bit,
                o_no_wo_tr_slice => s_o_no_wo_tr_slice,
                o_notify_wo_twr  => s_o_notify_wo_twr);
  END GENERATE gen_dut_notify;

END ARCHITECTURE tb;
-------------------------------------------------------------------------------
