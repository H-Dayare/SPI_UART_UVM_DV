# SPI + UART RTL & UVM Verification Environment

A dual-protocol verification project implementing SPI and UART DUTs in SystemVerilog, verified
with a shared UVM environment featuring two independent agents, protocol-level SVA assertions,
functional coverage, and a self-checking scoreboard — all running concurrently in a single test.

---

## Overview

| Attribute          | SPI                              | UART                             |
|--------------------|----------------------------------|----------------------------------|
| DUT behaviour      | Loopback (MISO mirrors MOSI)     | Receive → retransmit loopback    |
| Protocol mode      | Mode 0 (CPOL=0, CPHA=0), MSB-first | 8N1 (8 data, no parity, 1 stop), LSB-first |
| Stimulus           | Directed corner cases + constrained-random | Directed corner cases + constrained-random |
| Checker            | Inline monitor check + scoreboard  | Scoreboard exp vs. act comparison |
| Coverage           | 3-bin data value coverage          | 3-bin exp and act coverage        |
| SVA                | SCLK only toggling when CS_N low   | Stop bit high after start bit     |
| Simulator tested   | Questa (QuestaSim)                 | Questa (QuestaSim)                |

---

## Repository Structure

```
.
├── rtl/
│   ├── spi_dut.sv              # SPI DUT: samples MOSI on posedge SCLK when cs_n=0 → MISO
│   └── uart_dut.sv             # UART DUT: 8N1 RX FSM captures byte, TX FSM retransmits
├── dv/
│   ├── spi_uart_pkg.sv         # Top-level UVM package — includes all DV components
│   ├── tb_top.sv               # Testbench top: DUT instantiation, clocks, reset, config_db
│   ├── interfaces/
│   │   ├── spi_if.sv           # SPI virtual interface: xfer() task, byte event, SVA
│   │   └── uart_if.sv          # UART virtual interface: send_byte() task, byte event, SVA
│   ├── agents/
│   │   ├── spi_agent.sv        # SPI item, driver, monitor (coverage), agent
│   │   └── uart_agent.sv       # UART item, driver, monitor (coverage + queue), agent
│   ├── env/
│   │   ├── spi_uart_env.sv     # Environment: instantiates both agents + scoreboard, wires APs
│   │   └── scoreboard.sv       # Dual-imp scoreboard: SPI loopback tracking, UART exp/act check
│   ├── sequences/
│   │   └── spi_uart_sequences.sv # spi_basic_seq, uart_basic_seq (directed + random)
│   └── tests/
│       └── spi_uart_test.sv    # Top test: forks SPI and UART sequences concurrently
└── docs/
    └── SPI UART Project.pdf    # Project specification
```

---

## RTL — DUT Descriptions

### SPI DUT (`spi_dut.sv`)
Simple loopback: on every rising edge of `sclk`, if `cs_n` is low, `miso` is registered from `mosi`.
Tests the ability to drive and receive an 8-bit MSB-first SPI transfer and verify byte integrity.

### UART DUT (`uart_dut.sv`)
An 8N1 receive-then-retransmit loopback using two independent FSMs clocked by `baud_tick`:

| FSM | States | Behaviour |
|-----|--------|-----------|
| RX  | `RX_IDLE → RX_DATA → RX_STOP` | Detects start bit, shifts 8 data bits LSB-first into `rx_shift`, on valid stop bit triggers TX |
| TX  | `TX_IDLE → TX_START → TX_DATA → TX_STOP` | Drives start bit, shifts out captured byte, drives stop bit |

---

## UVM Testbench Architecture

```
spi_uart_test
└── spi_uart_env
    ├── spi_agent
    │   ├── uvm_sequencer ──► spi_driver  ──► spi_if.xfer()  ──► spi_dut
    │   └── spi_monitor   ◄── spi_if.byte_xfer_ev
    │           │ (spi_cg coverage sample + inline loopback check)
    │           └── analysis_port (spi) ──► scoreboard.spi_imp
    │
    ├── uart_agent
    │   ├── uvm_sequencer ──► uart_driver  ──► uart_if.send_byte() ──► uart_dut
    │   └── uart_monitor  ◄── uart_if (rx_byte_ev + TX bit sampling)
    │           │ (uart_cg coverage sample)
    │           └── analysis_port (uart) ──► scoreboard.uart_imp
    │
    └── spi_uart_scoreboard
            ├── write_spi()  — tracks SPI pass count (loopback check in monitor)
            └── write_uart() — compares exp_data vs. act_data, flags UVM_ERROR on mismatch
```

---

## Protocol Interfaces & SVA

### `spi_if.sv`
- **`xfer(tx, rx)`** task — drives 8 bits MSB-first: asserts CS_N, toggles SCLK, samples MISO each cycle
- **`byte_xfer_ev`** — event triggered after each complete transfer; monitor wakes on this
- **SVA:** `a_sclk_only_when_cs_low` — asserts that SCLK never toggles while CS_N is high

```systemverilog
property p_sclk_only_when_cs_low;
  @(posedge sclk) !cs_n;
endproperty
```

