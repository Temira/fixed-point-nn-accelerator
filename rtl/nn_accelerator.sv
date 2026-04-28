module nn_accelerator #(
    parameter int DATA_W = 16,
    parameter int N      = 8,
    parameter int M      = 8,
    parameter int MUL_W  = 2 * DATA_W,
    parameter int ACC_W  = MUL_W + 8,
    parameter int IN_ADDR_W       = (N <= 1) ? 1 : $clog2(N),
    parameter int OUT_ADDR_W      = (M <= 1) ? 1 : $clog2(M),
    parameter int WEIGHT_ADDR_W   = (M * N <= 1) ? 1 : $clog2(M * N),
    parameter int BIAS_ADDR_W     = (M <= 1) ? 1 : $clog2(M)
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     start,
    input  logic                     in_valid,
    input  logic signed [DATA_W-1:0] in_data,
    output logic                     in_ready,
    output logic                     out_valid,
    output logic signed [DATA_W-1:0] out_data,
    output logic                     busy,
    output logic                     done
);

    logic                     load_input;
    logic                     mac_enable;
    logic                     acc_reset;
    logic                     post_enable;
    logic                     write_output;

    logic [IN_ADDR_W-1:0]     input_write_addr;
    logic [IN_ADDR_W-1:0]     input_read_addr;
    logic [WEIGHT_ADDR_W-1:0] weight_addr;
    logic [BIAS_ADDR_W-1:0]   bias_addr;
    logic [OUT_ADDR_W-1:0]    output_write_addr;
    logic [OUT_ADDR_W-1:0]    output_read_addr;

    logic signed [DATA_W-1:0] input_read_data;
    logic signed [DATA_W-1:0] weight_data;
    logic signed [DATA_W-1:0] bias_data;
    logic signed [MUL_W-1:0]  mul_out;
    logic signed [ACC_W-1:0]  acc_out;
    logic signed [DATA_W-1:0] post_data;
    logic signed [DATA_W-1:0] post_data_reg;

    controller_fsm #(
        .N(N),
        .M(M),
        .IN_ADDR_W(IN_ADDR_W),
        .OUT_ADDR_W(OUT_ADDR_W),
        .WEIGHT_ADDR_W(WEIGHT_ADDR_W),
        .BIAS_ADDR_W(BIAS_ADDR_W)
    ) u_controller_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .in_valid(in_valid),
        .done(done),
        .busy(busy),
        .in_ready(in_ready),
        .out_valid(out_valid),
        .load_input(load_input),
        .mac_enable(mac_enable),
        .acc_reset(acc_reset),
        .post_enable(post_enable),
        .write_output(write_output),
        .input_write_addr(input_write_addr),
        .input_read_addr(input_read_addr),
        .weight_addr(weight_addr),
        .bias_addr(bias_addr),
        .output_write_addr(output_write_addr),
        .output_read_addr(output_read_addr)
    );

    input_buffer #(
        .DATA_W(DATA_W),
        .N(N),
        .ADDR_W(IN_ADDR_W)
    ) u_input_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(load_input),
        .write_addr(input_write_addr),
        .write_data(in_data),
        .read_addr(input_read_addr),
        .read_data(input_read_data)
    );

    weight_bias_mem #(
        .DATA_W(DATA_W),
        .N(N),
        .M(M),
        .WEIGHT_ADDR_W(WEIGHT_ADDR_W),
        .BIAS_ADDR_W(BIAS_ADDR_W)
    ) u_weight_bias_mem (
        .weight_addr(weight_addr),
        .weight_data(weight_data),
        .bias_addr(bias_addr),
        .bias_data(bias_data)
    );

    compute_core #(
        .DATA_W(DATA_W),
        .MUL_W(MUL_W),
        .ACC_W(ACC_W)
    ) u_compute_core (
        .clk(clk),
        .rst_n(rst_n),
        .mac_enable(mac_enable),
        .acc_reset(acc_reset),
        .x_data(input_read_data),
        .w_data(weight_data),
        .mul_out(mul_out),
        .acc_out(acc_out)
    );

    post_processing_unit #(
        .ACC_W(ACC_W),
        .DATA_W(DATA_W),
        .OUT_W(DATA_W)
    ) u_post_processing_unit (
        .acc(acc_out),
        .bias(bias_data),
        .enabled(post_enable),
        .out_data(post_data)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            post_data_reg <= '0;
        end else if (post_enable) begin
            post_data_reg <= post_data;
        end
    end

    output_buffer #(
        .DATA_W(DATA_W),
        .M(M),
        .ADDR_W(OUT_ADDR_W)
    ) u_output_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_output),
        .write_addr(output_write_addr),
        .write_data(post_data_reg),
        .read_addr(output_read_addr),
        .read_data(out_data)
    );

endmodule
