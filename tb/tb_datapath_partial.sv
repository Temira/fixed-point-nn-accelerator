`timescale 1ns/1ps

module tb_datapath_partial;

    localparam int DATA_W = 16;
    localparam int ACC_W  = 32;
    localparam int N      = 4;
    localparam int M      = 2;
    localparam int IN_ADDR_W  = $clog2(N);
    localparam int OUT_ADDR_W = $clog2(M);
    localparam int WEIGHT_ADDR_W = $clog2(M * N);

    logic clk;
    logic rst_n;

    logic in_write_en;
    logic [IN_ADDR_W-1:0] in_write_addr;
    logic signed [DATA_W-1:0] in_write_data;
    logic [IN_ADDR_W-1:0] in_read_addr;
    logic signed [DATA_W-1:0] in_read_data;

    logic [WEIGHT_ADDR_W-1:0] weight_addr;
    logic signed [DATA_W-1:0] weight_data;
    logic [OUT_ADDR_W-1:0] bias_addr;
    logic signed [DATA_W-1:0] bias_data;

    logic signed [ACC_W-1:0] acc;
    logic                     post_en;
    logic signed [DATA_W-1:0] post_data;

    logic out_write_en;
    logic [OUT_ADDR_W-1:0] out_write_addr;
    logic signed [DATA_W-1:0] out_write_data;
    logic [OUT_ADDR_W-1:0] out_read_addr;
    logic signed [DATA_W-1:0] out_read_data;
    logic [WEIGHT_ADDR_W-1:0] weight_addr_next;
    logic signed [DATA_W-1:0] expected [0:M-1];

    integer i;
    integer j;

    input_buffer #(
        .DATA_W(DATA_W),
        .N(N)
    ) u_input_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(in_write_en),
        .write_addr(in_write_addr),
        .write_data(in_write_data),
        .read_addr(in_read_addr),
        .read_data(in_read_data)
    );

    weight_bias_mem #(
        .DATA_W(DATA_W),
        .N(N),
        .M(M),
        .WEIGHTS_FILE("tb/test_vectors/weights.mem"),
        .BIASES_FILE("tb/test_vectors/biases.mem")
    ) u_weight_bias_mem (
        .weight_addr(weight_addr),
        .weight_data(weight_data),
        .bias_addr(bias_addr),
        .bias_data(bias_data)
    );

    post_processing_unit #(
        .ACC_W(ACC_W),
        .DATA_W(DATA_W),
        .OUT_W(DATA_W)
    ) u_post_processing_unit (
        .acc(acc),
        .bias(bias_data),
        .enabled(post_en),
        .out_data(post_data)
    );

    output_buffer #(
        .DATA_W(DATA_W),
        .M(M)
    ) u_output_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(out_write_en),
        .write_addr(out_write_addr),
        .write_data(out_write_data),
        .read_addr(out_read_addr),
        .read_data(out_read_data)
    );

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

    initial begin
        expected[0] = 16'sd21;
        expected[1] = 16'sd0;

        clk = 0;
        rst_n = 0;
        in_write_en = 0;
        in_write_addr = '0;
        in_write_data = '0;
        in_read_addr = '0;
        weight_addr = '0;
        bias_addr = '0;
        acc = '0;
        post_en = 0;
        out_write_en = 0;
        out_write_addr = '0;
        out_write_data = '0;
        out_read_addr = '0;

        #12;
        rst_n = 1;

        // Load input vector x = [3, -2, 1, 4]
        @(posedge clk);
        in_write_en   <= 1;
        in_write_addr <= 0;
        in_write_data <= 16'sd3;

        @(posedge clk);
        in_write_addr <= 1;
        in_write_data <= -16'sd2;

        @(posedge clk);
        in_write_addr <= 2;
        in_write_data <= 16'sd1;

        @(posedge clk);
        in_write_addr <= 3;
        in_write_data <= 16'sd4;

        @(posedge clk);
        in_write_en   <= 0;
        in_write_addr <= '0;
        in_write_data <= '0;

        post_en = 1'b1;

        for (i = 0; i < M; i++) begin
            acc = '0;
            bias_addr = i[OUT_ADDR_W-1:0];
            #1;

            for (j = 0; j < N; j++) begin
                in_read_addr = j[IN_ADDR_W-1:0];
                weight_addr_next = (i * N) + j;
                weight_addr = weight_addr_next;
                #1;
                acc = acc + (in_read_data * weight_data);
            end

            #1;
            check_equal(post_data, expected[i], $sformatf("post-processed output neuron %0d", i));

            @(posedge clk);
            out_write_en   <= 1;
            out_write_addr <= i[OUT_ADDR_W-1:0];
            out_write_data <= post_data;

            @(posedge clk);
            out_write_en <= 0;
        end

        #1;
        out_read_addr = 0; #1; check_equal(out_read_data, expected[0], "buffered output neuron 0");
        out_read_addr = 1; #1; check_equal(out_read_data, expected[1], "buffered output neuron 1");

        $display("tb_datapath_partial PASSED");
        $finish;
    end

endmodule
