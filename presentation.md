# Fixed-Point NN Accelerator Presentation

## Project Summary

This project implements a modular RTL accelerator for inference through a single fully connected neural-network layer using signed fixed-point arithmetic. The design targets a simple but realistic baseline architecture that is easy to verify, resource-efficient, and extensible to future parallel versions.

## Problem

The accelerator computes:

`y_i = max(0, sum_{j=0}^{N-1}(W[i][j] * x[j]) + b[i])`

for an input vector `x`, weight matrix `W`, and bias vector `b`.

This workload is well-suited for hardware acceleration because it is dominated by repeated multiply-accumulate operations, has deterministic control flow, and reuses the same input vector across multiple output neurons.

## Design

### Top-Level Architecture

- Input Buffer: stores streamed input activations
- Weight/Bias Memory: stores preloaded weights and biases
- Compute Core: performs a two-stage pipelined MAC
- Post-Processing Unit: adds bias, applies ReLU, and clamps the output range
- Controller FSM: sequences input loading, compute, post-processing, writeback, and output streaming
- Output Buffer: stores final output values before streaming

### Key Architectural Choice

The implemented baseline uses a **serial, time-multiplexed MAC datapath**:

- one multiplier reused across all inputs and outputs
- one accumulator reused across all output neurons
- pipelined multiply and accumulate stages for improved timing

This choice reduces area and complexity, at the cost of higher latency than a more parallel architecture.

## Verification

### Verification Method

The repository includes:

- SystemVerilog unit tests for each major module
- partial-datapath integration verification
- controller verification
- top-level accelerator verification
- a Python golden model for reference outputs

### Reference Test Case

For the included test vector:

- input: `[3, -2, 1, 4]`
- golden-model output: `[21, 0]`
- top-level RTL output: `[21, 0]`

This confirms agreement between the implemented RTL and the software reference for the verified case.

## Key Metrics

### Simulation

- all module-level testbenches passed
- controller FSM test passed
- top-level integrated accelerator test passed

### Synthesis

- Tool version: `2018.3`
- Target device: `xc7vx485tffg1157-1`
- LUTs: `246`
- FFs: `361`
- DSPs: `1`
- BRAM: `0`
- Achieved clock period: `7.447 ns`
- Fmax: `134.3 MHz`

### Performance

For the verified reference case `N = 4`, `M = 2`:

- cycles per inference: `23`
- latency: `171.3 ns`
- throughput: `5.84 M vectors/sec`

## Main Takeaway

The design meets its main goal: a clean, modular, resource-efficient baseline accelerator with strong verification evidence. The synthesis result confirms the intended serial-MAC tradeoff by using only one DSP, while still achieving reasonable performance for the tested problem size.

## Where To Look In The Repo

- project outline: [initial_plan.md](initial_plan.md)
- final design summary: [detailed_plan.md](detailed_plan.md)
- architecture: [docs/architecture.md](docs/architecture.md)
- interface definition: [docs/interface.md](docs/interface.md)
- verification evidence: [results/simulation/module_results.md](results/simulation/module_results.md)
- synthesis evidence: [results/synthesis/synthesis_summary.md](results/synthesis/synthesis_summary.md)
