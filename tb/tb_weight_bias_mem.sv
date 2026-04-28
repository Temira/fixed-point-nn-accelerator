`timescale 1ns/1ps

module tb_weight_bias_mem;

    localparam int DATA_W = 16;
    localparam int N      = 4;
    localparam int M      = 2;
    localparam int WEIGHT_ADDR_W = $clog2(M * N);
    localparam int BIAS_ADDR_W   = $clog2(M);

    logic [WEIGHT_ADDR_W-1:0] weight_addr;
    logic signed [DATA_W-1:0] weight_data;
    logic [BIAS_ADDR_W-1:0]   bias_addr;
    logic signed [DATA_W-1:0] bias_data;

    weight_bias_mem #(
        .DATA_W(DATA_W),
        .N(N),
        .M(M),
        .WEIGHTS_FILE("tb/test_vectors/weights.mem"),
        .BIASES_FILE("tb/test_vectors/biases.mem")
    ) dut (
        .weight_addr(weight_addr),
        .weight_data(weight_data),
        .bias_addr(bias_addr),
        .bias_data(bias_data)
    );

    task check_equal(
        input signed [DATA_W-1:0] got,
        input signed [DATA_W-1:0] exp,
        input string             msg
    );
        if (got !== exp) begin
            $display("FAIL: %s | got=%0d exp=%0d", msg, got, exp);
            $finish;
        end else begin
            $display("PASS: %s | got=%0d", msg, got);
        end
    endtask

    initial begin
        weight_addr = '0;
        bias_addr   = '0;

        #1;

        weight_addr = 0; #1; check_equal(weight_data, 16'sd2,  "weight[0]");
        weight_addr = 1; #1; check_equal(weight_data, -16'sd1, "weight[1]");
        weight_addr = 2; #1; check_equal(weight_data, 16'sd0,  "weight[2]");
        weight_addr = 4; #1; check_equal(weight_data, -16'sd3, "weight[4]");
        weight_addr = 7; #1; check_equal(weight_data, 16'sd1,  "weight[7]");

        bias_addr = 0; #1; check_equal(bias_data, 16'sd1,  "bias[0]");
        bias_addr = 1; #1; check_equal(bias_data, -16'sd2, "bias[1]");

        // Verify flattened row-major layout:
        // row 1, col 2 for a 2x4 matrix maps to linear address 6.
        weight_addr = 6; #1; check_equal(weight_data, 16'sd4, "row-major flattening check");

        $display("tb_weight_bias_mem PASSED");
        $finish;
    end

endmodule
