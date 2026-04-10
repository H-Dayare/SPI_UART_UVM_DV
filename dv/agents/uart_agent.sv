`timescale 1ns/1ps

class uart_item extends uvm_sequence_item;
  rand byte data;
  byte exp_data;
  byte act_data;
  `uvm_object_utils(uart_item)
  function new(string name = "uart_item");
    super.new(name);
  endfunction
endclass

class uart_driver extends uvm_driver #(uart_item);
  `uvm_component_utils(uart_driver)
  virtual uart_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("UART_DRV", "virtual interface not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    uart_item tr;
    forever begin
      seq_item_port.get_next_item(tr);
      vif.send_byte(tr.data);
      seq_item_port.item_done();
    end
  endtask
endclass

class uart_monitor extends uvm_component;
  `uvm_component_utils(uart_monitor)
  virtual uart_if vif;
  uvm_analysis_port #(uart_item) ap;
  byte exp_q[$];
  byte exp_data;
  byte act_data;

  covergroup uart_cg;
    option.per_instance = 1;
    cp_exp: coverpoint exp_data {
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins mid  = {[8'h01:8'hFE]};
    }
    cp_act: coverpoint act_data {
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins mid  = {[8'h01:8'hFE]};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
    uart_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("UART_MON", "virtual interface not set")
    end
  endfunction

  task automatic sample_tx_byte(output byte data);
    integer i;
    data = 8'h00;
    // wait for start bit
    @(posedge vif.baud_tick);
    while (vif.tx == 1'b1) begin
      @(posedge vif.baud_tick);
    end
    // data bits
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge vif.baud_tick);
      data[i] = vif.tx;
    end
    // stop bit
    @(posedge vif.baud_tick);
  endtask

  task run_phase(uvm_phase phase);
    fork
      forever begin
        @(vif.rx_byte_ev);
        exp_q.push_back(vif.last_rx_data);
      end
      forever begin
        byte tx_data;
        sample_tx_byte(tx_data);
        if (exp_q.size() == 0) begin
          `uvm_warning("UART_MON", $sformatf("TX byte %0h observed with no expected data", tx_data))
        end else begin
          uart_item tr;
          tr = uart_item::type_id::create("tr");
          tr.exp_data = exp_q.pop_front();
          tr.act_data = tx_data;
          exp_data = tr.exp_data;
          act_data = tr.act_data;
          uart_cg.sample();
          ap.write(tr);
        end
      end
    join
  endtask
endclass

class uart_agent extends uvm_component;
  `uvm_component_utils(uart_agent)
  uvm_sequencer #(uart_item) seqr;
  uart_driver drv;
  uart_monitor mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    seqr = uvm_sequencer#(uart_item)::type_id::create("seqr", this);
    drv  = uart_driver::type_id::create("drv", this);
    mon  = uart_monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
