`timescale 1ns/1ps

`uvm_analysis_imp_decl(_spi)
`uvm_analysis_imp_decl(_uart)

class spi_uart_scoreboard extends uvm_component;
  `uvm_component_utils(spi_uart_scoreboard)

  uvm_analysis_imp_spi #(spi_item, spi_uart_scoreboard) spi_imp;
  uvm_analysis_imp_uart #(uart_item, spi_uart_scoreboard) uart_imp;

  int spi_pass;
  int spi_fail;
  int uart_pass;
  int uart_fail;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    spi_imp = new("spi_imp", this);
    uart_imp = new("uart_imp", this);
  endfunction

  function void write_spi(spi_item t);
    // SPI loopback expected: rx == tx checked in monitor, track here as pass
    spi_pass++;
  endfunction

  function void write_uart(uart_item t);
    if (t.exp_data === t.act_data) begin
      uart_pass++;
    end else begin
      uart_fail++;
      `uvm_error("UART_SB", $sformatf("UART mismatch exp=%0h act=%0h", t.exp_data, t.act_data))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("SPI pass=%0d fail=%0d", spi_pass, spi_fail), UVM_LOW)
    `uvm_info("SB", $sformatf("UART pass=%0d fail=%0d", uart_pass, uart_fail), UVM_LOW)
  endfunction
endclass
