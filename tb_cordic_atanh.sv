`timescale 1ns/1ps

// Generic testbench for a CORDIC-based atanh IP core.
// - Drives a sequence of 10-bit fixed-point inputs via a ready/valid interface
// - Computes a real-valued reference using atanh(x) = 0.5*ln((1+x)/(1-x)) for visibility
// - Adjust the DUT instance to match your IP's module name and ports

module tb_cordic_atanh;

  // Configuration
  localparam int INPUT_WIDTH     = 10;  // stimulus width
  localparam int FRACTION_BITS   = 8;   // Q2.8 fixed-point for inputs (signed)
  localparam int OUTPUT_WIDTH    = 32;  // assumed output width (adjust to your DUT)

  // Clock/Reset
  logic clk;
  logic rst_n;

  // Stream-like handshake
  logic                         in_valid;
  logic                         in_ready;   // from DUT
  logic signed [INPUT_WIDTH-1:0] in_data;

  logic                         out_valid;  // from DUT
  logic                         out_ready;
  logic signed [OUTPUT_WIDTH-1:0] out_data; // from DUT

  // Clock generation: 100 MHz
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Reset sequence
  initial begin
    rst_n    = 1'b0;
    in_valid = 1'b0;
    in_data  = '0;
    out_ready = 1'b1; // always ready to take output
    repeat (8) @(posedge clk);
    rst_n = 1'b1;
  end

  // Reference conversion from fixed-point to real
  function automatic real fxp_to_real(input logic signed [INPUT_WIDTH-1:0] s);
    fxp_to_real = $itor($signed(s)) / (1 << FRACTION_BITS);
  endfunction

  // Reference atanh for visibility (SystemVerilog real math)
  function automatic real atanh_ref(input real x);
    real num, den;
    // Guard near |x| >= 1 to avoid log singularity
    if (x >= 0.999999 || x <= -0.999999) begin
      atanh_ref = (x > 0) ? 1.0e30 : -1.0e30; // represent saturation
    end else begin
      num = (1.0 + x);
      den = (1.0 - x);
      atanh_ref = 0.5 * $ln(num/den);
    end
  endfunction

  // Apply a single input with handshake
  task automatic apply_input(input logic [INPUT_WIDTH-1:0] v);
    real xr, yr;
    @(posedge clk);
    // Wait until DUT can accept input (if in_ready is used)
    // If your DUT does not provide in_ready, comment out this wait
    wait (in_ready === 1'b1);
    in_data  <= v;
    in_valid <= 1'b1;
    xr = fxp_to_real($signed(v));
    yr = atanh_ref(xr);
    $display("[%0t] IN  val=0b%0b signed=%0d real=%0.6f  ref_atanh=%0.6f",
             $time, v, $signed(v), xr, yr);
    @(posedge clk);
    in_valid <= 1'b0;
  endtask

  // Observe outputs
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      // no-op
    end else if (out_valid) begin
      $display("[%0t] OUT val=0x%0h signed=%0d",
               $time, out_data, $signed(out_data));
    end
  end

  // Stimulus: apply provided vectors
  initial begin
    // Wait for reset deassertion
    @(posedge rst_n);
    repeat (2) @(posedge clk);

    apply_input(10'b1100000000); // -1.00
    apply_input(10'b1100001100); // -0.97
    apply_input(10'b1100010110); // -0.92
    apply_input(10'b1100100110); // -0.85
    apply_input(10'b1100110011); // -0.80
    apply_input(10'b1101001001); // -0.72
    apply_input(10'b1101011010); // -0.66
    apply_input(10'b1110010110); // -0.45
    apply_input(10'b1110101101); // -0.34
    apply_input(10'b1111000100); // -0.26
    apply_input(10'b0000000000); //  0.00
    apply_input(10'b0000001001); //  0.03
    apply_input(10'b0000100110); //  0.15
    apply_input(10'b0001000100); //  0.27
    apply_input(10'b0001010011); //  0.32
    apply_input(10'b0010000000); //  0.50
    apply_input(10'b0010101011); //  0.67
    apply_input(10'b0010111001); //  0.72
    apply_input(10'b0011001110); //  0.78
    apply_input(10'b0011011011); //  0.83
    apply_input(10'b0011110100); //  0.96

    // Allow pipeline to drain
    repeat (50) @(posedge clk);
    $display("[%0t] TEST COMPLETE", $time);
    $finish;
  end

  // =====================
  // DUT INSTANTIATION
  // =====================
  // Replace 'cordic_atanh_ip' and port names to match your IP.
  // If your DUT does not use ready/valid, tie/ignore as needed and
  // update apply_input/wait conditions accordingly.

  cordic_atanh_ip dut (
    .clk       (clk),
    .rst_n     (rst_n),

    .in_valid  (in_valid),
    .in_ready  (in_ready),
    .in_data   (in_data),

    .out_valid (out_valid),
    .out_ready (out_ready),
    .out_data  (out_data)
  );

endmodule

// -----------------------------------------------------------------------------
// If you do not have the DUT available during early testbench development,
// you can uncomment the following simple placeholder model so the bench compiles.
// Remove this once you connect the real IP.
// -----------------------------------------------------------------------------
/*
module cordic_atanh_ip (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic                       in_valid,
  output logic                       in_ready,
  input  logic signed [9:0]          in_data,
  input  logic                       out_ready,
  output logic                       out_valid,
  output logic signed [31:0]         out_data
);
  // Simple elastic register + fake transform for placeholder only
  assign in_ready = 1'b1;
  logic                       v_q;
  logic signed [31:0]         d_q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      v_q    <= 1'b0;
      d_q    <= '0;
    end else begin
      v_q    <= in_valid;
      // Placeholder: pass-through extend (not atanh!)
      d_q    <= {{22{in_data[9]}}, in_data};
    end
  end

  assign out_valid = v_q;
  assign out_data  = d_q;
endmodule
*/

