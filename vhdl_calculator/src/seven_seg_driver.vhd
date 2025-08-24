library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_seg_driver is
  generic (
    CLK_FREQ_HZ   : natural := 50000000; -- input clock frequency
    REFRESH_HZ    : natural := 1000;     -- per-digit refresh frequency
    COMMON_ANODE  : boolean := true      -- true: outputs are active-low
  );
  port (
    clk           : in  std_logic;
    reset_n       : in  std_logic;
    value         : in  std_logic_vector(15 downto 0); -- 4 hex digits, [15:12] is leftmost
    an            : out std_logic_vector(3 downto 0);  -- digit enables (AN3..AN0)
    seg           : out std_logic_vector(6 downto 0);  -- segments (a,b,c,d,e,f,g)
    dp            : out std_logic                       -- decimal point (off by default)
  );
end entity seven_seg_driver;

architecture rtl of seven_seg_driver is
  function hex_to_segs(nibble : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable s : std_logic_vector(6 downto 0);
  begin
    --  abcdefg (active high encoding)
    case nibble is
      when "0000" => s := "1111110"; -- 0
      when "0001" => s := "0110000"; -- 1
      when "0010" => s := "1101101"; -- 2
      when "0011" => s := "1111001"; -- 3
      when "0100" => s := "0110011"; -- 4
      when "0101" => s := "1011011"; -- 5
      when "0110" => s := "1011111"; -- 6
      when "0111" => s := "1110000"; -- 7
      when "1000" => s := "1111111"; -- 8
      when "1001" => s := "1111011"; -- 9
      when "1010" => s := "1110111"; -- A
      when "1011" => s := "0011111"; -- b
      when "1100" => s := "1001110"; -- C
      when "1101" => s := "0111101"; -- d
      when "1110" => s := "1001111"; -- E
      when others => s := "1000111";  -- F
    end case;
    return s;
  end function;

  constant TICKS_PER_DIGIT : natural := integer(CLK_FREQ_HZ / (REFRESH_HZ * 4));

  signal tick_counter   : natural range 0 to TICKS_PER_DIGIT - 1 := 0;
  signal active_digit   : unsigned(1 downto 0) := (others => '0');
  signal seg_raw        : std_logic_vector(6 downto 0);
  signal an_raw         : std_logic_vector(3 downto 0);
  signal nibble         : std_logic_vector(3 downto 0);
begin
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      tick_counter <= 0;
      active_digit <= (others => '0');
    elsif rising_edge(clk) then
      if tick_counter = TICKS_PER_DIGIT - 1 then
        tick_counter <= 0;
        active_digit <= active_digit + 1;
      else
        tick_counter <= tick_counter + 1;
      end if;
    end if;
  end process;

  -- Select nibble for current digit (3 is leftmost)
  with active_digit select nibble <=
    value(3 downto 0)   when "00", -- rightmost
    value(7 downto 4)   when "01",
    value(11 downto 8)  when "10",
    value(15 downto 12) when others; -- leftmost

  seg_raw <= hex_to_segs(nibble);

  -- One-hot digit enable for active digit
  with active_digit select an_raw <=
    "0001" when "00",
    "0010" when "01",
    "0100" when "10",
    "1000" when others;

  -- Adjust polarity for common anode vs cathode
  seg <= (not seg_raw) when COMMON_ANODE else seg_raw;
  an  <= (not an_raw)  when COMMON_ANODE else an_raw;
  dp  <= '1' when COMMON_ANODE else '0'; -- keep decimal point off
end architecture rtl;