`timescale 1ns/1ps

module uart_dut (
  input  logic baud_tick,
  input  logic rst_n,
  input  logic rx,
  output logic tx
);
  typedef enum logic [1:0] {RX_IDLE, RX_DATA, RX_STOP} rx_state_t;
  typedef enum logic [1:0] {TX_IDLE, TX_START, TX_DATA, TX_STOP} tx_state_t;

  rx_state_t rx_state;
  tx_state_t tx_state;

  logic [2:0] rx_bit_cnt;
  logic [2:0] tx_bit_cnt;
  logic [7:0] rx_shift;
  logic [7:0] tx_shift;
  logic       tx_busy;

  always_ff @(posedge baud_tick or negedge rst_n) begin
    if (!rst_n) begin
      rx_state   <= RX_IDLE;
      rx_bit_cnt <= 3'd0;
      rx_shift   <= 8'h00;
      tx_state   <= TX_IDLE;
      tx_bit_cnt <= 3'd0;
      tx_shift   <= 8'h00;
      tx         <= 1'b1;
      tx_busy    <= 1'b0;
    end else begin
      // RX state machine
      case (rx_state)
        RX_IDLE: begin
          if (rx == 1'b0) begin
            rx_state   <= RX_DATA;
            rx_bit_cnt <= 3'd0;
          end
        end
        RX_DATA: begin
          rx_shift[rx_bit_cnt] <= rx;
          if (rx_bit_cnt == 3'd7) begin
            rx_state <= RX_STOP;
          end
          rx_bit_cnt <= rx_bit_cnt + 3'd1;
        end
        RX_STOP: begin
          // On valid stop bit, launch TX if idle
          if (rx == 1'b1 && !tx_busy) begin
            tx_shift   <= rx_shift;
            tx_state   <= TX_START;
            tx_bit_cnt <= 3'd0;
            tx_busy    <= 1'b1;
          end
          rx_state <= RX_IDLE;
        end
        default: rx_state <= RX_IDLE;
      endcase

      // TX state machine
      case (tx_state)
        TX_IDLE: begin
          tx <= 1'b1;
        end
        TX_START: begin
          tx <= 1'b0;
          tx_state <= TX_DATA;
          tx_bit_cnt <= 3'd0;
        end
        TX_DATA: begin
          tx <= tx_shift[tx_bit_cnt];
          if (tx_bit_cnt == 3'd7) begin
            tx_state <= TX_STOP;
          end
          tx_bit_cnt <= tx_bit_cnt + 3'd1;
        end
        TX_STOP: begin
          tx <= 1'b1;
          tx_state <= TX_IDLE;
          tx_busy <= 1'b0;
        end
        default: tx_state <= TX_IDLE;
      endcase
    end
  end

endmodule
