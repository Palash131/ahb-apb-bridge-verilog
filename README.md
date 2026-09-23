# RTL Design Portfolio — AHB-to-APB Bridge & Intel 4004 Datapath

A collection of synthesizable RTL designs written in Verilog, built and verified using **Intel Quartus Prime** and standard simulation tools.

---

## 📦 Projects

### 1. AHB-to-APB Bridge

An AMBA-compliant bus bridge that translates AHB (Advanced High-performance Bus) transactions to APB (Advanced Peripheral Bus) protocol — a fundamental building block in ARM-based SoC designs.

**Architecture:**

```
AHB Master
    │
    ▼
┌─────────────────┐
│   AHB Slave     │  ← Address decoding, pipeline registers, HREADY logic
│  (AHB_slave.v)  │
└────────┬────────┘
         │  valid, haddr1/2, hwdata1/2, hwritereg, tempselx
         ▼
┌─────────────────┐
│  APB Controller │  ← 8-state FSM: IDLE → WAIT → WRITE/READ → ENABLE
│(apb_controller.v│
└────────┬────────┘
         │  psel, penable, pwrite, paddr, pwdata
         ▼
    APB Slave(s)
```

**Key Features:**
- Supports **NONSEQ** and **SEQ** AHB transfer types (`HTRANS = 2'b10 / 2'b11`)
- Decodes 3 APB slave regions across a 64 MB address space (`0x8000_0000` – `0x8BFF_FFFF`)
- Fully pipelined — handles back-to-back read & write transactions
- Clean 8-state Mealy FSM with registered outputs (no glitch on APB bus)
- Asynchronous active-low reset

**Files:**

| File | Description |
|------|-------------|
| [`AHB_slave.v`](AHB_slave.v) | AHB slave interface — pipeline registers, address decoder, `valid` signal |
| [`apb_controller.v`](apb_controller.v) | APB FSM controller — state machine + registered APB output signals |
| [`bridge_top.v`](bridge_top.v) | Top-level module — instantiates and connects both sub-modules |
| [`AHB_slave_tb.v`](AHB_slave_tb.v) | Testbench — exercises read/write to all 3 slave select regions |

**State Machine:**

```
IDLE ──(valid & write)──► WAIT ──(valid)──► WRITEP ──► WENABLEP ─┐
  │                         │                                      │
  │                         └──(~valid)──► WRITE ──► WENABLE     │
  │                                                                │
  └──(valid & read)──► READ ──► RENABLE ◄──────────────────────────┘
```

---

### 2. Intel 4004 Datapath

A synthesizable RTL model of the **datapath** of the Intel 4004 — the world's first commercially available microprocessor (1971). This design is controlled by external control signals (mimicking what a separate Control Unit would drive).

**Implemented Datapath Components:**

| Component | Width | Description |
|-----------|-------|-------------|
| Bi-directional Data Bus Buffer | 4-bit | Tri-state driver for external `D0–D3` pins |
| Instruction Register | 8-bit | Serial shift-in (4 bits/cycle) from internal bus |
| Accumulator | 4-bit | Destination register for all ALU operations |
| Temp Register | 4-bit | ALU source operand register |
| ALU | 4-bit | ADD, SUB, AND, OR, NOT operations |
| Scratch Pad | 16 × 4-bit | General-purpose register file (Index Registers R0–R15) |
| Address Stack | 4 × 12-bit | 3-level subroutine call stack + Program Counter |

**File:**

| File | Description |
|------|-------------|
| [`intel_4004_datapath.v`](intel_4004_datapath.v) | Complete synthesizable datapath — all components + internal bus routing |

---

## 🛠 Tools Used

- **Intel Quartus Prime** — Synthesis & implementation
- **ModelSim / QuestaSim** — Functional simulation
- **Verilog HDL** (IEEE 1364-2001)

---

## 🎯 Concepts Demonstrated

- AMBA AHB/APB protocol implementation
- Finite State Machine (FSM) design with registered outputs
- Pipelined bus interfaces
- Tri-state bus drivers
- Register file design
- Stack-based program counter
- Synthesizable RTL coding style
