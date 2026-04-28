module weight_bias_mem #(
    parameter int DATA_W   = 16,
    parameter int N        = 8,
    parameter int M        = 8,
    parameter string WEIGHTS_FILE = "",
    parameter string BIASES_FILE  = "",
    parameter int WEIGHT_ADDR_W   = (M * N <= 1) ? 1 : $clog2(M * N),
    parameter int BIAS_ADDR_W     = (M <= 1) ? 1 : $clog2(M)
)(
    input  logic [WEIGHT_ADDR_W-1:0]        weight_addr,
    output logic signed [DATA_W-1:0]        weight_data,
    input  logic [BIAS_ADDR_W-1:0]          bias_addr,
    output logic signed [DATA_W-1:0]        bias_data
);

    logic signed [DATA_W-1:0] weights [0:(M*N)-1];
    logic signed [DATA_W-1:0] biases  [0:M-1];
    integer i;

    initial begin
        for (i = 0; i < M * N; i++) begin
            weights[i] = '0;
        end
        for (i = 0; i < M; i++) begin
            biases[i] = '0;
        end

        if (WEIGHTS_FILE != "") begin
            $readmemh(WEIGHTS_FILE, weights);
        end
        if (BIASES_FILE != "") begin
            $readmemh(BIASES_FILE, biases);
        end
    end

    assign weight_data = weights[weight_addr];
    assign bias_data   = biases[bias_addr];

endmodule
