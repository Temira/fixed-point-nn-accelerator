#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

mkdir -p results/simulation/logs

make golden | tee results/simulation/logs/golden_model.log
make test-input-buffer | tee results/simulation/logs/tb_input_buffer.log
make test-weight-bias-mem | tee results/simulation/logs/tb_weight_bias_mem.log
make test-post-processing | tee results/simulation/logs/tb_post_processing_unit.log
make test-output-buffer | tee results/simulation/logs/tb_output_buffer.log
make test-datapath-partial | tee results/simulation/logs/tb_datapath_partial.log
make test-compute-core | tee results/simulation/logs/tb_compute_core.log
make test-controller-fsm | tee results/simulation/logs/tb_controller_fsm.log
make test-top-level | tee results/simulation/logs/tb_nn_accelerator.log
