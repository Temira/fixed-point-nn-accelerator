module compute_core #(
    parameter int DATA_W = 16,
    parameter int MUL_W  = 2 * DATA_W,
    parameter int ACC_W  = MUL_W + 8
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     mac_enable,
    input  logic                     acc_reset,
    input  logic signed [DATA_W-1:0] x_data,
    input  logic signed [DATA_W-1:0] w_data,
    output logic signed [MUL_W-1:0]  mul_out,
    output logic signed [ACC_W-1:0]  acc_out
);

    logic signed [MUL_W-1:0] mul_reg;
    logic signed [ACC_W-1:0] acc_reg;
    logic                    mul_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_reg   <= '0;
            acc_reg   <= '0;
            mul_valid <= 1'b0;
        end else if (acc_reset) begin
            mul_reg   <= '0;
            acc_reg   <= '0;
            mul_valid <= 1'b0;
        end else begin
            if (mul_valid) begin
                acc_reg <= acc_reg + {{(ACC_W-MUL_W){mul_reg[MUL_W-1]}}, mul_reg};
            end

            if (mac_enable) begin
                mul_reg   <= x_data * w_data;
                mul_valid <= 1'b1;
            end else begin
                mul_reg   <= '0;
                mul_valid <= 1'b0;
            end
        end
    end

    assign mul_out = mul_reg;
    assign acc_out = acc_reg;

endmodule
