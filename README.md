# Fixed-Point NN Accelerator

A modular RTL implementation of a fixed-point neural network inference accelerator for a single fully connected layer with ReLU activation, verified in simulation against a Python golden model.

## Project Overview

This project implements a hardware IP block that computes inference for one dense neural-network layer:

`y_i = max(0, sum_{j=0}^{N-1} W[i][j] * x[j] + b[i])`

The design accepts one input vector at a time, performs fixed-point matrix-vector multiplication, adds bias, applies ReLU, and produces an output vector.

The project is designed to emphasize:
- modular RTL design
- clear system interface behavior
- unit and integration testing
- reproducible verification against software reference results

## Goals

The main goals of this project are:

1. Implement a well-defined hardware IP block for dense-layer inference
2. Use signed fixed-point arithmetic throughout the datapath
3. Build the design as modular subcomponents that can be tested independently
4. Verify correctness using a Python golden model and RTL simulation
5. Document the design clearly enough that another user can reproduce the results

## Design Scope

Current scope:
- single fully connected layer
- ReLU activation
- inference only
- simulation-only evaluation
- signed fixed-point arithmetic
- one input vector processed at a time

Out of scope:
- training / backpropagation
- floating-point arithmetic
- multi-layer scheduling
- FPGA deployment
- DMA / host drivers / Linux integration

## Top-Level Interface

Planned top-level signals:

### Inputs
- `clk` : system clock
- `rst` : synchronous reset
- `start` : begins a new inference operation
- `in_valid` : indicates valid input data
- `in_data[DATA_W-1:0]` : streamed input vector element

### Outputs
- `in_ready` : accelerator ready to accept input
- `out_valid` : output data is valid
- `out_data[DATA_W-1:0]` : streamed output vector element
- `busy` : accelerator is processing
- `done` : inference operation complete

## Architecture

The accelerator is decomposed into the following modules:

- **Input Buffer**  
  Stores the input vector and provides indexed access during computation.

- **Weight/Bias Memory**  
  Stores the coefficient matrix and bias vector.

- **MAC Engine**  
  Performs signed fixed-point multiply-accumulate operations for one output neuron at a time.

- **Bias + ReLU Unit**  
  Adds bias and applies ReLU activation.

- **Control FSM**  
  Sequences input loading, computation, and output generation.

- **Output Buffer**  
  Stores completed results and handles output streaming.

The architecture uses a **serial MAC datapath** to reduce implementation complexity and improve testability.

## Arithmetic Format

Planned arithmetic format:
- signed fixed-point
- initial target: `Q8.8` using 16-bit data values
- widened multiplication and accumulation
- output truncation after bias addition and activation

This may be refined during implementation, but the key principle is that internal precision is expanded to reduce overflow risk during accumulation.

## Repository Layout

```text
.
├── README.md
├── initial_plan.md
├── detailed_plan.md
├── docs/
├── rtl/
├── tb/
├── model/
├── results/
└── scripts/
