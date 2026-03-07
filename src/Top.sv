module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out
);

// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;

// ===== Registers & Wires =====
logic state_r, state_w;
logic clk_en;
logic lfsr_en;
assign lfsr_en = (state_r == S_PROC) && clk_en;

// ===== Sub-Module Instantiation =====
clk_counter u_clk_counter (
	.i_clk   (i_clk),
	.i_rst_n (i_rst_n),
	.o_clk_en(clk_en)
);

lfsr_random_gen u_lfsr_random_gen (
	.i_clk   (i_clk),
	.i_rst_n (i_rst_n),
	.i_en    (lfsr_en),
	.i_seed  (16'd1),
	.o_rand  (o_random_out)
);

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	state_w        = state_r;

	// FSM
	case(state_r)
		S_IDLE: begin
			if (i_start) begin
				state_w = S_PROC;
			end
		end

		S_PROC: begin
			
		end

	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		state_r        <= S_IDLE;
	end
	else begin
		state_r        <= state_w;
	end
end

endmodule

module clk_counter(
	input logic i_clk,
	input logic i_rst_n,
	output logic o_clk_en
);
	reg[17:0] counter;
	
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

module lfsr_random_gen (
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_en,
    input  logic [15:0] i_seed,
    output logic [3:0]  o_rand
);

    // 16-bit LFSR Register
    logic [15:0] lfsr_r, lfsr_w;

    assign o_rand = lfsr_r[3:0]; 

    // ===== Combinational Circuits =====
    always_comb begin
        lfsr_w = lfsr_r;
        
        if (i_en) begin
			// Taps: 16, 14, 13, 11 (x^16 + x^14 + x^13 + x^11 + 1)
            lfsr_w = {lfsr_r[14:0], lfsr_r[15] ^ lfsr_r[13] ^ lfsr_r[12] ^ lfsr_r[10]};
        end
    end

    // ===== Sequential Circuits =====
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
			// If seed is zero, initialize to a non-zero value (e.g., 0xACE1)
            if (i_seed == 16'd0) begin
                lfsr_r <= 16'hACE1;
            end else begin
                lfsr_r <= i_seed;
            end
        end
        else begin
            lfsr_r <= lfsr_w;
        end
    end

endmodule