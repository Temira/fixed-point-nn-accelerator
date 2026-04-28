# Verification Plan And Evidence

## Verification Scope

This repository now includes verification for the module-level datapath blocks, the pipelined compute core, the controller FSM, and an integrated top-level accelerator path.

## Automated Test Entry Points

The repository includes a [`Makefile`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/Makefile) so module tests can be run consistently:

- `make golden`
- `make test-input-buffer`
- `make test-weight-bias-mem`
- `make test-compute-core`
- `make test-post-processing`
- `make test-output-buffer`
- `make test-datapath-partial`
- `make test-controller-fsm`
- `make test-top-level`

For a one-shot run of the owned verification flow, use [`scripts/run_all_tests.sh`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/scripts/run_all_tests.sh).

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

[`tb/tb_datapath_partial.sv`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/tb/tb_datapath_partial.sv) provides an integration-oriented check across the modules owned in this split:

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

[`tb/tb_nn_accelerator.sv`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/tb/tb_nn_accelerator.sv) verifies the full implemented accelerator path:

1. assert `start`
2. stream in one input vector through the top-level interface
3. allow the controller FSM to load inputs, sequence the compute core, trigger post-processing, and write the output buffer
4. observe streamed outputs at the top level
5. compare those outputs against the golden-model reference

For the included reference vector set, the top-level RTL output matches the golden-model output `[21, 0]`.

## Evidence Files Expected Before Final Submission

The grader will not run the repo, so the following markdown pages are the primary submission-facing evidence locations:

- [`results/simulation/module_results.md`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/results/simulation/module_results.md)
- [`results/synthesis/synthesis_summary.md`](/Users/temirakoenig/Documents/Codex/2026-04-28/github-plugin-github-openai-curated-help-2/fixed-point-nn-accelerator/results/synthesis/synthesis_summary.md)

## What Still Needs To Be Filled In

- timing and cycle-count analysis summarized from the implemented controller and compute pipeline
- post-synthesis latency, throughput, and resource utilization tables
- brief analysis comparing those measured values against initial design goals
