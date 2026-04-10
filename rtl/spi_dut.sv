`timescale 1ns/1ps

module spi_dut (
  input  logic sclk,
  input  logic cs_n,
  input  logic mosi,
  output logic miso
);
  // Simple loopback: miso follows mosi on each sampled edge when selected
  always_ff @(posedge sclk) begin
    if (!cs_n) begin
      miso <= mosi;
    end
  end

endmodule
