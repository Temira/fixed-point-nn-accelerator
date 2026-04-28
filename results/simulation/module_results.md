# Simulation Results

This page is the submission-facing location for simulation evidence. The logs below were captured from local `iverilog` and `vvp` runs using the repository `Makefile` targets.

## Module Test Summary

| Testbench | Purpose | Status | Notes |
|---|---|---|---|
| `tb_input_buffer.sv` | input buffer reset/read/write behavior | Passed | verified reset clearing, random-access reads, overwrite behavior, and second-reset clearing |
| `tb_weight_bias_mem.sv` | memory preload and indexed parameter reads | Passed | verified `.mem` preload contents and row-major flattened addressing |
| `tb_post_processing_unit.sv` | bias, ReLU, saturation correctness | Passed | verified positive path, clamp-to-zero, saturation, and boundary cases |
| `tb_output_buffer.sv` | output storage and readback behavior | Passed | verified reset clearing, writes, overwrite behavior, and reset-after-write clearing |
| `tb_datapath_partial.sv` | partial datapath integration owned by this split | Passed | verified input buffering, memory reads, post-processing, output storage, and expected vector output `[21, 0]` |
| `tb_compute_core.sv` | pipelined MAC datapath behavior | Passed | verified accumulator reset, pipeline latency, intermediate accumulation, and final drain behavior |
| `tb_controller_fsm.sv` | controller sequencing and control-signal pulse counts | Passed | verified load, compute, post-process, writeback, and output-stream control activity across one transaction |
| `tb_nn_accelerator.sv` | integrated top-level dense-layer execution | Passed | verified end-to-end streamed outputs `[21, 0]` for the reference vector set |

## Golden Model Reference

For the included datapath-partial vector set:

| Input | Expected output |
|---|---|
| `[3, -2, 1, 4]` | `[21, 0]` |

## Log Excerpts

### tb_input_buffer.sv

```text
PASS: reset clears addr 0 | got=0
PASS: reset clears addr 1 | got=0
PASS: reset clears addr 2 | got=0
PASS: reset clears addr 3 | got=0
PASS: reset clears addr 4 | got=0
PASS: reset clears addr 5 | got=0
PASS: reset clears addr 6 | got=0
PASS: reset clears addr 7 | got=0
PASS: read addr 7 | got=25
PASS: read addr 0 | got=10
PASS: read addr 1 | got=-3
PASS: unwritten addr remains zero | got=0
PASS: overwrite addr 1 | got=99
PASS: other addr unaffected by overwrite | got=10
PASS: second reset clears addr 0 | got=0
PASS: second reset clears addr 1 | got=0
tb_input_buffer PASSED
```

### tb_weight_bias_mem.sv

```text
PASS: weight[0] | got=2
PASS: weight[1] | got=-1
PASS: weight[2] | got=0
PASS: weight[4] | got=-3
PASS: weight[7] | got=1
PASS: bias[0] | got=1
PASS: bias[1] | got=-2
PASS: row-major flattening check | got=4
tb_weight_bias_mem PASSED
```

### tb_post_processing_unit.sv

```text
PASS: disabled output forced to zero | got=0
PASS: positive accumulation plus bias | got=13
PASS: bias subtraction stays positive | got=6
PASS: negative result clamps to zero | got=0
PASS: positive overflow saturates | got=32767
PASS: boundary case reaches signed max exactly | got=32767
PASS: exact zero passes through relu | got=0
PASS: bias can drive positive accumulator below zero | got=0
tb_post_processing_unit PASSED
```

### tb_output_buffer.sv

```text
PASS: reset clears addr 0 | got=0
PASS: reset clears addr 1 | got=0
PASS: reset clears addr 2 | got=0
PASS: reset clears addr 3 | got=0
PASS: read addr 0 | got=7
PASS: read addr 1 | got=19
PASS: read addr 3 | got=42
PASS: unwritten addr remains zero | got=0
PASS: overwrite addr 1 | got=-5
PASS: other addr unaffected by overwrite | got=42
PASS: second reset clears addr 3 | got=0
tb_output_buffer PASSED
```

### tb_datapath_partial.sv

```text
PASS: post-processed output neuron 0 | got=21
PASS: post-processed output neuron 1 | got=0
PASS: buffered output neuron 0 | got=21
PASS: buffered output neuron 1 | got=0
tb_datapath_partial PASSED
```

### tb_compute_core.sv

```text
PASS: accumulator reset | got=0
PASS: pipeline has not accumulated after first multiply | got=0
PASS: accumulator includes first product | got=6
PASS: accumulator includes second product | got=-2
PASS: drain cycle adds final product | got=-7
tb_compute_core PASSED
```

### tb_controller_fsm.sv

```text
PASS: load_input pulse count | got=4
PASS: mac_enable pulse count | got=8
PASS: acc_reset pulse count | got=2
PASS: post_enable pulse count | got=2
PASS: write_output pulse count | got=2
PASS: out_valid pulse count | got=2
tb_controller_fsm PASSED
```

### tb_nn_accelerator.sv

```text
PASS: top-level output 0 | got=21
PASS: top-level output 1 | got=0
PASS: streamed output count | got=2
tb_nn_accelerator PASSED
```

## Notes

- `iverilog` emitted `sorry: constant selects in always_* processes are not fully supported` warnings for `post_processing_unit.sv`.
- These warnings did not cause functional failures; `tb_post_processing_unit.sv`, `tb_datapath_partial.sv`, and `tb_nn_accelerator.sv` all completed successfully with the expected outputs.
