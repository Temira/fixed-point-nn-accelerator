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
    integer idx;

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

    task automatic write_word(
        input logic [ADDR_W-1:0]        addr,
        input logic signed [DATA_W-1:0] data
    );
        @(negedge clk);
        write_en   = 1'b1;
        write_addr = addr;
        write_data = data;
        @(posedge clk);
    endtask

    task automatic stop_write;
        @(negedge clk);
        write_en   = 1'b0;
        write_addr = '0;
        write_data = '0;
        @(posedge clk);
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

        // Reset should clear all storage locations.
        for (idx = 0; idx < N; idx++) begin
            read_addr = idx[ADDR_W-1:0];
            #1;
            check_equal(read_data, '0, $sformatf("reset clears addr %0d", idx));
        end

        // Write a few values, including a negative sample.
        write_word(0, 16'sd10);
        write_word(1, -16'sd3);
        write_word(7, 16'sd25);
        stop_write();

        // Read them back in non-sequential order.
        #1;
        read_addr = 7; #1; check_equal(read_data, 16'sd25, "read addr 7");
        read_addr = 0; #1; check_equal(read_data, 16'sd10, "read addr 0");
        read_addr = 1; #1; check_equal(read_data, -16'sd3, "read addr 1");

        // Unwritten addresses should still hold reset values.
        read_addr = 2; #1; check_equal(read_data, '0, "unwritten addr remains zero");

        // Overwrite and ensure only the targeted location changes.
        write_word(1, 16'sd99);
        stop_write();

        #1;
        read_addr = 1; #1; check_equal(read_data, 16'sd99, "overwrite addr 1");
        read_addr = 0; #1; check_equal(read_data, 16'sd10, "other addr unaffected by overwrite");

        // A second reset should clear previously written contents.
        rst_n = 0;
        #2;
        read_addr = 0; #1; check_equal(read_data, '0, "second reset clears addr 0");
        read_addr = 1; #1; check_equal(read_data, '0, "second reset clears addr 1");
        rst_n = 1;

        $display("tb_input_buffer PASSED");
        $finish;
    end

endmodule
