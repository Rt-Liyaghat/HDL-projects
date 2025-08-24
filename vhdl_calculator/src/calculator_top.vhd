library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calculator_top is
  generic (
    CLK_FREQ_HZ  : natural := 50000000;
    COMMON_ANODE : boolean := true
  );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    sw_a         : in  std_logic_vector(7 downto 0);
    sw_b         : in  std_logic_vector(7 downto 0);
    op_sel       : in  std_logic_vector(1 downto 0); -- 00:add 01:sub 10:mul 11:div
    an           : out std_logic_vector(3 downto 0);
    seg          : out std_logic_vector(6 downto 0);
    dp           : out std_logic;
    leds         : out std_logic_vector(7 downto 0)
  );
end entity calculator_top;

architecture rtl of calculator_top is
  component alu8 is
    port (
      a               : in  std_logic_vector(7 downto 0);
      b               : in  std_logic_vector(7 downto 0);
      op              : in  std_logic_vector(1 downto 0);
      result          : out std_logic_vector(15 downto 0);
      carry           : out std_logic;
      overflow        : out std_logic;
      zero            : out std_logic;
      div_by_zero     : out std_logic
    );
  end component;

  component seven_seg_driver is
    generic (
      CLK_FREQ_HZ   : natural := 50000000;
      REFRESH_HZ    : natural := 1000;
      COMMON_ANODE  : boolean := true
    );
    port (
      clk           : in  std_logic;
      reset_n       : in  std_logic;
      value         : in  std_logic_vector(15 downto 0);
      an            : out std_logic_vector(3 downto 0);
      seg           : out std_logic_vector(6 downto 0);
      dp            : out std_logic
    );
  end component;

  signal alu_result      : std_logic_vector(15 downto 0);
  signal flag_carry      : std_logic;
  signal flag_overflow   : std_logic;
  signal flag_zero       : std_logic;
  signal flag_divzero    : std_logic;
begin
  u_alu: alu8
    port map (
      a           => sw_a,
      b           => sw_b,
      op          => op_sel,
      result      => alu_result,
      carry       => flag_carry,
      overflow    => flag_overflow,
      zero        => flag_zero,
      div_by_zero => flag_divzero
    );

  u_disp: seven_seg_driver
    generic map (
      CLK_FREQ_HZ  => CLK_FREQ_HZ,
      REFRESH_HZ   => 1000,
      COMMON_ANODE => COMMON_ANODE
    )
    port map (
      clk     => clk,
      reset_n => reset_n,
      value   => alu_result,
      an      => an,
      seg     => seg,
      dp      => dp
    );

  -- LEDs: [0]=carry [1]=overflow [2]=zero [3]=div0 [7:4]=op_sel & zeros
  leds(0) <= flag_carry;
  leds(1) <= flag_overflow;
  leds(2) <= flag_zero;
  leds(3) <= flag_divzero;
  leds(5 downto 4) <= op_sel;
  leds(7 downto 6) <= (others => '0');
end architecture rtl;