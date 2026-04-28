module controller_fsm #(
    parameter int N = 8,
    parameter int M = 8,
    parameter int IN_ADDR_W     = (N <= 1) ? 1 : $clog2(N),
    parameter int OUT_ADDR_W    = (M <= 1) ? 1 : $clog2(M),
    parameter int WEIGHT_ADDR_W = (M * N <= 1) ? 1 : $clog2(M * N),
    parameter int BIAS_ADDR_W   = (M <= 1) ? 1 : $clog2(M)
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     start,
    input  logic                     in_valid,
    output logic                     done,
    output logic                     busy,
    output logic                     in_ready,
    output logic                     out_valid,
    output logic                     load_input,
    output logic                     mac_enable,
    output logic                     acc_reset,
    output logic                     post_enable,
    output logic                     write_output,
    output logic [IN_ADDR_W-1:0]     input_write_addr,
    output logic [IN_ADDR_W-1:0]     input_read_addr,
    output logic [WEIGHT_ADDR_W-1:0] weight_addr,
    output logic [BIAS_ADDR_W-1:0]   bias_addr,
    output logic [OUT_ADDR_W-1:0]    output_write_addr,
    output logic [OUT_ADDR_W-1:0]    output_read_addr
);

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_LOAD_INPUT,
        ST_COMPUTE_RESET,
        ST_COMPUTE_FEED,
        ST_COMPUTE_DRAIN,
        ST_POST_PROCESS,
        ST_WRITE_OUTPUT,
        ST_STREAM_OUTPUT,
        ST_DONE
    } state_t;

    state_t state, state_next;

    logic [IN_ADDR_W-1:0]     input_count;
    logic [IN_ADDR_W-1:0]     input_count_next;
    logic [IN_ADDR_W-1:0]     compute_j;
    logic [IN_ADDR_W-1:0]     compute_j_next;
    logic [OUT_ADDR_W-1:0]    output_idx;
    logic [OUT_ADDR_W-1:0]    output_idx_next;
    logic [OUT_ADDR_W-1:0]    stream_idx;
    logic [OUT_ADDR_W-1:0]    stream_idx_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= ST_IDLE;
            input_count <= '0;
            compute_j   <= '0;
            output_idx  <= '0;
            stream_idx  <= '0;
        end else begin
            state       <= state_next;
            input_count <= input_count_next;
            compute_j   <= compute_j_next;
            output_idx  <= output_idx_next;
            stream_idx  <= stream_idx_next;
        end
    end

    always_comb begin
        state_next       = state;
        input_count_next = input_count;
        compute_j_next   = compute_j;
        output_idx_next  = output_idx;
        stream_idx_next  = stream_idx;

        done         = 1'b0;
        busy         = (state != ST_IDLE) && (state != ST_DONE);
        in_ready     = 1'b0;
        out_valid    = 1'b0;
        load_input   = 1'b0;
        mac_enable   = 1'b0;
        acc_reset    = 1'b0;
        post_enable  = 1'b0;
        write_output = 1'b0;

        input_write_addr  = input_count;
        input_read_addr   = compute_j;
        weight_addr       = output_idx * N + compute_j;
        bias_addr         = output_idx;
        output_write_addr = output_idx;
        output_read_addr  = stream_idx;

        case (state)
            ST_IDLE: begin
                if (start) begin
                    input_count_next = '0;
                    compute_j_next   = '0;
                    output_idx_next  = '0;
                    stream_idx_next  = '0;
                    state_next       = ST_LOAD_INPUT;
                end
            end

            ST_LOAD_INPUT: begin
                in_ready   = 1'b1;
                load_input = in_valid;
                if (in_valid) begin
                    if (input_count == N - 1) begin
                        input_count_next = '0;
                        compute_j_next   = '0;
                        output_idx_next  = '0;
                        state_next       = ST_COMPUTE_RESET;
                    end else begin
                        input_count_next = input_count + 1'b1;
                    end
                end
            end

            ST_COMPUTE_RESET: begin
                acc_reset      = 1'b1;
                compute_j_next = '0;
                state_next     = ST_COMPUTE_FEED;
            end

            ST_COMPUTE_FEED: begin
                mac_enable = 1'b1;
                if (compute_j == N - 1) begin
                    compute_j_next = '0;
                    state_next     = ST_COMPUTE_DRAIN;
                end else begin
                    compute_j_next = compute_j + 1'b1;
                end
            end

            ST_COMPUTE_DRAIN: begin
                state_next = ST_POST_PROCESS;
            end

            ST_POST_PROCESS: begin
                post_enable = 1'b1;
                state_next  = ST_WRITE_OUTPUT;
            end

            ST_WRITE_OUTPUT: begin
                write_output = 1'b1;
                if (output_idx == M - 1) begin
                    stream_idx_next = '0;
                    state_next      = ST_STREAM_OUTPUT;
                end else begin
                    output_idx_next = output_idx + 1'b1;
                    state_next      = ST_COMPUTE_RESET;
                end
            end

            ST_STREAM_OUTPUT: begin
                out_valid = 1'b1;
                if (stream_idx == M - 1) begin
                    state_next = ST_DONE;
                end else begin
                    stream_idx_next = stream_idx + 1'b1;
                end
            end

            ST_DONE: begin
                done       = 1'b1;
                state_next = ST_IDLE;
            end

            default: begin
                state_next = ST_IDLE;
            end
        endcase
    end

endmodule
