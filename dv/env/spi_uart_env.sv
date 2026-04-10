`timescale 1ns/1ps

class spi_uart_env extends uvm_env;
  `uvm_component_utils(spi_uart_env)
  spi_agent spi_ag;
  uart_agent uart_ag;
  spi_uart_scoreboard sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    spi_ag = spi_agent::type_id::create("spi_ag", this);
    uart_ag = uart_agent::type_id::create("uart_ag", this);
    sb = spi_uart_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    spi_ag.mon.ap.connect(sb.spi_imp);
    uart_ag.mon.ap.connect(sb.uart_imp);
  endfunction
endclass
