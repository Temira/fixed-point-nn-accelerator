`timescale 1ns/1ps

module tb_controller_fsm;

    localparam int N = 4;
    localparam int M = 2;
    localparam int IN_ADDR_W     = $clog2(N);
    localparam int OUT_ADDR_W    = $clog2(M);
    localparam int WEIGHT_ADDR_W = $clog2(M * N);
    localparam int BIAS_ADDR_W   = $clog2(M);

    logic clk;
    logic rst_n;
    logic start;
    logic in_valid;
    logic done;
    logic busy;
    logic in_ready;
    logic out_valid;
    logic load_input;
    logic mac_enable;
    logic acc_reset;
    logic post_enable;
    logic write_output;
    logic [IN_ADDR_W-1:0] input_write_addr;
    logic [IN_ADDR_W-1:0] input_read_addr;
    logic [WEIGHT_ADDR_W-1:0] weight_addr;
    logic [BIAS_ADDR_W-1:0] bias_addr;
    logic [OUT_ADDR_W-1:0] output_write_addr;
    logic [OUT_ADDR_W-1:0] output_read_addr;

    integer load_count;
    integer mac_count;
    integer reset_count;
    integer post_count;
    integer write_count;
    integer stream_count;

    controller_fsm #(
        .N(N),
        .M(M),
        .IN_ADDR_W(IN_ADDR_W),
        .OUT_ADDR_W(OUT_ADDR_W),
        .WEIGHT_ADDR_W(WEIGHT_ADDR_W),
        .BIAS_ADDR_W(BIAS_ADDR_W)
    ) dut (
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

    always #5 clk = ~clk;

    task check_equal_int(input integer got, input integer exp, input string msg);
        if (got !== exp) begin
            $display("FAIL: %s | got=%0d exp=%0d", msg, got, exp);
            $finish;
        end else begin
            $display("PASS: %s | got=%0d", msg, got);
        end
    endtask

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_count   <= 0;
            mac_count    <= 0;
            reset_count  <= 0;
            post_count   <= 0;
            write_count  <= 0;
            stream_count <= 0;
        end else begin
            if (load_input)   load_count   <= load_count + 1;
            if (mac_enable)   mac_count    <= mac_count + 1;
            if (acc_reset)    reset_count  <= reset_count + 1;
            if (post_enable)  post_count   <= post_count + 1;
            if (write_output) write_count  <= write_count + 1;
            if (out_valid)    stream_count <= stream_count + 1;
        end
    end

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        in_valid = 1'b0;

        #12;
        rst_n = 1'b1;

        @(negedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        repeat (2) @(posedge clk);
        if (!busy || !in_ready) begin
            $display("FAIL: controller did not enter input-load phase");
            $finish;
        end

        repeat (N) begin
            @(negedge clk);
            in_valid = 1'b1;
            @(posedge clk);
        end

        @(negedge clk);
        in_valid = 1'b0;

        wait(done === 1'b1);
        @(posedge clk);

        check_equal_int(load_count, N, "load_input pulse count");
        check_equal_int(mac_count, M * N, "mac_enable pulse count");
        check_equal_int(reset_count, M, "acc_reset pulse count");
        check_equal_int(post_count, M, "post_enable pulse count");
        check_equal_int(write_count, M, "write_output pulse count");
        check_equal_int(stream_count, M, "out_valid pulse count");

        $display("tb_controller_fsm PASSED");
        $finish;
    end

endmodule
