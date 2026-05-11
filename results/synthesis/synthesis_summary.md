# Synthesis Summary

This page provides synthesis results and performance analysis for the implemented neural network accelerator. It includes latency, throughput, and resource utilization, along with interpretation relative to design goals.

---

## Build Context

| Item | Value |
|---|---|
| Tool version | 2018.3 |
| Target device / board | xc7vx485tffg1157-1 |
| Clock constraint | 10 ns (100 MHz) |
| Top module synthesized | nn_accelerator |

---

## Resource Utilization

| Metric | Value | Notes |
|---|---|---|
| LUTs | 246 | |
| FFs | 361 | |
| DSPs | 1 | Single MAC datapath reused |
| BRAM | 0 | |
| URAM | 0 | optional |

**Interpretation:**  
The use of a single DSP confirms the intended serialized MAC architecture, where one multiply-accumulate unit is reused across all computations. This minimizes hardware usage at the cost of increased latency.

---

## Performance Summary

| Metric | Value | Notes |
|---|---|---|
| Achieved clock period | 7.447 ns | |
| Fmax | 134.3 MHz | |
| Cycles per inference | `N + M * (N + 4) + M + 1` (23 cycles) | derived from controller FSM schedule |
| Latency per inference | 171.3 ns | computed as `cycles × clock period` |
| Throughput | 5.84 M vectors/sec | computed as `1 / latency` |

For the verified reference case:

- \( N = 4 \), \( M = 2 \)
- cycles = 4 + 2*(4 + 4) + 2 + 1 = 23
- latency = 23 × 7.447 ns = 171.3 ns
- throughput = 1 / 171.3 ns ≈ 5.84 M vectors/sec


**Breakdown of cycle formula:**
- `N`: input loading
- `M(N + 4)`: reset, MAC feed, drain, post-process, and writeback work per output neuron
- `M`: output streaming
- `+1`: final completion stage

The controller schedule that drives this cycle model is implemented in [controller_fsm.sv](../../rtl/controller_fsm.sv#L104), and the reused pipelined MAC datapath is implemented in [compute_core.sv](../../rtl/compute_core.sv#L20).

---

## Analysis Against Initial Goals

| Goal | Measured Result | Met? | Discussion |
|---|---|---|---|
| Correct dense-layer datapath behavior | Verified for N=4, M=2 case | Yes | Outputs match Python golden model |
| Modular implementation | Separate RTL modules (MAC, controller, buffers) | Yes | Supports reuse and clean integration |
| Resource-efficient serial MAC architecture | 1 DSP, low LUT/FF count | Yes | Confirms serialized datapath design |
| Reproducible verification flow | SystemVerilog testbench + Python model | Yes | Deterministic and repeatable validation |

---

## Conclusion

The synthesized design meets the intended goal of minimizing hardware usage through a serialized MAC architecture, as evidenced by the use of a single DSP and low overall resource utilization. This design achieves reasonable throughput for small problem sizes while maintaining a simple and modular structure suitable for SoC-style integration. Higher performance targets would require increased parallelism.

---

## Required Final Attachments

- synthesis report screenshot or pasted summary table  
- timing summary screenshot or pasted slack/Fmax numbers  
- short paragraph interpreting whether the serial architecture met the intended tradeoff  
