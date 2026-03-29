# Initial Plan — Fixed-Point NN Accelerator

## Project Team

- Temira Koenig  
- Would ideally like to work on this project on my own. Will discuss with professor. 

---

## 1. IP Definition

### Overview

This project implements a **custom Vitis hardware IP** that accelerates inference for a single fully connected neural network layer using fixed-point arithmetic.

The IP computes:

`y_i = max(0, sum_{j=0}^{N-1} W[i][j] * x[j] + b[i])`

where:
- `x` is the input vector of size `N`
- `W` is a weight matrix of size `M × N`
- `b` is a bias vector of size `M`
- `y` is the output vector of size `M`

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

### Mathematical Operations

For each output element:

1. Multiply input elements by weights  
2. Accumulate partial sums  
3. Add bias  
4. Apply ReLU activation  

Equivalent pseudocode:

```python
for i in range(M):
    acc = 0
    for j in range(N):
        acc += W[i][j] * x[j]
    acc += b[i]
    y[i] = max(0, acc)

## Mathematical Operations

For each output element:

1. Multiply input elements by weights
2. Accumulate partial sums
3. Add bias
4. Apply ReLU activation

Equivalent pseudocode:

```python
for i in range(M):
    acc = 0
    for j in range(N):
        acc += W[i][j] * x[j]
    acc += b[i]
    y[i] = max(0, acc)
```

---

## Why This Is Suitable for Hardware Acceleration

* **High arithmetic intensity**: many multiply-accumulate operations
* **Deterministic computation pattern**: fixed loops over `i` and `j`
* **Data reuse**: input vector reused across multiple outputs
* **Parallelism potential**: MAC operations can be parallelized or pipelined
* **Common workload**: dense layers are fundamental in ML inference

These properties make the computation well-suited for a custom hardware IP, even in a simplified form.

---

# IP Architecture

## High-Level Design

The design is modular and consists of the following components:

* Input Buffer
* Weight/Bias Memory
* MAC Engine
* Bias + ReLU Unit
* Control FSM
* Output Buffer

---

## Module Descriptions

### 1. Input Buffer

* Stores the input vector `x`
* Receives streamed input data
* Provides indexed access during computation

---

### 2. Weight/Bias Memory

* Stores weight matrix `W` and bias vector `b`
* Provides values to the MAC engine during computation
* Can be implemented using internal memory (BRAM-style arrays)

---

### 3. MAC Engine

* Performs multiply-accumulate operations:
  `acc += W[i][j] * x[j]`
* Uses fixed-point arithmetic
* Iterates over input indices for each output neuron

---

### 4. Bias + ReLU Unit

* Adds bias to accumulated result
* Applies activation:
  `y = max(0, acc)`
* Produces final output value

---

### 5. Control FSM

* Controls execution flow
* Handles:

  * input loading
  * nested iteration over `i` and `j`
  * output generation
* Maintains counters and control signals

---

### 6. Output Buffer

* Stores computed output values
* Streams output vector to the host system

---

## Interface with Host (PS)

The IP will be structured as a **Vitis-compatible custom IP** with the following interfaces:

### AXI4-Stream (Data Path)

* Input vector `x` streamed into the accelerator
* Output vector `y` streamed out

### AXI4-Lite (Control)

* Control registers:

  * `start`
  * `done`
  * `busy`
  * optional configuration (dimensions, base addresses)

---

## Dataflow

```
Input Stream → Input Buffer → MAC Engine → Bias + ReLU → Output Buffer → Output Stream
                               ↑
                       Weight/Bias Memory
                               ↑
                         Control FSM
```

---

## Architectural Choice

The design uses a **time-multiplexed (serial) MAC engine**:

* One multiplier and one accumulator
* Iterates over all inputs per output neuron

### Justification

* Reduces hardware complexity
* Easier to implement and debug
* Enables clear modular design
* Fits project time constraints

---

## Modularity and Partitioning

The design is explicitly partitioned into separate modules to:

* Enable **independent unit testing**
* Support **incremental development**
* Allow **clear debugging boundaries**
* Provide a path to future extensions (e.g., parallel MAC units)

This avoids a single monolithic design and aligns with best practices for hardware IP development.

---

## Use of Existing AMD IP

Because this project is implemented as a custom Vitis IP, existing AMD/Xilinx IP blocks may be used where appropriate to simplify system integration. In particular, standard infrastructure IP such as AXI4-Stream interfaces, AXI4-Lite control interfaces, FIFOs, and memory-related support blocks can be leveraged to handle communication and data movement.

However, the core functionality of this project — the fixed-point dense-layer computation including the MAC engine, bias addition, ReLU activation, and control sequencing — will be implemented as custom RTL. This ensures that the key architectural and mathematical components remain fully specified, testable, and aligned with the learning objectives of the project.

---

## Summary

This project defines a modular, fixed-point neural network inference accelerator implemented as a custom Vitis IP. The design focuses on clear structure, well-defined interfaces, and hardware-appropriate computation, making it suitable for both implementation and verification within the project timeline.
