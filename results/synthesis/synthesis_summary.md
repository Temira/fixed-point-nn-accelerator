# Synthesis Summary

This page is the submission-facing location for synthesis evidence. The grader will look for explicit latency, throughput, and resource data here.

## Build Context

| Item | Value |
|---|---|
| Tool version | Pending |
| Target device / board | Pending |
| Clock constraint | Pending |
| Top module synthesized | Pending |

## Resource Utilization

| Metric | Value | Notes |
|---|---|---|
| LUTs | Pending | |
| FFs | Pending | |
| DSPs | Pending | |
| BRAM | Pending | |
| URAM | Pending | optional |

## Performance Summary

| Metric | Value | Notes |
|---|---|---|
| Achieved clock period | Pending | |
| Fmax | Pending | |
| Cycles per inference | `N + M * (N + 4) + M + 1` | implemented baseline controller estimate |
| Latency per inference | Pending | compute as `cycles_per_inference * achieved_clock_period` |
| Throughput | Pending | compute as `1 / latency_per_inference` in vectors/sec |

For the currently verified reference case `N = 4`, `M = 2`, the implemented controller implies `23` cycles per inference before synthesis timing is applied.

## Analysis Against Initial Goals

| Goal | Measured result | Met? | Discussion |
|---|---|---|---|
| Correct dense-layer datapath behavior | Pending | Pending | |
| Modular implementation | Pending | Pending | |
| Resource-efficient serial MAC architecture | Pending synthesis numbers | Pending | The RTL uses a single reused MAC datapath with a two-stage pipeline, so the qualitative area/throughput tradeoff is already established; synthesis is still needed for quantitative LUT/FF/DSP/BRAM evidence. |
| Reproducible verification flow | Pending | Pending | |

## Required Final Attachments

- synthesis report screenshot or pasted summary table
- timing summary screenshot or pasted slack/Fmax numbers
- short paragraph interpreting whether the serial architecture met the intended tradeoff
