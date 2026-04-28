PYTHON ?= python3
IVERILOG ?= iverilog
VVP ?= vvp

RTL_DIR := rtl
TB_DIR := tb
BUILD_DIR := build

INPUT_BUFFER_SRCS := $(RTL_DIR)/input_buffer.sv $(TB_DIR)/tb_input_buffer.sv
WEIGHT_BIAS_MEM_SRCS := $(RTL_DIR)/weight_bias_mem.sv $(TB_DIR)/tb_weight_bias_mem.sv
POST_PROCESS_SRCS := $(RTL_DIR)/post_processing_unit.sv $(TB_DIR)/tb_post_processing_unit.sv
OUTPUT_BUFFER_SRCS := $(RTL_DIR)/output_buffer.sv $(TB_DIR)/tb_output_buffer.sv
PARTIAL_DATAPATH_SRCS := $(RTL_DIR)/input_buffer.sv $(RTL_DIR)/weight_bias_mem.sv $(RTL_DIR)/post_processing_unit.sv $(RTL_DIR)/output_buffer.sv $(TB_DIR)/tb_datapath_partial.sv
COMPUTE_CORE_SRCS := $(RTL_DIR)/compute_core.sv $(TB_DIR)/tb_compute_core.sv
CONTROLLER_FSM_SRCS := $(RTL_DIR)/controller_fsm.sv $(TB_DIR)/tb_controller_fsm.sv
TOP_LEVEL_SRCS := $(RTL_DIR)/input_buffer.sv $(RTL_DIR)/weight_bias_mem.sv $(RTL_DIR)/post_processing_unit.sv $(RTL_DIR)/output_buffer.sv $(RTL_DIR)/compute_core.sv $(RTL_DIR)/controller_fsm.sv $(RTL_DIR)/nn_accelerator.sv $(TB_DIR)/tb_nn_accelerator.sv

.PHONY: golden test-input-buffer test-weight-bias-mem test-post-processing test-output-buffer test-datapath-partial test-compute-core test-controller-fsm test-top-level clean

golden:
	$(PYTHON) model/golden_model.py

test-input-buffer:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_input_buffer $(INPUT_BUFFER_SRCS)
	$(VVP) $(BUILD_DIR)/tb_input_buffer

test-weight-bias-mem:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_weight_bias_mem $(WEIGHT_BIAS_MEM_SRCS)
	$(VVP) $(BUILD_DIR)/tb_weight_bias_mem

test-post-processing:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_post_processing_unit $(POST_PROCESS_SRCS)
	$(VVP) $(BUILD_DIR)/tb_post_processing_unit

test-output-buffer:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_output_buffer $(OUTPUT_BUFFER_SRCS)
	$(VVP) $(BUILD_DIR)/tb_output_buffer

test-datapath-partial:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_datapath_partial $(PARTIAL_DATAPATH_SRCS)
	$(VVP) $(BUILD_DIR)/tb_datapath_partial

test-compute-core:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_compute_core $(COMPUTE_CORE_SRCS)
	$(VVP) $(BUILD_DIR)/tb_compute_core

test-controller-fsm:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_controller_fsm $(CONTROLLER_FSM_SRCS)
	$(VVP) $(BUILD_DIR)/tb_controller_fsm

test-top-level:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_nn_accelerator $(TOP_LEVEL_SRCS)
	$(VVP) $(BUILD_DIR)/tb_nn_accelerator

clean:
	rm -rf $(BUILD_DIR)
