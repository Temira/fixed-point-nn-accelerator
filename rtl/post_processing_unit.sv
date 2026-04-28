module post_processing_unit #(
    parameter int ACC_W  = 32,
    parameter int DATA_W = 16,
    parameter int OUT_W  = DATA_W
)(
    input  logic signed [ACC_W-1:0]  acc,
    input  logic signed [DATA_W-1:0] bias,
    input  logic                     enabled,
    output logic signed [OUT_W-1:0]  out_data
);

    localparam int SUM_W = ACC_W + 1;

    logic signed [SUM_W-1:0] bias_ext;
    logic signed [SUM_W-1:0] total;
    logic signed [SUM_W-1:0] relu_val;
    logic signed [SUM_W-1:0] max_pos;

    always_comb begin
        bias_ext = {{(SUM_W-DATA_W){bias[DATA_W-1]}}, bias};
        total    = {{1{acc[ACC_W-1]}}, acc} + bias_ext;
        relu_val = (total < 0) ? '0 : total;
        max_pos  = {{(SUM_W-OUT_W){1'b0}}, 1'b0, {(OUT_W-1){1'b1}}};

        if (!enabled) begin
            out_data = '0;
        end else if (relu_val > max_pos) begin
            out_data = {1'b0, {(OUT_W-1){1'b1}}};
        end else begin
            out_data = relu_val[OUT_W-1:0];
        end
    end

endmodule
