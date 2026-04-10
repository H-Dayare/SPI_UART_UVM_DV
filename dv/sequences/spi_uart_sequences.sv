`timescale 1ns/1ps

class spi_basic_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_basic_seq)
  function new(string name = "spi_basic_seq");
    super.new(name);
  endfunction

  task body();
    spi_item tr;
    byte vals[$] = {8'h00, 8'hFF, 8'h55, 8'hAA, 8'h10, 8'hF0};
    foreach (vals[i]) begin
      tr = spi_item::type_id::create("tr");
      tr.data = vals[i];
      start_item(tr);
      finish_item(tr);
    end
    repeat (10) begin
      tr = spi_item::type_id::create("tr");
      assert(tr.randomize());
      start_item(tr);
      finish_item(tr);
    end
  endtask
endclass

class uart_basic_seq extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_basic_seq)
  function new(string name = "uart_basic_seq");
    super.new(name);
  endfunction

  task body();
    uart_item tr;
    byte vals[$] = {8'h00, 8'hFF, 8'h33, 8'hCC, 8'h0F, 8'hF0};
    foreach (vals[i]) begin
      tr = uart_item::type_id::create("tr");
      tr.data = vals[i];
      start_item(tr);
      finish_item(tr);
    end
    repeat (8) begin
      tr = uart_item::type_id::create("tr");
      assert(tr.randomize());
      start_item(tr);
      finish_item(tr);
    end
  endtask
endclass
