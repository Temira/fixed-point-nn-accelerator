# Detailed Plan And Final Design Notes

This document records the detailed architecture, implementation decisions, and deviations from the initial outline for the fixed-point neural-network accelerator.

## Final Scope

The implemented design targets inference for a single fully connected layer with ReLU activation using signed fixed-point arithmetic:

`y_i = max(0, sum_{j=0}^{N-1}(W[i][j] * x[j]) + b[i])`

The implemented repository includes:

- modular RTL for input buffering, parameter memory, compute, post-processing, control, output buffering, and top-level integration
- SystemVerilog unit and integration testbenches
- a Python golden model for reference outputs
- simulation result summaries and synthesis summaries in Markdown

## Final Module Partitioning

### Input Buffer

- file: [rtl/input_buffer.sv](rtl/input_buffer.sv)
- role: stores streamed input activations and provides indexed read access during compute

### Weight/Bias Memory

- file: [rtl/weight_bias_mem.sv](rtl/weight_bias_mem.sv)
- role: stores preloaded weights and biases using deterministic `.mem` files

### Compute Core

- file: [rtl/compute_core.sv](rtl/compute_core.sv)
- role: performs the pipelined multiply-accumulate operation
- implementation note: the compute path is split into a multiply stage and an accumulate stage

### Post-Processing Unit

- file: [rtl/post_processing_unit.sv](rtl/post_processing_unit.sv)
- role: applies bias addition, ReLU, and output-range saturation

### Controller FSM

- file: [rtl/controller_fsm.sv](rtl/controller_fsm.sv)
- role: sequences input loading, MAC scheduling, post-processing, output writes, and output streaming

### Output Buffer

- file: [rtl/output_buffer.sv](rtl/output_buffer.sv)
- role: stores final output values before they are streamed out

### Top-Level Integration

- file: [rtl/nn_accelerator.sv](rtl/nn_accelerator.sv)
- role: connects all submodules into one accelerator path

## Interface Strategy

### Current implemented verification interface

The repository verifies the design using a direct RTL interface:

- `start`, `in_valid`, `in_ready`
- `busy`, `done`, `out_valid`
- streamed input samples through `in_data`
- streamed output samples through `out_data`

### Planned deployment interface

The design documentation assumes:

- `AXI4-Stream` for input and output vectors
- `AXI4-Lite` for control/status (`start`, `done`, `busy`)

That boundary is explained in [docs/interface.md](docs/interface.md).

## Implementation Deviations From The Initial Plan

The final repository goes beyond the earliest ownership split:

- the compute core and controller FSM are now implemented rather than remaining only partner-owned placeholders
- the repo includes integrated top-level verification, not only module-level datapath tests
- synthesis results are now documented in [results/synthesis/synthesis_summary.md](results/synthesis/synthesis_summary.md)

## Verification And Results

Primary evidence files:

- simulation: [results/simulation/module_results.md](results/simulation/module_results.md)
- synthesis: [results/synthesis/synthesis_summary.md](results/synthesis/synthesis_summary.md)

## Navigation

For a grader starting from the repo root:

- [README.md](README.md) is the main landing page
- [initial_plan.md](initial_plan.md) captures the original project outline
- [detailed_plan.md](detailed_plan.md) summarizes the final implemented architecture
