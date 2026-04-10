`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import spi_uart_pkg::*;

  bit tb_clk;

  // Interfaces
  spi_if  spi_vif(.tb_clk(tb_clk));
  uart_if uart_vif(.tb_clk(tb_clk));

  // DUTs
  spi_dut u_spi (
    .sclk(spi_vif.sclk),
    .cs_n(spi_vif.cs_n),
    .mosi(spi_vif.mosi),
    .miso(spi_vif.miso)
  );

  uart_dut u_uart (
    .baud_tick(uart_vif.baud_tick),
    .rst_n(uart_vif.rst_n),
    .rx(uart_vif.rx),
    .tx(uart_vif.tx)
  );

  // Clock generation
  initial tb_clk = 1'b0;
  always #1 tb_clk = ~tb_clk;

  // Baud tick generation
  initial begin
    uart_vif.baud_tick = 1'b0;
    forever #5 uart_vif.baud_tick = ~uart_vif.baud_tick;
  end

  // Reset
  initial begin
    uart_vif.rst_n = 1'b0;
    repeat (4) @(posedge uart_vif.baud_tick);
    uart_vif.rst_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual spi_if)::set(null, "*", "vif", spi_vif);
    uvm_config_db#(virtual uart_if)::set(null, "*", "vif", uart_vif);
    run_test("spi_uart_test");
  end
endmodule
