`timescale 1ns/1ps

module tb_nn_accelerator;

    localparam int DATA_W = 16;
    localparam int N      = 4;
    localparam int M      = 2;

    logic clk;
    logic rst_n;
    logic start;
    logic in_valid;
    logic signed [DATA_W-1:0] in_data;
    logic in_ready;
    logic out_valid;
    logic signed [DATA_W-1:0] out_data;
    logic busy;
    logic done;

    logic signed [DATA_W-1:0] captured [0:M-1];
    integer out_count;

    nn_accelerator #(
        .DATA_W(DATA_W),
        .N(N),
        .M(M)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .in_valid(in_valid),
        .in_data(in_data),
        .in_ready(in_ready),
        .out_valid(out_valid),
        .out_data(out_data),
        .busy(busy),
        .done(done)
    );

    defparam dut.u_weight_bias_mem.WEIGHTS_FILE = "tb/test_vectors/weights.mem";
    defparam dut.u_weight_bias_mem.BIASES_FILE  = "tb/test_vectors/biases.mem";

    always #5 clk = ~clk;

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

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_count <= 0;
        end else if (out_valid) begin
            captured[out_count] <= out_data;
            out_count <= out_count + 1;
        end
    end

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        in_valid = 1'b0;
        in_data = '0;
        out_count = 0;

        #12;
        rst_n = 1'b1;

        @(negedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait(in_ready === 1'b1);

        @(negedge clk);
        in_valid = 1'b1; in_data = 16'sd3;
        @(posedge clk);
        @(negedge clk);
        in_data = -16'sd2;
        @(posedge clk);
        @(negedge clk);
        in_data = 16'sd1;
        @(posedge clk);
        @(negedge clk);
        in_data = 16'sd4;
        @(posedge clk);
        @(negedge clk);
        in_valid = 1'b0; in_data = '0;

        wait(done === 1'b1);
        @(posedge clk);

        check_equal(captured[0], 16'sd21, "top-level output 0");
        check_equal(captured[1], 16'sd0,  "top-level output 1");

        if (out_count !== M) begin
            $display("FAIL: expected %0d streamed outputs, got %0d", M, out_count);
            $finish;
        end else begin
            $display("PASS: streamed output count | got=%0d", out_count);
        end

        $display("tb_nn_accelerator PASSED");
        $finish;
    end

endmodule
