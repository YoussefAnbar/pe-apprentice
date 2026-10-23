`ifndef PE_V
`define PE_V

`timescale 1ns/1ps

module pe #(
  parameter QI = 8,
  parameter QF = 8,
  localparam DW = QI + QF
)(
  input  logic                 clk,
  input  logic                 rst,

  input  logic signed [DW-1:0] pe_psum_in,
  input  logic signed [DW-1:0] pe_weight_in,
  input  logic                 pe_accept_w_in,

  input  logic signed [DW-1:0] pe_input_in,
  input  logic                 pe_valid_in,
  input  logic                 pe_switch_in,
  input  logic                 pe_enabled,

  output logic signed [DW-1:0] pe_psum_out,
  output logic signed [DW-1:0] pe_weight_out,
  output logic signed [DW-1:0] pe_input_out,
  output logic                 pe_valid_out,
  output logic                 pe_switch_out
);

  logic signed [DW-1:0] weight_bg;
  logic signed [DW-1:0] weight_active;
  logic signed [DW-1:0] mult_out;
  logic signed [DW-1:0] mac_out;

  fxp_mul #(QI, QF) u_mul (pe_input_in, weight_active, mult_out, );
  fxp_add #(QI, QF) u_add (mult_out, pe_psum_in, mac_out, );

  // Select the weight used by the multiplier.
  always_comb begin
    if (pe_switch_in)
      weight_active = weight_bg;
    else
      weight_active = pe_weight_out;
  end

  // Load the background weight.
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      weight_bg <= '0;
    else if (pe_enabled && pe_accept_w_in)
      weight_bg <= pe_weight_in;
  end

  // Register the selected weight, data, and controls.
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      pe_psum_out   <= '0;
      pe_weight_out <= '0;
      pe_input_out  <= '0;
      pe_valid_out  <= 1'b0;
      pe_switch_out <= 1'b0;
    end
    else if (!pe_enabled) begin
      // Hold all output registers.
    end
    else begin
      pe_weight_out <= weight_active;
      pe_valid_out  <= pe_valid_in;
      pe_switch_out <= pe_switch_in;

      if (pe_valid_in) begin
        pe_input_out <= pe_input_in;
        pe_psum_out  <= mac_out;
      end
      else begin
        pe_input_out <= '0;
        pe_psum_out  <= '0;
      end
    end
  end

endmodule

`endif
