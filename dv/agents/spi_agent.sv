`timescale 1ns/1ps

class spi_item extends uvm_sequence_item;
  rand byte data;
  `uvm_object_utils(spi_item)
  function new(string name = "spi_item");
    super.new(name);
  endfunction
endclass

class spi_driver extends uvm_driver #(spi_item);
  `uvm_component_utils(spi_driver)
  virtual spi_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("SPI_DRV", "virtual interface not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    spi_item tr;
    byte rx;
    forever begin
      seq_item_port.get_next_item(tr);
      vif.xfer(tr.data, rx);
      seq_item_port.item_done();
    end
  endtask
endclass

class spi_monitor extends uvm_component;
  `uvm_component_utils(spi_monitor)
  virtual spi_if vif;
  uvm_analysis_port #(spi_item) ap;
  byte spi_data;
  covergroup spi_cg;
    option.per_instance = 1;
    cp_data: coverpoint spi_data {
      bins low  = {[8'h00:8'h1F]};
      bins mid  = {[8'h20:8'hDF]};
      bins high = {[8'hE0:8'hFF]};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
    spi_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("SPI_MON", "virtual interface not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    spi_item tr;
    forever begin
      @(vif.byte_xfer_ev);
      tr = spi_item::type_id::create("tr");
      tr.data = vif.last_tx;
      spi_data = tr.data;
      spi_cg.sample();
      ap.write(tr);
      if (vif.last_rx !== vif.last_tx) begin
        `uvm_error("SPI_MON", $sformatf("Loopback mismatch tx=%0h rx=%0h", vif.last_tx, vif.last_rx))
      end
    end
  endtask
endclass

class spi_agent extends uvm_component;
  `uvm_component_utils(spi_agent)
  uvm_sequencer #(spi_item) seqr;
  spi_driver drv;
  spi_monitor mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    seqr = uvm_sequencer#(spi_item)::type_id::create("seqr", this);
    drv  = spi_driver::type_id::create("drv", this);
    mon  = spi_monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
