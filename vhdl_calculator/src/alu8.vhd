library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu8 is
  port (
    a               : in  std_logic_vector(7 downto 0);
    b               : in  std_logic_vector(7 downto 0);
    op              : in  std_logic_vector(1 downto 0); -- 00: add, 01: sub, 10: mul, 11: div
    result          : out std_logic_vector(15 downto 0);
    carry           : out std_logic;
    overflow        : out std_logic;
    zero            : out std_logic;
    div_by_zero     : out std_logic
  );
end entity alu8;

architecture rtl of alu8 is
begin
  process(a, b, op)
    variable result_v       : std_logic_vector(15 downto 0);
    variable carry_v        : std_logic;
    variable overflow_v     : std_logic;
    variable zero_v         : std_logic;
    variable div_by_zero_v  : std_logic;

    variable add_tmp        : unsigned(8 downto 0);
    variable sub_tmp        : signed(8 downto 0);
    variable mul_tmp        : unsigned(15 downto 0);
    variable quo_tmp        : unsigned(7 downto 0);
    variable rem_tmp        : unsigned(7 downto 0);

    variable a_unsigned     : unsigned(7 downto 0);
    variable b_unsigned     : unsigned(7 downto 0);
    variable a_signed       : signed(7 downto 0);
    variable b_signed       : signed(7 downto 0);
  begin
    a_unsigned := unsigned(a);
    b_unsigned := unsigned(b);
    a_signed   := signed(a);
    b_signed   := signed(b);

    -- Defaults
    result_v       := (others => '0');
    carry_v        := '0';
    overflow_v     := '0';
    div_by_zero_v  := '0';

    case op is
      when "00" =>  -- ADD (unsigned carry, signed overflow)
        add_tmp        := unsigned('0' & a) + unsigned('0' & b);
        result_v(7 downto 0) := std_logic_vector(add_tmp(7 downto 0));
        result_v(15 downto 8) := (others => '0');
        carry_v        := add_tmp(8);
        -- Signed overflow detection for addition
        -- overflow if sign(a) = sign(b) and sign(result) /= sign(a)
        overflow_v     := ((a(7) xor result_v(7)) and (not (a(7) xor b(7))));

      when "01" =>  -- SUB (a - b)
        sub_tmp        := signed('0' & a) - signed('0' & b);
        result_v(7 downto 0) := std_logic_vector(sub_tmp(7 downto 0));
        result_v(15 downto 8) := (others => '0');
        -- carry flag here indicates "no borrow" for subtraction
        if a_unsigned >= b_unsigned then
          carry_v := '1';
        else
          carry_v := '0';
        end if;
        -- Signed overflow detection for subtraction
        -- overflow if sign(a) /= sign(b) and sign(result) /= sign(a)
        overflow_v     := ((a(7) xor b(7)) and (a(7) xor result_v(7)));

      when "10" =>  -- MUL (unsigned)
        mul_tmp        := unsigned(a) * unsigned(b);
        result_v       := std_logic_vector(mul_tmp);
        -- Overflow if upper 8 bits are non-zero
        if mul_tmp(15 downto 8) /= (others => '0') then
          overflow_v := '1';
        else
          overflow_v := '0';
        end if;
        carry_v        := '0';

      when others =>  -- "11" DIV (unsigned) -> result = {remainder, quotient}
        if b = x"00" then
          result_v      := (others => '0');
          div_by_zero_v := '1';
        else
          quo_tmp       := unsigned(a) / unsigned(b);
          rem_tmp       := unsigned(a) mod unsigned(b);
          result_v      := std_logic_vector(rem_tmp & quo_tmp);
          div_by_zero_v := '0';
        end if;
        carry_v        := '0';
        overflow_v     := '0';
    end case;

    if result_v = (others => '0') then
      zero_v := '1';
    else
      zero_v := '0';
    end if;

    result      <= result_v;
    carry       <= carry_v;
    overflow    <= overflow_v;
    zero        <= zero_v;
    div_by_zero <= div_by_zero_v;
  end process;
end architecture rtl;