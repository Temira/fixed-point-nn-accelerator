# Master Context Prompt

```text
You are assisting me with a hardware design project for an NYU course.

Project summary:
I am designing a modular RTL hardware IP block: a fixed-point neural network accelerator for a single fully connected layer with ReLU activation.

Core computation:
y_i = max(0, sum_{j=0}^{N-1} W[i][j] * x[j] + b[i])

Design constraints:
- One fully connected layer only (no multi-layer, no training)
- Fixed-point arithmetic (target: signed Q8.8, 16-bit)
- Simulation-only (no FPGA deployment required)
- Time-multiplexed (serial) MAC architecture, not parallel
- Input and output are streamed one vector at a time
- Dimensions initially small (e.g., N=8, M=8)

Architecture (modular):
- Input Buffer
- Weight/Bias Memory
- MAC Engine (multiply-accumulate)
- Bias + ReLU Unit
- Control FSM
- Output Buffer

Interface (top-level):
Inputs:
- clk, rst, start
- in_valid, in_data

Outputs:
- in_ready
- out_valid, out_data
- busy, done

Project goals:
- Clean modular design
- Well-defined interfaces and signal behavior
- Strong verification (unit tests + integration tests)
- Python golden model for correctness checking
- Reproducible simulation results

Repository structure:
- rtl/ (SystemVerilog modules)
- tb/ (testbenches and vectors)
- model/ (Python golden model)
- docs/ (architecture + specs)
- scripts/ (automation)
- results/ (logs and outputs)

What I want from you:
- Help me design clean, correct RTL modules
- Help define precise interfaces (signals, widths, timing)
- Help write testbenches and verification strategy
- Help debug issues step-by-step
- Help refine architecture decisions without overcomplicating
- Keep solutions scoped and realistic for a 3–4 week project

Important constraints:
- Do not over-engineer (no AXI unless explicitly requested)
- Do not introduce unnecessary features
- Keep everything modular and testable
- Prefer clarity over performance optimization
- Always explain reasoning when making design decisions

When helping me:
- Be precise about signal behavior and timing
- Clearly separate combinational vs sequential logic
- Point out edge cases (overflow, reset, handshakes)
- Suggest unit tests where relevant

You can assume I am comfortable with:
- SystemVerilog basics
- hardware architecture concepts
- but I want structured, step-by-step guidance for implementation

Current task:
[PASTE YOUR CURRENT QUESTION OR TASK HERE]
```

---

### When starting a new chat

Paste the whole thing, then add:

```text
Current task: Help me write the MAC engine module with correct bit widths and overflow handling.
```

---

### When debugging

```text
Current task: My MAC accumulator is overflowing. Here is my code: [paste code]
```

---

### When designing a module

```text
Current task: Define the Control FSM states and transitions cycle-by-cycle.
```

---

### When writing testbenches

```text
Current task: Help me design a unit testbench for the Bias + ReLU module.
```

---

# Short version (quick reset)

```text
I am building a modular fixed-point (Q8.8) neural network accelerator in RTL for a single dense layer:
y_i = max(0, sum W[i][j]*x[j] + b[i])

Architecture:
Input buffer, weight/bias memory, serial MAC, bias+ReLU, FSM, output buffer.

Simulation only. Small size (N=8, M=8). Strong unit + integration testing with Python golden model.

Help me with: [TASK]
```

