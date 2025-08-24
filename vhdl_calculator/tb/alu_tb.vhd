library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb is
end entity;

architecture tb of alu_tb is
  signal a, b        : std_logic_vector(7 downto 0);
  signal op          : std_logic_vector(1 downto 0);
  signal result      : std_logic_vector(15 downto 0);
  signal carry       : std_logic;
  signal overflow    : std_logic;
  signal zero        : std_logic;
  signal div_by_zero : std_logic;

  procedure check(
    constant msg        : in string;
    constant exp_res    : in std_logic_vector;
    constant exp_c      : in std_logic;
    constant exp_o      : in std_logic;
    constant exp_z      : in std_logic;
    constant exp_dz     : in std_logic
  ) is
  begin
    assert result = exp_res report msg & ": result mismatch" severity error;
    assert carry = exp_c report msg & ": carry mismatch" severity error;
    assert overflow = exp_o report msg & ": overflow mismatch" severity error;
    assert zero = exp_z report msg & ": zero mismatch" severity error;
    assert div_by_zero = exp_dz report msg & ": div_by_zero mismatch" severity error;
  end procedure;

begin
  dut: entity work.alu8
    port map (
      a => a,
      b => b,
      op => op,
      result => result,
      carry => carry,
      overflow => overflow,
      zero => zero,
      div_by_zero => div_by_zero
    );

  stim: process
    variable res16 : std_logic_vector(15 downto 0);
  begin
    -- ADD: 5 + 10 = 15
    a <= x"05"; b <= x"0A"; op <= "00"; wait for 1 ns;
    res16 := (others => '0'); res16(7 downto 0) := x"0F";
    check("add 5+10", res16, '0', '0', '0', '0');

    -- ADD with carry: 200 + 100 = 300 (0x12C), low=0x2C, carry set
    a <= std_logic_vector(to_unsigned(200, 8));
    b <= std_logic_vector(to_unsigned(100, 8));
    op <= "00"; wait for 1 ns;
    res16 := (others => '0'); res16(7 downto 0) := std_logic_vector(to_unsigned(44,8));
    check("add carry", res16, '1', '0', '0', '0');

    -- ADD with signed overflow: 120 + 120 = -16 (overflow)
    a <= std_logic_vector(to_signed(120, 8));
    b <= std_logic_vector(to_signed(120, 8));
    op <= "00"; wait for 1 ns;
    res16 := (others => '0'); res16(7 downto 0) := std_logic_vector(to_signed(-16, 8));
    check("add overflow", res16, '0', '1', '0', '0');

    -- SUB: 50 - 20 = 30, carry(no borrow) = 1
    a <= std_logic_vector(to_unsigned(50, 8));
    b <= std_logic_vector(to_unsigned(20, 8));
    op <= "01"; wait for 1 ns;
    res16 := (others => '0'); res16(7 downto 0) := std_logic_vector(to_unsigned(30,8));
    check("sub no borrow", res16, '1', '0', '0', '0');

    -- SUB with borrow: 20 - 50 = -30, carry(no borrow)=0
    a <= std_logic_vector(to_unsigned(20, 8));
    b <= std_logic_vector(to_unsigned(50, 8));
    op <= "01"; wait for 1 ns;
    res16 := (others => '0'); res16(7 downto 0) := std_logic_vector(to_signed(-30,8));
    check("sub borrow", res16, '0', '0', '0', '0');

    -- MUL: 20 * 15 = 300 (0x012C)
    a <= std_logic_vector(to_unsigned(20, 8));
    b <= std_logic_vector(to_unsigned(15, 8));
    op <= "10"; wait for 1 ns;
    res16 := x"012C";
    check("mul", res16, '0', '0', '0', '0');

    -- MUL with overflow: 255 * 255 = 0xFE01, overflow high != 0
    a <= x"FF"; b <= x"FF"; op <= "10"; wait for 1 ns;
    res16 := x"FE01";
    check("mul overflow", res16, '0', '1', '0', '0');

    -- DIV: 200 / 15 => quotient=13 (0x0D), remainder=5 (0x05); result={rem,quo}=0x050D
    a <= std_logic_vector(to_unsigned(200, 8));
    b <= std_logic_vector(to_unsigned(15, 8));
    op <= "11"; wait for 1 ns;
    res16 := x"050D";
    check("div", res16, '0', '0', '0', '0');

    -- DIV by zero
    a <= x"12"; b <= x"00"; op <= "11"; wait for 1 ns;
    res16 := (others => '0');
    check("div by zero", res16, '0', '0', '1', '1');

    -- Zero flag test: result zero (e.g., 0-0)
    a <= x"00"; b <= x"00"; op <= "01"; wait for 1 ns;
    res16 := (others => '0');
    check("zero flag", res16, '1', '0', '1', '0');

    report "ALU TB completed" severity note;
    wait;
  end process;
end architecture tb;