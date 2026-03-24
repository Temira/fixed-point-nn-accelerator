# Initial Plan — Fixed-Point NN Accelerator

## 1. IP Definition

### Overview

This project implements a **fixed-point hardware accelerator** for inference through a single fully connected neural network layer with ReLU activation.

The accelerator computes:

`y_i = max(0, sum_{j=0}^{N-1} W[i][j] * x[j] + b[i])`

for an input vector `x`, weight matrix `W`, and bias vector `b`.

---

### Functionality

The IP performs the following steps:

1. Receives an input vector `x` (streamed sequentially)
2. Stores the input internally
3. Computes matrix-vector multiplication
4. Adds bias
5. Applies ReLU activation
6. Outputs the result vector `y`

---

### Data Representation

- Signed fixed-point arithmetic
- Target format: **Q8.8 (16-bit)**
- Internal accumulation uses extended precision
- Final outputs are truncated to target width
- ReLU applied after bias addition

---

### Interface

#### Inputs
- `clk`
- `rst`
- `start`
- `in_valid`
- `in_data [DATA_W-1:0]`

#### Outputs
- `in_ready`
- `out_valid`
- `out_data [DATA_W-1:0]`
- `busy`
- `done`

---

### Scope

- Single fully connected layer
- Fixed dimensions (initial: N=8, M=8)
- Simulation only
- No floating point
- No training/backpropagation

---

## 2. IP Architecture

### High-Level Design

The system is composed of the following modules:

- Input Buffer
- Weight/Bias Memory
- MAC Engine
- Bias + ReLU Unit
- Control FSM
- Output Buffer

---

### Dataflow

1. Load input vector into buffer
2. For each output neuron:
   - Multiply and accumulate
   - Add bias
   - Apply ReLU
3. Store and output results

---

### Architectural Choice

The design uses a **time-multiplexed (serial) MAC engine**.

This choice:
- reduces complexity
- simplifies verification
- enables modular testing
- fits project scope

---

### Modularity Justification

The design is partitioned to support:

- **Independent unit testing**
- **Incremental development**
- **Clear debugging boundaries**
- **Scalability for future extensions**

Each module has a single responsibility, enabling clean verification and integration.

---

### Summary

This project implements a modular, fixed-point neural network inference accelerator designed for correctness, clarity, and reproducibility in simulation.
