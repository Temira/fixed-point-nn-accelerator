# Verification Plan And Evidence

## Verification Scope

This repository now includes verification for the module-level datapath blocks, the pipelined compute core, the controller FSM, and an integrated top-level accelerator path.

## Automated Test Entry Points

The repository includes a [Makefile](../Makefile) so module tests can be run consistently:

- `make golden`
- `make test-input-buffer`
- `make test-weight-bias-mem`
- `make test-compute-core`
- `make test-post-processing`
- `make test-output-buffer`
- `make test-datapath-partial`
- `make test-controller-fsm`
- `make test-top-level`

For a one-shot run of the owned verification flow, use [scripts/run_all_tests.sh](../scripts/run_all_tests.sh).

## Module-Level Verification Matrix

| Module | Testbench | What it proves | Evidence status |
|---|---|---|---|
| `input_buffer` | `tb/tb_input_buffer.sv` | reset behavior, indexed writes, indexed reads, overwrite behavior | RTL/testbench present |
| `weight_bias_mem` | `tb/tb_weight_bias_mem.sv` | deterministic preload from `weights.mem` and `biases.mem`, correct indexed reads | RTL/testbench present |
| `compute_core` | `tb/tb_compute_core.sv` | accumulator reset, MAC pipeline latency, staged accumulation, drain behavior | RTL/testbench present |
| `post_processing_unit` | `tb/tb_post_processing_unit.sv` | bias addition, negative clamp to zero, positive saturation, disabled output behavior | RTL/testbench present |
| `output_buffer` | `tb/tb_output_buffer.sv` | reset behavior, sequential writes, random-access reads, overwrite behavior | RTL/testbench present |
| `controller_fsm` | `tb/tb_controller_fsm.sv` | transaction sequencing, control-signal pulse counts, load/compute/post/write/output phases | RTL/testbench present |

## Partial Datapath Verification

[tb/tb_datapath_partial.sv](../tb/tb_datapath_partial.sv) provides an integration-oriented check across the modules owned in this split:

1. load a known input vector into `input_buffer`
2. read deterministic parameters from `weight_bias_mem`
3. emulate the missing compute accumulation inside the testbench
4. feed the accumulator result into `post_processing_unit`
5. store the final values in `output_buffer`
6. read back the stored outputs and compare against expected values

For the included test vectors, the golden-model output is:

| Input vector | Output vector |
|---|---|
| `[3, -2, 1, 4]` | `[21, 0]` |

## Top-Level Integration Verification

[tb/tb_nn_accelerator.sv](../tb/tb_nn_accelerator.sv) verifies the full implemented accelerator path:

1. assert `start`
2. stream in one input vector through the top-level interface
3. allow the controller FSM to load inputs, sequence the compute core, trigger post-processing, and write the output buffer
4. observe streamed outputs at the top level
5. compare those outputs against the golden-model reference

For the included reference vector set, the top-level RTL output matches the golden-model output `[21, 0]`.

## Performance Interpretation Before Synthesis

Even before post-synthesis timing is available, the current RTL already shows the intended efficiency tradeoff:

- the controller issues `M * N` MAC-enable pulses, which matches the expected number of multiply-accumulate operations
- the compute core uses a two-stage pipeline, so multiplication and accumulation are separated across cycles
- only one MAC datapath is instantiated, so hardware is reused across all outputs rather than replicated

These claims can be checked directly in the RTL:

- MAC pipeline registers and accumulation behavior: [compute_core.sv](../rtl/compute_core.sv#L16)
- controller state sequencing and pulse generation: [controller_fsm.sv](../rtl/controller_fsm.sv#L93)
- top-level binding of controller, compute core, post-processing, and buffers: [nn_accelerator.sv](../rtl/nn_accelerator.sv#L45)

For the current baseline controller, the estimated cycle count per inference is:

`cycles_per_inference = N + M * (N + 4) + M + 1`

For the verified test configuration `N = 4`, `M = 2`, this gives `23` cycles per inference. This cycle model should be compared against post-synthesis clock frequency later to compute latency and throughput in physical time.

## Evidence Files Expected Before Final Submission

The grader will not run the repo, so the following markdown pages are the primary submission-facing evidence locations:

- [results/simulation/module_results.md](../results/simulation/module_results.md)
- [results/synthesis/synthesis_summary.md](../results/synthesis/synthesis_summary.md)
- [results/index.md](../results/index.md)

## Remaining Submission Items

- final report screenshots or exported synthesis/timing report snippets, if required by the course submission format
- any optional larger-dimension experiments beyond the verified `N = 4`, `M = 2` reference case
