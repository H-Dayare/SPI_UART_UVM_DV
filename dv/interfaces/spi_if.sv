`timescale 1ns/1ps

interface spi_if (input logic tb_clk);
  logic sclk;
  logic cs_n;
  logic mosi;
  logic miso;

  byte last_tx;
  byte last_rx;
  event byte_xfer_ev;

  // Drive one byte and capture loopback
  task automatic xfer(input byte tx, output byte rx);
    integer i;
    cs_n = 1'b0;
    rx = 8'h00;
    for (i = 7; i >= 0; i = i - 1) begin
      mosi = tx[i];
      #1 sclk = 1'b1;
      #1 rx[i] = miso;
      #1 sclk = 1'b0;
    end
    cs_n = 1'b1;
    last_tx = tx;
    last_rx = rx;
    -> byte_xfer_ev;
  endtask

  // Assertions
  property p_sclk_only_when_cs_low;
    @(posedge sclk) !cs_n;
  endproperty
  a_sclk_only_when_cs_low: assert property(p_sclk_only_when_cs_low)
    else $error("SPI sclk toggled while cs_n high");

  initial begin
    sclk = 1'b0;
    cs_n = 1'b1;
    mosi = 1'b0;
  end
endinterface
