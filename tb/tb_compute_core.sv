`timescale 1ns/1ps

module tb_compute_core;

    localparam int DATA_W = 16;
    localparam int MUL_W  = 32;
    localparam int ACC_W  = 40;

    logic clk;
    logic rst_n;
    logic mac_enable;
    logic acc_reset;
    logic signed [DATA_W-1:0] x_data;
    logic signed [DATA_W-1:0] w_data;
    logic signed [MUL_W-1:0]  mul_out;
    logic signed [ACC_W-1:0]  acc_out;

    compute_core #(
        .DATA_W(DATA_W),
        .MUL_W(MUL_W),
        .ACC_W(ACC_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .mac_enable(mac_enable),
        .acc_reset(acc_reset),
        .x_data(x_data),
        .w_data(w_data),
        .mul_out(mul_out),
        .acc_out(acc_out)
    );

    always #5 clk = ~clk;

    task check_equal(
        input signed [ACC_W-1:0] got,
        input signed [ACC_W-1:0] exp,
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
        clk = 1'b0;
        rst_n = 1'b0;
        mac_enable = 1'b0;
        acc_reset = 1'b0;
        x_data = '0;
        w_data = '0;

        #12;
        rst_n = 1'b1;

        @(negedge clk);
        acc_reset = 1'b1;
        @(posedge clk);
        acc_reset = 1'b0;
        check_equal(acc_out, '0, "accumulator reset");

        @(negedge clk);
        mac_enable = 1'b1;
        x_data = 16'sd3;
        w_data = 16'sd2;
        @(posedge clk);

        @(negedge clk);
        x_data = -16'sd2;
        w_data = 16'sd4;
        @(posedge clk);
        check_equal(acc_out, '0, "pipeline has not accumulated after first multiply");

        @(negedge clk);
        x_data = 16'sd1;
        w_data = -16'sd5;
        @(posedge clk);
        check_equal(acc_out, 40'sd6, "accumulator includes first product");

        @(negedge clk);
        mac_enable = 1'b0;
        x_data = '0;
        w_data = '0;
        @(posedge clk);
        check_equal(acc_out, -40'sd2, "accumulator includes second product");

        @(negedge clk);
        @(posedge clk);
        check_equal(acc_out, -40'sd7, "drain cycle adds final product");

        $display("tb_compute_core PASSED");
        $finish;
    end

endmodule
