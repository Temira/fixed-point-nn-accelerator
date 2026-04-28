`timescale 1ns/1ps

module tb_post_processing_unit;

    localparam int ACC_W  = 32;
    localparam int DATA_W = 16;
    localparam int OUT_W  = 16;

    logic signed [ACC_W-1:0]  acc;
    logic signed [DATA_W-1:0] bias;
    logic                     enabled;
    logic signed [OUT_W-1:0]  out_data;

    post_processing_unit #(
        .ACC_W(ACC_W),
        .DATA_W(DATA_W),
        .OUT_W(OUT_W)
    ) dut (
        .acc(acc),
        .bias(bias),
        .enabled(enabled),
        .out_data(out_data)
    );

    task check_equal(
        input signed [OUT_W-1:0] got,
        input signed [OUT_W-1:0] exp,
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
        acc = '0;
        bias = '0;
        enabled = 1'b0;

        #1;
        check_equal(out_data, 16'sd0, "disabled output forced to zero");

        enabled = 1'b1;

        acc = 32'sd10;
        bias = 16'sd3;
        #1;
        check_equal(out_data, 16'sd13, "positive accumulation plus bias");

        acc = 32'sd10;
        bias = -16'sd4;
        #1;
        check_equal(out_data, 16'sd6, "bias subtraction stays positive");

        acc = -32'sd8;
        bias = 16'sd3;
        #1;
        check_equal(out_data, 16'sd0, "negative result clamps to zero");

        acc = 32'sd40000;
        bias = 16'sd0;
        #1;
        check_equal(out_data, 16'sd32767, "positive overflow saturates");

        acc = 32'sd32760;
        bias = 16'sd7;
        #1;
        check_equal(out_data, 16'sd32767, "boundary case reaches signed max exactly");

        acc = -32'sd1;
        bias = 16'sd1;
        #1;
        check_equal(out_data, 16'sd0, "exact zero passes through relu");

        acc = 32'sd12;
        bias = -16'sd20;
        #1;
        check_equal(out_data, 16'sd0, "bias can drive positive accumulator below zero");

        $display("tb_post_processing_unit PASSED");
        $finish;
    end

endmodule