### `uart_if.sv`
- **`send_byte(data)`** task — drives start bit, 8 data bits LSB-first, stop bit, each one baud tick wide
- **`rx_byte_ev`** — event triggered after each byte is sent; monitor queues expected data
- **SVA:** `a_stop_bit_high` — asserts that 9 baud ticks after a start bit, the line is high

```systemverilog
property p_stop_bit_high;
  @(posedge baud_tick) (rx == 1'b0) |-> ##9 (rx == 1'b1);
endproperty
```

---

## Verification Plan

| Check | Mechanism | Status |
|-------|-----------|--------|
| SPI: MISO matches MOSI for every bit | Monitor inline check (`last_rx !== last_tx`) | ✔ Implemented |
| SPI: SCLK protocol compliance | SVA `a_sclk_only_when_cs_low` | ✔ Implemented |
| UART: transmitted byte matches received byte | Scoreboard `write_uart` exp vs. act | ✔ Implemented |
| UART: stop bit protocol compliance | SVA `a_stop_bit_high` | ✔ Implemented |
| SPI: all-zeros and all-ones byte transfers | Directed values `{8'h00, 8'hFF}` in `spi_basic_seq` | ✔ Covered |
| SPI: alternating-bit patterns | Directed values `{8'h55, 8'hAA, 8'hF0, 8'h10}` | ✔ Covered |
| SPI: random byte values | 10 randomized transfers per run | ✔ Covered |
| UART: all-zeros and all-ones byte transfers | Directed values `{8'h00, 8'hFF}` in `uart_basic_seq` | ✔ Covered |
| UART: alternating-bit patterns | Directed values `{8'h33, 8'hCC, 8'h0F, 8'hF0}` | ✔ Covered |
| UART: random byte values | 8 randomized transfers per run | ✔ Covered |
| Concurrent SPI and UART operation | `fork...join` in test run_phase | ✔ By construction |

---

## Functional Coverage Model

### SPI — `spi_cg` (in `spi_monitor`)

| Coverpoint | Bins | Description |
|------------|------|-------------|
| `cp_data`  | `low [0x00–0x1F]` | Low byte values |
|            | `mid [0x20–0xDF]` | Mid-range values |
|            | `high [0xE0–0xFF]` | High byte values |

### UART — `uart_cg` (in `uart_monitor`)

| Coverpoint | Bins | Description |
|------------|------|-------------|
| `cp_exp`   | `zero {0x00}`, `ones {0xFF}`, `mid [0x01–0xFE]` | Expected byte value distribution |
| `cp_act`   | `zero {0x00}`, `ones {0xFF}`, `mid [0x01–0xFE]` | Actual received byte distribution |

Directed sequences target the boundary bins (`0x00`, `0xFF`) explicitly; random transactions
fill the `mid` bin. Target: **≥80% coverage** across both covergroups.

---

## Scoreboard — Self-Checking Design

**SPI:** The monitor performs an inline loopback check (`last_rx !== last_tx → UVM_ERROR`).
The scoreboard receives passing transactions and maintains a `spi_pass` counter for the report.

**UART:** The monitor independently tracks injected bytes in an expected queue (`exp_q[$]`).
When the TX bit-sampler observes a complete byte, it pops the queue and writes a `uart_item`
with both `exp_data` and `act_data` to the scoreboard. Any mismatch triggers `UVM_ERROR`.

`report_phase` prints final pass/fail counts for both protocols:
```
UVM_INFO SB: SPI pass=16 fail=0
UVM_INFO SB: UART pass=14 fail=0
```

---

## Simulation — Quick Start (Questa)

```tcl
# Compile and run in one step
vlib work
vlog -sv \
  +incdir+dv \
  dv/interfaces/spi_if.sv \
  dv/interfaces/uart_if.sv \
  rtl/spi_dut.sv \
  rtl/uart_dut.sv \
  dv/spi_uart_pkg.sv \
  dv/tb_top.sv \
  +define+UVM_NO_DEPRECATED

vsim -c tb_top -do "run -all; quit" +UVM_TESTNAME=spi_uart_test

# With full UVM message verbosity
vsim -c tb_top -do "run -all; quit" \
  +UVM_TESTNAME=spi_uart_test \
  +UVM_VERBOSITY=UVM_HIGH
```

Expected pass output:
```
UVM_INFO ... SB: SPI pass=16 fail=0
UVM_INFO ... SB: UART pass=14 fail=0
UVM_INFO ... UVM_ERROR : 0
UVM_INFO ... UVM_FATAL : 0
```

---

## Skills Demonstrated

- **UVM 1.2**: dual-agent environment, `uvm_config_db`, analysis ports with `uvm_analysis_imp_decl`, factory, objection mechanism
- **Protocol-level interfaces**: encapsulated transfer tasks (`xfer`, `send_byte`), event-driven monitor synchronization
- **SystemVerilog Assertions (SVA)**: concurrent properties in interfaces, protocol compliance checking
- **Functional coverage**: `covergroup` with directed bin targeting, inline sampling in monitors
- **Self-checking scoreboard**: expected-queue model for UART, inline check for SPI, `report_phase` summary
- **Concurrent verification**: `fork...join` for simultaneous multi-protocol stimulus
- **RTL design**: FSM-based UART (8N1), registered SPI loopback, `always_ff` state machines
- **Constrained-random + directed hybrid**: corner-case vectors combined with `randomize()`
