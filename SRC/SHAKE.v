`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/15 16:22:41
// Design Name: 
// Module Name: SHAKE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
// Yes;
module SHAKE(
	input clk,
	input rstn,
	
	input model_sel,	// SHAKE 128 or 256;
	
	// msg;
	input [63:0] msg,	
	input msg_val,
	input lastmsg_val,
	
	// indexa;
	input [7:0] indexa,
	input indexa_val,
	
	// indexb;
	input [7:0] indexb,
	input indexb_val,
	
	// padflag;
	input [2:0] padflag,
	
	// cnt;
	input [8:0]	sqzcnt,
	
	// onehash_val,
	output onehash_val,	// one hash is over;
	
	// sqzout64;
	input sqzout64_en,
	output [63:0] sqzout64,
	output sqzout64_val,
	
	// sqzout448;
	input sqzout448_en,
	output [447:0] sqzout448,
	output sqzout448_val,
	
	// done;
	output reg done
    );
	
	//// Intermediate;
	// FSM;
	reg	[2:0] CS;
	reg [2:0] NS;
	
	localparam PROCESS = 0;
	localparam PADDING = 1;
	localparam ABSORB  = 2;
	localparam SQUEEZ  = 3;
	localparam CLEAR   = 4;
	
	// Control Signal;
	reg [8:0] sqzcurcnt;
	reg firstmsg_val;
	
	wire [63:0] msgn;
	wire msgn_val;
	wire lastmsgn_val;
	
	reg [1343:0] S;
	reg [7:0]S_len;
	reg S_shift_en;
	
	reg [7:0] zerotoadd;
	reg [7:0] padding_cnt;
	
	wire [1343:0] keccakIn;
	reg keccakIn_val;
	
	wire [1343:0] keccakOut;
	wire keccakOut_val;
	
	// CS;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			CS <= PROCESS;
		else
			CS <= NS;
	end
	
	// NS;
	always @(*) begin
		case(CS)
			PROCESS: begin
				if(lastmsgn_val)
					NS <= PADDING;
				else if(model_sel == 0 && msg_val && S_len == 160)
					NS <= ABSORB;
				else if(model_sel == 1 && msg_val && S_len == 128)
					NS <= ABSORB;
				else
					NS <= PROCESS;
			end
			PADDING: begin
				if(padding_cnt == zerotoadd - 8)
					NS <= SQUEEZ;
				else
					NS <= PADDING;
			end
			ABSORB: begin
				if(keccakOut_val)
					NS <= PROCESS;
				else
					NS <= ABSORB;
			end
			SQUEEZ: begin
				if(sqzcurcnt == sqzcnt && S_len == 0) begin
					NS <= CLEAR;
				end else begin
					NS <= SQUEEZ;
				end
			end
			CLEAR: begin
				NS <= PROCESS;
			end
		endcase
	end
	
	// S, S_len, keccakIn_val, firstmsg_val, zerotoadd, padding_cnt, sqzcurcnt, done;
	always @(posedge clk or negedge rstn) begin
		if(~rstn) begin
			S <= 1344'b0;
			S_len <= 8'b0;
			S_shift_en <= 1'b0;
			keccakIn_val <= 1'b0;
			firstmsg_val <= 1'b1;
			zerotoadd <= 8'b0;
			padding_cnt <= 8'b0;
			sqzcurcnt <= 9'b0;
			done <= 1'b0;
		end else begin
			case(CS)
				PROCESS: begin
					if(msgn_val) begin
						S <= (S << 64) | msgn;
						S_len <= S_len + 8;
					end
					// keccakIn_val;
					case(model_sel)
						1'b0: keccakIn_val <= (S_len == 160 && msg_val) ? 1'b1 : 1'b0;
						1'b1: keccakIn_val <= (S_len == 128 && msg_val) ? 1'b1 : 1'b0;
					endcase
					// zerotoadd;
					case(model_sel)
						1'b0: zerotoadd <= 160 - S_len;
						1'b1: zerotoadd <= 128 - S_len;
					endcase
					// padding_cnt;
					padding_cnt <= 8'b0;
					// done;
					done <= 1'b0;
				end
				PADDING: begin
					// S, S_len, padding_cnt;
					if(zerotoadd - padding_cnt > 8) begin
						S <= S << 64;
						S_len <= S_len + 8;
						padding_cnt <= padding_cnt + 8;
					end else begin
						S <= (S << 64) | {56'b0, 8'h80};
						S_len <= S_len + 8;
						padding_cnt <= padding_cnt + 8;
					end
					
					// keccakIn_val;
					if(zerotoadd - padding_cnt == 8) begin
						keccakIn_val <= 1'b1;
					end
				end
				ABSORB: begin
					S <= 1344'b0;
					S_len <= 8'b0;
					keccakIn_val <= 1'b0;
					firstmsg_val <= 1'b0;
				end
				SQUEEZ: begin
					// S_len;
					S_len <= 8'b0;
					// firstmsg_val;
					firstmsg_val <= 1'b0;
					// sqzcurcnt;
					if(keccakOut_val) sqzcurcnt <= sqzcurcnt + 1'b1;
					// keccakIn_val;
					if(keccakOut_val && sqzcurcnt < sqzcnt - 1)
						keccakIn_val <= 1'b1;
					else
						keccakIn_val <= 1'b0;
					// S, S_len;
					if(keccakOut_val) begin
						S <= keccakOut;
						case(model_sel)
							1'b0: S_len <= 168;
							1'b1: S_len <= 136;
						endcase
					end else begin
						if(sqzout448_en && S_shift_en) begin
							S <= (S << 448);
							S_len <= S_len - 56;
						end else if(sqzout64_en && S_shift_en) begin
							S <= (S << 64);
							S_len <= S_len - 8;
						end
					end
					// S_shift_en;
					if(keccakOut_val)
						S_shift_en <= 1'b1;
					else if(S_len == 56 && sqzout448_val && sqzout448_en)
						S_shift_en <= 1'b0;
					else if(S_len ==  8 && sqzout64_val  && sqzout64_en)
						S_shift_en <= 1'b0;
					else
						S_shift_en <= S_shift_en;
				end
				CLEAR: begin
					S <= 1344'b0;
					S_len <= 8'b0;
					S_shift_en <= 1'b0;
					keccakIn_val <= 1'b0;
					firstmsg_val <= 1'b1;
					zerotoadd <= 8'b0;
					padding_cnt <= 8'b0;
					sqzcurcnt <= 9'b0;
					done <= 1'b1;
				end
			endcase
		end
	end
	
	// process msg;
	Msg_Processor Msg_Processor_uut(
	.clk(clk),
    .rstn(rstn),
    
    .msg(msg),
    .msg_val(msg_val),
    .lastmsg_val(lastmsg_val),
    
    // indexa
    .indexa(indexa),
    .indexa_val(indexa_val),
    
    // indexb
    .indexb(indexb),
    .indexb_val(indexb_val),
    
    // padflag
    .padflag(padflag),
    
    // msgr;
    .msgn(msgn),
    .msgn_val(msgn_val),
    .lastmsgn_val(lastmsgn_val)
    );
	
	// Keccak;
	Keccak Keccak_uut(
	.clk(clk),
	.rstn(rstn),
	
	.datr(keccakIn),
	.datr_val(keccakIn_val),
	
	.model_sel(model_sel),
	.isfirstblock(firstmsg_val),
	
	.out(keccakOut),
	.out_val(keccakOut_val)
    );
	
	// keccakIn;
	assign keccakIn = (CS == SQUEEZ && keccakIn_val && sqzcurcnt == 0) ? S : 1344'b0;
	
	// onehash_val;
	assign onehash_val = keccakOut_val;
	
	// sqzout448;
	assign sqzout448 = S[1343:896];
	// sqzout448_val;
	assign sqzout448_val = sqzout448_en && S_shift_en;
	
	// sqzout64;
	assign sqzout64 = S[1343:1280];
	// sqzout64_val;
	assign sqzout64_val = sqzout64_en && S_shift_en;
	
endmodule
