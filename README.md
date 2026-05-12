# Fixed-Point NN Accelerator

This repository implements and documents a modular RTL accelerator for inference through a single fully connected neural-network layer using signed fixed-point arithmetic. The project is organized so a grader can read the design definition, inspect the module partitioning, and find verification and synthesis evidence without needing to execute the code.

## Project Team

- Temira Koenig
- Zihao Zhang

The original project outline is included in [initial_plan.md](initial_plan.md).

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

## Video Presentation
- [Link](presentation/video.md) to recorded presentation on YouTube

## Submission Map

- [docs/interface.md](docs/interface.md): IP role, data flow, and planned PS/IP interface
- [docs/architecture.md](docs/architecture.md): module decomposition, block diagram, serial-MAC architecture choices
- [docs/verification.md](docs/verification.md): automated tests, golden-model comparison, and integration verification
- [initial_plan.md](initial_plan.md): original project outline
- [detailed_plan.md](detailed_plan.md): final implementation-oriented design summary
- [presentation.md](presentation.md): presentation-style summary of the problem, design, and key results
- [results/index.md](results/index.md): results landing page
- [results/simulation/module_results.md](results/simulation/module_results.md): simulation evidence page
- [results/synthesis/synthesis_summary.md](results/synthesis/synthesis_summary.md): synthesis evidence page
- [presentation/video.md](presentation/video.md): link to YouTube video

## Evidence At A Glance

The two most important evidence pages are:

- simulation evidence: [results/simulation/module_results.md](results/simulation/module_results.md)
- synthesis and timing evidence: [results/synthesis/synthesis_summary.md](results/synthesis/synthesis_summary.md)

### Simulation Summary

| Area | Evidence |
|---|---|
| Module verification | `tb_input_buffer`, `tb_weight_bias_mem`, `tb_compute_core`, `tb_post_processing_unit`, and `tb_output_buffer` all pass |
| Controller verification | `tb_controller_fsm` passes and confirms expected control pulse counts |
| Partial integration | `tb_datapath_partial` passes for the reference vector set |
| Top-level integration | `tb_nn_accelerator` passes and produces output `[21, 0]` |
| Golden-model reference | Python reference model in `model/golden_model.py` also produces `[21, 0]` for the same vector set |

### Synthesis Summary

| Metric | Value |
|---|---|
| Tool version | 2018.3 |
| Target device | `xc7vx485tffg1157-1` |
| Top module | `nn_accelerator` |
| LUTs | 246 |
| FFs | 361 |
| DSPs | 1 |
| Achieved clock period | 7.447 ns |
| Fmax | 134.3 MHz |
| Reference-case latency | 171.3 ns |
| Reference-case throughput | 5.84 M vectors/sec |

This root page intentionally repeats the key results so a grader can confirm that the repository contains populated verification and synthesis evidence without needing to guess where the important files are.

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

That system-level message flow is documented in [docs/interface.md](docs/interface.md).

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

Key RTL anchors for these claims are:

- the two-stage MAC behavior in [compute_core.sv](rtl/compute_core.sv#L20)
- the controller state machine and scheduling logic in [controller_fsm.sv](rtl/controller_fsm.sv#L30)
- the top-level datapath/control integration in [nn_accelerator.sv](rtl/nn_accelerator.sv#L45)

## Efficiency Tradeoffs

The implementation makes the area/throughput tradeoff explicit rather than hiding it:

- one multiplier is reused across all `N` inputs and all `M` outputs
- one accumulator is reused across all output neurons
- the compute path is pipelined into multiply and accumulate stages to shorten the critical combinational path
- the controller sequences work serially, which increases latency but keeps the datapath compact

These are visible directly in the RTL:

- `mul_reg` and `mul_valid` implement the pipelined multiply stage in [compute_core.sv](rtl/compute_core.sv#L16)
- the accumulator update that consumes the prior-cycle multiplication result appears in [compute_core.sv](rtl/compute_core.sv#L30)
- the serial scheduling over input and output indices appears in [controller_fsm.sv](rtl/controller_fsm.sv#L104) and [controller_fsm.sv](rtl/controller_fsm.sv#L119)

For the current baseline controller in [rtl/controller_fsm.sv](rtl/controller_fsm.sv), the cycle budget is:

- input load: `N` cycles
- per output neuron: `1` reset + `N` feed cycles + `1` drain + `1` post-process + `1` writeback = `N + 4` cycles
- output streaming: `M` cycles
- completion pulse / return-to-idle overhead: `1` cycle

So the baseline total is approximately:

`cycles_per_inference = N + M * (N + 4) + M + 1`

For the currently tested configuration `N = 4`, `M = 2`:

`cycles_per_inference = 4 + 2 * (4 + 4) + 2 + 1 = 23 cycles`

This is not a high-throughput architecture, but it is resource-efficient and easy to verify. That is the intended baseline tradeoff for this project.

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

The repository includes a [Makefile](Makefile) with named targets for the Python golden model and each SystemVerilog testbench.

If you want a single command for the full verification flow implemented in this repo, use [scripts/run_all_tests.sh](scripts/run_all_tests.sh).

## Current Evidence Status

- RTL modules and matching testbenches for input buffering, parameter memory, compute, post-processing, control, output buffering, and top-level integration
- deterministic memory preload vectors in `tb/test_vectors/`
- Python golden model for dense-layer reference outputs
- completed module-level, control-path, partial-datapath, and top-level simulation evidence in `results/simulation/module_results.md`
- completed synthesis and timing evidence in `results/synthesis/synthesis_summary.md`

## Repository Layout

```text
.
├── README.md
├── Makefile
├── docs/
├── model/
├── presentation/
├── results/
├── rtl/
├── scripts/
├── tb/
├── initial_plan.md
├── plan.md
└── LICENSE
```
