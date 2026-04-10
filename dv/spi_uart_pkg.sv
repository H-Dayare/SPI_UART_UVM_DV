`timescale 1ns/1ps
package spi_uart_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "dv/agents/spi_agent.sv"
  `include "dv/agents/uart_agent.sv"
  `include "dv/env/scoreboard.sv"
  `include "dv/env/spi_uart_env.sv"
  `include "dv/sequences/spi_uart_sequences.sv"
  `include "dv/tests/spi_uart_test.sv"
endpackage
