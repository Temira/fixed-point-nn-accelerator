`timescale 1ns/1ps

module tb_input_buffer;

    localparam int DATA_W = 16;
    localparam int N      = 8;
    localparam int ADDR_W = $clog2(N);

    logic clk;
    logic rst_n;
    logic write_en;
    logic [ADDR_W-1:0] write_addr;
    logic signed [DATA_W-1:0] write_data;
    logic [ADDR_W-1:0] read_addr;
    logic signed [DATA_W-1:0] read_data;

    input_buffer #(
        .DATA_W(DATA_W),
        .N(N)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr(read_addr),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    task check_equal(input signed [DATA_W-1:0] got, input signed [DATA_W-1:0] exp, input string msg);
        if (got !== exp) begin
            $display("FAIL: %s | got=%0d exp=%0d", msg, got, exp);
            $finish;
        end
        else begin
            $display("PASS: %s | got=%0d", msg, got);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        write_en = 0;
        write_addr = 0;
        write_data = 0;
        read_addr = 0;

        #12;
        rst_n = 1;

        // Write a few values
        @(posedge clk);
        write_en   <= 1;
        write_addr <= 0;
        write_data <= 16'sd10;

        @(posedge clk);
        write_addr <= 1;
        write_data <= -16'sd3;

        @(posedge clk);
        write_addr <= 7;
        write_data <= 16'sd25;

        @(posedge clk);
        write_en <= 0;

        // Read them back
        #1;
        read_addr = 0; #1; check_equal(read_data, 16'sd10, "read addr 0");
        read_addr = 1; #1; check_equal(read_data, -16'sd3, "read addr 1");
        read_addr = 7; #1; check_equal(read_data, 16'sd25, "read addr 7");

        // Overwrite
        @(posedge clk);
        write_en   <= 1;
        write_addr <= 1;
        write_data <= 16'sd99;

        @(posedge clk);
        write_en <= 0;

        #1;
        read_addr = 1; #1; check_equal(read_data, 16'sd99, "overwrite addr 1");

        $display("tb_input_buffer PASSED");
        $finish;
    end

endmodule
