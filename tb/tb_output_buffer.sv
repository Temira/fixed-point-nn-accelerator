`timescale 1ns/1ps

module tb_output_buffer;

    localparam int DATA_W = 16;
    localparam int M      = 4;
    localparam int ADDR_W = $clog2(M);

    logic clk;
    logic rst_n;
    logic write_en;
    logic [ADDR_W-1:0] write_addr;
    logic signed [DATA_W-1:0] write_data;
    logic [ADDR_W-1:0] read_addr;
    logic signed [DATA_W-1:0] read_data;
    integer idx;

    output_buffer #(
        .DATA_W(DATA_W),
        .M(M)
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
        write_addr = '0;
        write_data = '0;
        read_addr = '0;

        #12;
        rst_n = 1;

        for (idx = 0; idx < M; idx++) begin
            read_addr = idx[ADDR_W-1:0];
            #1;
            check_equal(read_data, '0, $sformatf("reset clears addr %0d", idx));
        end

        write_word(0, 16'sd7);
        write_word(1, 16'sd19);
        write_word(3, 16'sd42);
        stop_write();

        #1;
        read_addr = 0; #1; check_equal(read_data, 16'sd7,  "read addr 0");
        read_addr = 1; #1; check_equal(read_data, 16'sd19, "read addr 1");
        read_addr = 3; #1; check_equal(read_data, 16'sd42, "read addr 3");
        read_addr = 2; #1; check_equal(read_data, '0, "unwritten addr remains zero");

        write_word(1, -16'sd5);
        stop_write();

        #1;
        read_addr = 1; #1; check_equal(read_data, -16'sd5, "overwrite addr 1");
        read_addr = 3; #1; check_equal(read_data, 16'sd42, "other addr unaffected by overwrite");

        rst_n = 0;
        #2;
        read_addr = 3; #1; check_equal(read_data, '0, "second reset clears addr 3");
        rst_n = 1;

        $display("tb_output_buffer PASSED");
        $finish;
    end

endmodule
