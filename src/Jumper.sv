/*
    Jumper is basically a counter that counts from 0 to 127. 
    When i_start is asserted, it will set the state to S_PROC and start incrementing the counter. 
    When the state is S_PROC, it will increment the counter by 1 at each clock cycle.
    When the counter reaches 127, it will reset to 0 at the next clock cycle and set the state to S_IDLE.
*/

module Jumper #(
    parameter WIDTH = 7
)(
	input               i_clk,
	input               i_rst_n,
	input               i_start,
	output [WIDTH-1:0]  o_jumper_out,
    output              o_state
);

localparam MAX_VAL = (1 << WIDTH) - 1;

// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;

// ===== Output Buffers =====
logic [WIDTH-1:0] o_jumper_out_r, o_jumper_out_w;

// ===== Registers & Wires =====
logic state_r, state_w;

// ===== Output Assignments =====
assign o_jumper_out = o_jumper_out_r;
assign o_state = state_r;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	o_jumper_out_w = o_jumper_out_r;
	state_w        = state_r;

	// FSM
	case(state_r)
	S_IDLE: begin
		if (i_start) begin
			state_w = S_PROC;
			o_jumper_out_w = '0;
		end
	end

	S_PROC: begin
		state_w = (o_jumper_out_r == WIDTH'(MAX_VAL)) ? S_IDLE : state_w;
		o_jumper_out_w = (o_jumper_out_r == WIDTH'(MAX_VAL)) ? '0 : (o_jumper_out_r + 1);
	end

	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		o_jumper_out_r <= '0;
		state_r        <= S_IDLE;
	end
	else begin
		o_jumper_out_r <= o_jumper_out_w;
		state_r        <= state_w;
	end
end

endmodule
