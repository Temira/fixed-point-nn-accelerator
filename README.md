# Fixed-Point NN Accelerator

This repository implements and documents a modular RTL accelerator for inference through a single fully connected neural-network layer using signed fixed-point arithmetic. The project is organized so a grader can read the design definition, inspect the module partitioning, and find verification and synthesis evidence without needing to execute the code.

## What The IP Does

The accelerator computes one dense layer with ReLU activation:

`y_i = max(0, sum_{j=0}^{N-1}(W[i][j] * x[j]) + b[i])`

The intended usage model is:

1. receive one input vector `x`
2. store that vector in an input buffer
3. reuse `x` across all output neurons
4. multiply-accumulate against weights `W`
5. add bias `b`
6. apply ReLU and output-range clamping
7. stream or read back the output vector `y`

## Submission Map

- [`docs/interface.md`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/docs/interface.md): IP role, data flow, and planned PS/IP interface
- [`docs/architecture.md`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/docs/architecture.md): module decomposition, block diagram, serial-MAC architecture choices
- [`docs/verification.md`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/docs/verification.md): automated tests, golden-model comparison, and integration verification
- [`results/simulation/module_results.md`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/results/simulation/module_results.md): simulation evidence page
- [`results/synthesis/synthesis_summary.md`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/results/synthesis/synthesis_summary.md): synthesis evidence page

## IP Interface Definition

### Current verification-level interface

The repository currently contains module-level, datapath-level, and integrated top-level RTL interfaces used for simulation:

- buffers use `write_en`, `write_addr`, `write_data`, `read_addr`, `read_data`
- parameter memory uses `weight_addr`, `weight_data`, `bias_addr`, `bias_data`
- post-processing uses `acc`, `bias`, `enabled`, `out_data`
- compute core uses `mac_enable`, `acc_reset`, `x_data`, `w_data`, `mul_out`, `acc_out`
- controller and top-level integration use `start`, `in_valid`, `in_ready`, `out_valid`, `busy`, and `done`

### Planned deployable system interface

The top-level accelerator is intended to be wrapped with:

- `AXI4-Stream` for input vector and output vector transport
- `AXI4-Lite` for control and status registers such as `start`, `done`, and `busy`

That system-level message flow is documented in [`docs/interface.md`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/docs/interface.md).

## Architecture And Module Partitioning

The design is explicitly partitioned into logical blocks:

- `rtl/input_buffer.sv`
- `rtl/weight_bias_mem.sv`
- `rtl/compute_core.sv`
- `rtl/post_processing_unit.sv`
- `rtl/controller_fsm.sv`
- `rtl/output_buffer.sv`
- `rtl/nn_accelerator.sv`

The chosen architecture is a serial, time-multiplexed MAC datapath with a two-stage pipelined MAC core and an FSM-driven control path. That tradeoff reduces area and simplifies verification at the cost of latency. The architecture page explains how this partition supports unit testing, partial integration testing, and end-to-end top-level integration.

## Verification Strategy

The verification story is split into module-level checks, partial-datapath integration, control/compute verification, and end-to-end top-level evidence:

### Module-level tests owned in this split

- `tb/tb_input_buffer.sv`
- `tb/tb_weight_bias_mem.sv`
- `tb/tb_compute_core.sv`
- `tb/tb_post_processing_unit.sv`
- `tb/tb_output_buffer.sv`
- `tb/tb_datapath_partial.sv`
- `tb/tb_controller_fsm.sv`
- `tb/tb_nn_accelerator.sv`

### Golden-model reference

- `model/golden_model.py`

### Automated entry points

The repository includes a [`Makefile`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/Makefile) with named targets for the Python golden model and each SystemVerilog testbench.

If you want a single command for the full verification flow implemented in this repo, use [`scripts/run_all_tests.sh`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/scripts/run_all_tests.sh).

## Current Evidence Status

### Available now

- RTL modules and matching testbenches for input buffering, parameter memory, compute, post-processing, control, output buffering, and top-level integration
- deterministic memory preload vectors in `tb/test_vectors/`
- Python golden model for dense-layer reference outputs
- completed module-level, control-path, partial-datapath, and top-level simulation evidence in `results/simulation/module_results.md`
- submission-facing markdown pages for synthesis evidence

### Still required before final grading

- copied synthesis/timing/resource summaries in `results/synthesis/synthesis_summary.md`
- latency and throughput analysis against the initial serial-MAC design goals
- synthesis and timing evidence for the integrated accelerator

## Repository Layout

```text
.
├── README.md
├── Makefile
├── docs/
├── model/
├── results/
├── rtl/
├── scripts/
├── tb/
├── initial_plan.md
├── plan.md
└── LICENSE
```
