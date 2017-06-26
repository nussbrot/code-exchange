library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity log is
    port(
        inp : in unsigned;
        outp : out unsigned
    );
end;

architecture rtl of log is
    constant c_val_bits : integer := 5;

    type t_lut is array(natural range <>) of unsigned(c_val_bits-1 downto 0);

    function map_log2(addr_bits, value_bits : integer) return t_lut is
        variable step : real := 1.0/real(2**addr_bits);
        variable tmp : real;
        variable result : t_lut(0 to 2**addr_bits-1);
    begin
        for idx in result'range loop
            tmp := 1.0 + real(idx)*step;
            result(idx) := to_unsigned(integer(tmp), value_bits);
        end loop;
        return result;
    end function;
        
    constant lut : t_lut := map_log2(5, c_val_bits);

    function find_msb(inp : unsigned) return integer is
        variable result : integer := 0;
    begin
        for idx in inp'left downto inp'right loop
            if inp(idx) = '1' then
                result := idx;
                exit;
            end if;
        end loop;
        return result;
    end;

begin

    p_comb : process(inp)
        variable msb : integer;
        variable lsb : integer;
        variable idx : unsigned(c_val_bits-1 downto 0);
    begin
        if inp = 0 then
            outp <= (others => '0');
        else
            msb := find_msb(inp);
            lsb := msb - c_val_bits;
            if lsb >= 0 then
                idx := inp(msb-1 downto lsb);
            else
                idx := shift_left(inp, abs(lsb))(c_val_bits-1 downto 0);
            end if;
            outp <= to_unsigned(2**c_val_bits * msb) +
                    lut(to_integer(idx));
        end if;
    end process;

end;