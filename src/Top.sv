module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
    input        i_show,
	output [3:0] o_random_out
);

// ===== Wires =====
logic tick_en;
logic update_en;
logic [15:0] time_seed;
logic done, show;
logic [3:0] random_out_now;

// ===== Sub-Module Instantiation =====
clk_counter u_clk_counter (
    .i_clk       (i_clk),
    .i_rst_n     (i_rst_n),
    .o_clk_en    (tick_en),
    .o_time_seed (time_seed)
);

speed_controller u_speed_controller (
    .i_clk       (i_clk),
    .i_rst_n     (i_rst_n),
    .i_start     (i_start),
    .i_show      (i_show),
    .i_tick      (tick_en),
    .o_update_en (update_en),
    .o_finished  (done),
    .o_show      (show)
);

lfsr_random_gen u_lfsr_random_gen (
    .i_clk   (i_clk),
    .i_rst_n (i_rst_n),
    .i_en    (update_en),
    .i_load  (i_start),
    .i_seed  (time_seed),
    .o_rand  (random_out_now)
);

assign o_random_out = show?old_num:random_out_now;

// assign old_num = 4'b1010;
logic [3:0] old_num, cur_num;
logic done_r;
always_ff @(posedge i_clk) begin
    if (!i_rst_n) begin
        old_num <= 18'd0;
        cur_num <= 18'd0;
        done_r <= 1'b0;
    end else begin
        done_r <= done;
        if (~done_r & done) begin //rising edge
            cur_num <= random_out_now;
            old_num <= cur_num;
        end
    end
end

endmodule

module clk_counter(
	input logic i_clk,
	input logic i_rst_n,
	output logic o_clk_en,
	output logic [15:0] o_time_seed
);
	reg [17:0] counter;
	assign o_time_seed = counter[15:0];
	
	always_ff @(posedge i_clk or negedge i_rst_n) begin
		// reset
		if (!i_rst_n) begin
			counter <= 18'd0;
			o_clk_en <= 1'b0;
		end
		else begin
			if (counter == 18'd99999) begin
				o_clk_en <= 1'b1;
				counter <= 18'd0;
			end else begin
				o_clk_en <= 1'b0;
				counter <= counter + 1'b1;
			end
		end
	end

endmodule

// module lfsr_random_gen (
//     input  logic        i_clk,
//     input  logic        i_rst_n,
//     input  logic        i_en,
//     input  logic        i_load,
//     input  logic [15:0] i_seed,
//     output logic [3:0]  o_rand
// );

//     // 16-bit LFSR Register
//     logic [15:0] lfsr_r, lfsr_w;

//     assign o_rand = lfsr_r[3:0]; 

//     // ===== Combinational Circuits =====
//     always_comb begin
//         lfsr_w = lfsr_r;
        
//         if (i_load) begin
// 			// If seed is zero, use a default non-zero value to avoid getting stuck in the zero state
//             lfsr_w = (i_seed == 16'd0) ? 16'hACE0 : i_seed;
//         end
//         else if (i_en) begin
//             // Taps: 16, 14, 13, 11 (x^16 + x^14 + x^13 + x^11 + 1)
//             lfsr_w = {lfsr_r[14:0], lfsr_r[15] ^ lfsr_r[13] ^ lfsr_r[12] ^ lfsr_r[10]};
//         end
//     end

//     // ===== Sequential Circuits =====
//     always_ff @(posedge i_clk or negedge i_rst_n) begin
//         if (!i_rst_n) begin
//             lfsr_r <= 16'hACE0;
//         end
//         else begin
//             if (i_en) begin
//                 lfsr_r <= lfsr_w;
//             end
//         end
//     end

// endmodule

module lfsr_random_gen (
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_en,
    input  logic        i_load,
    input  logic [3:0]  i_seed,
    output logic [3:0]  o_rand
);

    // 4-bit LFSR Register
    logic [3:0] lfsr_r, lfsr_w;
    logic       feedback;

    assign o_rand = lfsr_r; 

    // ===== Combinational Circuits =====
    always_comb begin
        lfsr_w = lfsr_r;
        
        // 1. 標準 Fibonacci 反饋邏輯 (x^4 + x^3 + 1)
        // 這裡採用 XOR 邏輯
        feedback = lfsr_r[3] ^ lfsr_r[2];

        if (i_load) begin
            lfsr_w = i_seed;
        end
        else if (i_en) begin
            /* 為了達到 16 個狀態 (0~15)：
               當目前的狀態為 4'b1000 時，下一步原本會進入 4'b0000 (原本被禁止的狀態)。
               當目前的狀態為 4'b0000 時，下一步強制進入 4'b0001 (回到正常循環)。
            */
            if (lfsr_r == 4'b0000) begin
                lfsr_w = 4'b0001; // 從全零狀態跳回循環
            end
            else if (lfsr_r == 4'b1000) begin
                lfsr_w = 4'b0000; // 強制進入全零狀態
            end
            else begin
                lfsr_w = {lfsr_r[2:0], feedback}; // 標準位移
            end
        end
    end

    // ===== Sequential Circuits =====
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            lfsr_r <= 4'h1; // 初始值設定
        end
        else begin
            // 只有在啟動或載入時才更新
            if (i_load || i_en) begin
                lfsr_r <= lfsr_w;
            end
        end
    end

endmodule