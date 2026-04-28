module output_buffer #(
    parameter int DATA_W = 16,
    parameter int M      = 8,
    parameter int ADDR_W = (M <= 1) ? 1 : $clog2(M)
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     write_en,
    input  logic [ADDR_W-1:0]        write_addr,
    input  logic signed [DATA_W-1:0] write_data,
    input  logic [ADDR_W-1:0]        read_addr,
    output logic signed [DATA_W-1:0] read_data
);

    logic signed [DATA_W-1:0] mem [0:M-1];
    integer i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < M; i++) begin
                mem[i] <= '0;
            end
        end else if (write_en) begin
            mem[write_addr] <= write_data;
        end
    end

    assign read_data = mem[read_addr];

endmodule
