# IP Interface Definition

## Functional Role

This IP performs inference for a single fully connected neural-network layer using signed fixed-point arithmetic:

`y_i = max(0, sum_j(W[i][j] * x[j]) + b[i])`

The block accepts one input vector `x`, reuses that vector across all output neurons, and emits one output vector `y`.

## Current Verification Interface

The RTL in this repository is currently verified at the module, partial-datapath, controller, compute-core, and top-level integration levels using direct testbench stimulus rather than a wrapped AXI bus implementation.

### Input-side signals

- `clk`, `rst_n`: synchronous module clock and active-low reset
- `write_en`, `write_addr`, `write_data`: load input or output buffer entries
- `read_addr`, `read_data`: indexed datapath access for buffer/memory modules

### Memory-side signals

- `weight_addr`, `weight_data`: indexed access into flattened weight memory
- `bias_addr`, `bias_data`: indexed access into bias memory
- `WEIGHTS_FILE`, `BIASES_FILE`: memory preload file parameters for repeatable tests

### Post-processing signals

- `acc`: accumulated MAC result from the compute stage
- `bias`: per-neuron bias value
- `enabled`: gate for output validity during testing
- `out_data`: ReLU-processed, saturated result

### Compute-core signals

- `mac_enable`: enables the pipelined MAC path
- `acc_reset`: clears the accumulator before a new output neuron
- `x_data`: buffered input activation
- `w_data`: corresponding weight value
- `mul_out`: stage-1 multiplication result
- `acc_out`: accumulated stage-2 result

### Controller / top-level signals

- `start`: begins one accelerator transaction
- `in_valid`, `in_ready`: top-level input handshake used in the current simulation flow
- `out_valid`: top-level output-valid indication during output streaming
- `busy`, `done`: execution status outputs from the controller FSM

## Planned Top-Level PS/IP Interface

The intended deployable top-level IP uses a standard control/data split:

### AXI4-Stream data path

- input stream carries one element of `x` per transfer
- output stream carries one element of `y` per transfer
- `tvalid/tready` handshake defines transfer boundaries

### AXI4-Lite control path

- `start`: begin one inference transaction
- `done`: pulse when one output vector is complete
- `busy`: accelerator is mid-transaction
- optional configuration registers for dimensions, scaling, or memory base selection

## Message Flow Between PS and IP

1. Processor writes configuration and asserts `start`.
2. Processor streams `N` input samples into the accelerator.
3. Input buffer stores the vector for repeated reuse by the compute stage.
4. Compute core walks weights and inputs, producing one accumulator result per output neuron.
5. Post-processing adds bias, applies ReLU, and clamps overflow.
6. Output buffer stores results and streams `M` outputs back to the processor.
7. Accelerator asserts `done` and returns to idle.
