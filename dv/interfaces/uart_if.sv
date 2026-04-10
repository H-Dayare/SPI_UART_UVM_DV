`timescale 1ns/1ps

interface uart_if (input logic tb_clk);
  logic baud_tick;
  logic rst_n;
  logic rx;
  logic tx;

  byte last_rx_data;
  event rx_byte_ev;

  task automatic send_byte(input byte data);
    integer i;
    // start bit
    rx = 1'b0;
    @(posedge baud_tick);
    // data bits LSB first
    for (i = 0; i < 8; i = i + 1) begin
      rx = data[i];
      @(posedge baud_tick);
    end
    // stop bit
    rx = 1'b1;
    @(posedge baud_tick);
    last_rx_data = data;
    -> rx_byte_ev;
  endtask

  // Assertion: after a start bit, stop bit should be high
  property p_stop_bit_high;
    @(posedge baud_tick) (rx == 1'b0) |-> ##9 (rx == 1'b1);
  endproperty
  a_stop_bit_high: assert property(p_stop_bit_high)
    else $error("UART stop bit not high after start bit");

  initial begin
    rx = 1'b1;
    rst_n = 1'b0;
  end
endinterface
