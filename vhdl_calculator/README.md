# VHDL Calculator (ISE 14.7)

This project implements a simple 8-bit calculator on FPGA using VHDL (compatible with ISE 14.7). It supports add, subtract, multiply, and divide. The 16-bit result is shown on a 4-digit seven-segment display; flags are shown on LEDs.

## Modules

- `src/alu8.vhd`: 8-bit ALU with 4 ops (00=ADD, 01=SUB, 10=MUL, 11=DIV). Outputs 16-bit `result` and flags: `carry`, `overflow`, `zero`, `div_by_zero`.
- `src/seven_seg_driver.vhd`: 4-digit seven-segment multiplex driver for hex output. Supports both common-anode and common-cathode via generic.
- `src/calculator_top.vhd`: Top-level wiring switches to ALU and seven-seg.
- `tb/alu_tb.vhd`: Simple behavioral testbench for the ALU.
- `constraints/example.ucf`: Example pin constraints; update for your board.

## Display encoding

- A 16-bit value is displayed as 4 hex digits `[15:12][11:8][7:4][3:0]` left to right.
- For DIV, the output is `{remainder, quotient}`.
- For ADD/SUB, only the low 8-bit result is displayed; carry/borrow and overflow appear in flags.

## LED flags

- `LED0` = carry (for SUB: 1 means no-borrow)
- `LED1` = overflow
- `LED2` = zero (entire 16-bit result is zero)
- `LED3` = divide-by-zero

## ISE 14.7 (Spartan series)

1. Create a New Project (VHDL, preferred language VHDL-93).
2. Add Source files:
   - `src/alu8.vhd`
   - `src/seven_seg_driver.vhd`
   - `src/calculator_top.vhd` (set this as the Top Module)
3. Add Simulation Sources:
   - `tb/alu_tb.vhd`
4. Add Constraints:
   - `constraints/example.ucf` (copy, rename, and edit to match your board)
5. Set Generics in `calculator_top` if needed:
   - `CLK_FREQ_HZ` (e.g., 50_000_000)
   - `COMMON_ANODE` true for active-low segments (many Digilent boards)
6. Synthesis and Implementation:
   - Synthesize, Implement Design, Generate Programming File.
7. Program the FPGA via iMPACT / Hardware Manager.

## Example top-level ports to board signals

- `clk`: board 50 MHz clock
- `reset_n`: active-low pushbutton
- `sw_a[7:0]`: 8 input switches (operand A)
- `sw_b[7:0]`: 8 input switches (operand B)
- `op_sel[1:0]`: 2 input switches to select operation
- `an[3:0]`: 7-seg digit enables
- `seg[6:0]`: 7-seg segments (a..g)
- `dp`: decimal point (kept off)
- `leds[7:0]`: LEDs

## Simulation (optional with GHDL)

If you have `ghdl` locally:

```bash
cd vhdl_calculator
ghdl -a src/alu8.vhd
ghdl -a tb/alu_tb.vhd
ghdl -e alu_tb
ghdl -r alu_tb --stop-time=1us --vcd=alu_tb.vcd
```

Open the VCD with GTKWave to inspect waveforms.

## Notes

- Multiply is unsigned. Overflow is set if the upper 8 bits of the product are non-zero.
- For DIV, `result = remainder & quotient` (remainder in bits [15:8], quotient in bits [7:0]). Divide-by-zero generates zero and sets the flag.
- Seven-seg mapping assumes `seg(6 downto 0) = a..g`.