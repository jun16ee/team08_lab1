/*
    speed_controller.sv
    This module implements a speed controller that generates update enable signals at increasing intervals.
*/

module speed_controller (
    input  logic i_clk,
    input  logic i_rst_n,
    input  logic i_start,
    input  logic i_tick,
    output logic o_update_en,
    output logic o_finished
);

    // ===== State Definitions =====
    typedef enum logic [1:0] {
        S_IDLE,
        S_RUN,
        S_DONE
    } state_t;

    state_t state_r, state_w;

    // ===== Register and Wire Declarations =====
    logic [15:0] tick_cnt_r, tick_cnt_w;
    logic [15:0] current_threshold_r, current_threshold_w;
    logic [7:0]  update_count_r, update_count_w;
    logic        update_en_w;

    // ===== Parameter Definitions =====
    parameter INITIAL_DELAY = 16'd10;
    parameter DELAY_STEP    = 16'd5;
    parameter MAX_UPDATES   = 8'd30;

    assign o_update_en = update_en_w;
    assign o_finished  = (state_r == S_DONE);

    // ===== Combinational Logic =====
    always_comb begin
        state_w             = state_r;
        tick_cnt_w          = tick_cnt_r;
        current_threshold_w = current_threshold_r;
        update_count_w      = update_count_r;
        update_en_w         = 1'b0;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w             = S_RUN;
                    tick_cnt_w          = 16'd0;
                    current_threshold_w = INITIAL_DELAY;
                    update_count_w      = 8'd0;
                end
            end

            S_RUN: begin
                if (i_tick) begin
                    if (tick_cnt_r >= current_threshold_r) begin
                        update_en_w = 1'b1;
                        tick_cnt_w  = 16'd0;

                        // Increase the delay threshold for the next update
                        current_threshold_w = current_threshold_r + DELAY_STEP;
                        
                        // Increment the update count
                        update_count_w = update_count_r + 1'b1;

                        // Check if we've reached the maximum number of updates
                        if (update_count_w >= MAX_UPDATES) begin
                            state_w = S_DONE;
                        end
                    end else begin
                        tick_cnt_w = tick_cnt_r + 1'b1;
                    end
                end
            end

            S_DONE: begin
                if (i_start) begin
                    state_w             = S_RUN;
                    tick_cnt_w          = 16'd0;
                    current_threshold_w = INITIAL_DELAY;
                    update_count_w      = 8'd0;
                end
            end
        endcase
    end

    // ===== Sequential Logic =====
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r             <= S_IDLE;
            tick_cnt_r          <= 16'd0;
            current_threshold_r <= INITIAL_DELAY;
            update_count_r      <= 8'd0;
        end else begin
            state_r             <= state_w;
            tick_cnt_r          <= tick_cnt_w;
            current_threshold_r <= current_threshold_w;
            update_count_r      <= update_count_w;
        end
    end

endmodule