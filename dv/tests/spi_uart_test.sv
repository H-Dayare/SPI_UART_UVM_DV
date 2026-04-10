`timescale 1ns/1ps

class spi_uart_test extends uvm_test;
  `uvm_component_utils(spi_uart_test)
  spi_uart_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    env = spi_uart_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    spi_basic_seq spi_seq;
    uart_basic_seq uart_seq;
    phase.raise_objection(this);

    // Allow reset to deassert
    #50ns;

    spi_seq = spi_basic_seq::type_id::create("spi_seq");
    uart_seq = uart_basic_seq::type_id::create("uart_seq");

    fork
      spi_seq.start(env.spi_ag.seqr);
      uart_seq.start(env.uart_ag.seqr);
    join

    #100ns;
    phase.drop_objection(this);
  endtask
endclass
