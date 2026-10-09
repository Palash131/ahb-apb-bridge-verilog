# AHB-to-APB Bridge RTL Design

A synthesizable AMBA-compliant bus bridge RTL design written in Verilog, built and verified using **Intel Quartus Prime** and standard simulation tools.

---

## 📦 Project Overview

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

## 🛠 Tools Used

- **Intel Quartus Prime** — Synthesis & implementation
- **ModelSim / QuestaSim** — Functional simulation
- **Verilog HDL** (IEEE 1364-2001)

---

## 🎯 Concepts Demonstrated

- AMBA AHB/APB protocol implementation
- Finite State Machine (FSM) design with registered outputs
- Pipelined bus interfaces
- Synthesizable RTL coding style
