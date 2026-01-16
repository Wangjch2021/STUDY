`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/30 11:45:48
// Design Name: 
// Module Name: Keccak
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: datIn = (r,c) xor pad(msg)
// 
//////////////////////////////////////////////////////////////////////////////////


module Keccak(
	input			clk,
	input			rstn,
	
	input	[1343:0]datr,
	input			datr_val,
	
	input			model_sel,
	input			isfirstblock,
	
	output	[1343:0]out,
	output	reg		out_val
    );
	// Intermediate;
	`define KECCAKIDLE			1'b0
	`define KECCAKROUND_LOOP	1'b1
	
	localparam ROUND_NUMBER = 23;
	
	// FSM;
	reg				CS;
	reg				NS;
	
	// Keccak;
	reg		[4:0]	rcnt;
	reg		[1599:0]state;
	
	wire	[1599:0]statein;
	wire	[1599:0]stateout;
	
	reg				hashing;
	
	// CS;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			CS <= 1'b0;
		else
			CS <= NS;
	end
	
	// NS;
	always @(CS or datr_val or rcnt) begin
		case(CS)
		`KECCAKIDLE: 
			if(datr_val == 1'b1)
				NS <= `KECCAKROUND_LOOP;
			else
				NS <= `KECCAKIDLE;
		`KECCAKROUND_LOOP:
			if(rcnt == ROUND_NUMBER)
				NS <= `KECCAKIDLE;
			else
				NS <= `KECCAKROUND_LOOP;
		default:
			NS <= `KECCAKIDLE;
		endcase
	end
	
	// hashing;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			hashing <= 1'b0;
		else if((hashing == 1'b0) && (datr_val == 1'b1))
			hashing <= 1'b1;
		else if(rcnt == ROUND_NUMBER)
			hashing <= 1'b0;
		else
			hashing <= hashing;
	end
	
	// rcnt;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			rcnt <= {5{1'b0}};
		else begin
			if(rcnt == ROUND_NUMBER)
				rcnt <= {5{1'b0}};
			else if((CS == `KECCAKROUND_LOOP) || (datr_val == 1'b1))
				rcnt <=  rcnt + 1'b1;
			else
				rcnt <= rcnt;
		end
	end
	
	// state;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			state <= {1600{1'b0}};
		else if((datr_val == 1'b1) || (CS == `KECCAKROUND_LOOP))
			state <= stateout;
		else
			state <= state;
	end
	
	// out_val;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			out_val <= 1'b0;
		else if(rcnt == ROUND_NUMBER)
			out_val <= 1'b1;
		else
			out_val <= 1'b0;
	end
	
	// out;
	assign out = state[1599:256];
	
	// KeccakF1600_StatePermute;
	// statein;
	assign statein = (hashing == 1'b0) ? 
	((model_sel == 0) ? ((isfirstblock == 1'b1) ? {datr[1343:0], {256{1'b0}}} : {state[1599:256] ^ datr[1343:0], state[255:0]})
		               :((isfirstblock == 1'b1) ? {datr[1087:0], {512{1'b0}}} : {state[1599:512] ^ datr[1087:0], state[511:0]})
	)
	: state;
	// KeccakF1600_StatePermute;
	KeccakF1600_StatePermute KeccakF1600_StatePermute_Inst(
		.statein(statein), 
		.rcnt(rcnt), 
		.stateout(stateout)
    );
	
endmodule

module KeccakF1600_StatePermute(
	input	[1599:0]	statein,
	input	[   4:0]	rcnt,
	output	[1599:0]	stateout
    );
	// Intermediate;
	`define high_pos(x, y)	1599 - 64 * (5 * y + x)
	`define low_pos(x, y) 	`high_pos(x, y) - 63
	
	`define rot_up_1(x)		{x[62:0], x[63]}
	`define rot_up(x, n)	{x[63-n:0], x[63:64-n]}
	
	`define add_1(x) 		((x == 4) ? 0 : (x + 1))
	`define add_2(x)		((x == 3) ? 0 : ((x == 4) ? 1 : (x + 2)))
	`define sub_1(x) 		((x == 0) ? 4 : (x - 1))
	
	wire		[63: 0]	a[04:00][04:00];
	wire		[63: 0]	a1[04:00];
	wire		[63: 0]	theat[04:00][04:00];
	wire		[63: 0]	rho[04:00][04:00];
	wire		[63: 0]	pi[04:00][04:00];
	wire		[63: 0]	chi[04:00][04:00];
	wire		[63: 0]	iota[04:00][04:00];
	wire		[63: 0]	constant;
	
	wire		[63: 0]	tmpin[4:0][4:0];
	wire		[63: 0]	tmpout[4:0][4:0];
	
	localparam SIZE = 5;
	
	genvar i, j;
	generate
	for(i = 0; i < SIZE; i = i + 1'b1) begin:T0
		for(j = 0; j < SIZE; j = j + 1'b1) begin:T1
			assign tmpin[i][j] = statein[`high_pos(i, j) : `low_pos(i, j)];
		end
	end
	endgenerate
	
	generate
	for(i = 0; i < SIZE; i = i + 1'b1) begin:X0
		for(j = 0; j < SIZE; j = j + 1'b1) begin:X1
			assign a[i][j][63:56] = tmpin[i][j][ 7: 0];
			assign a[i][j][55:48] = tmpin[i][j][15: 8];
			assign a[i][j][47:40] = tmpin[i][j][23:16];
			assign a[i][j][39:32] = tmpin[i][j][31:24];
			assign a[i][j][31:24] = tmpin[i][j][39:32];
			assign a[i][j][23:16] = tmpin[i][j][47:40];
			assign a[i][j][15: 8] = tmpin[i][j][55:48];
			assign a[i][j][ 7: 0] = tmpin[i][j][63:56];
		end
	end
	endgenerate
	
	// theat
	generate
	for(i = 0; i < SIZE; i = i + 1'b1) begin:X2
		assign a1[i] = a[i][0] ^ a[i][1] ^ a[i][2] ^ a[i][3] ^ a[i][4];
	end
	endgenerate
	
	generate
	for(i = 0; i < SIZE; i = i + 1'b1) begin:X3
		for(j = 0; j < SIZE; j = j + 1'b1) begin:X4
			assign theat[i][j] = a[i][j] ^ a1[`sub_1(i)] ^ `rot_up_1(a1[`add_1(i)]);
		end
	end
	endgenerate
	
	//rho
	assign rho[0][0] = theat[0][0];
	assign rho[0][1] = `rot_up(theat[0][1], 36);	//7
	assign rho[0][2] = `rot_up(theat[0][2], 03);	//1
	assign rho[0][3] = `rot_up(theat[0][3], 41);	//13
	assign rho[0][4] = `rot_up(theat[0][4], 18);	//19
	
	assign rho[1][0] = `rot_up(theat[1][0], 01);	//0
	assign rho[1][1] = `rot_up(theat[1][1], 44);	//23
	assign rho[1][2] = `rot_up(theat[1][2], 10);	//3
	assign rho[1][3] = `rot_up(theat[1][3], 45);	//8
	assign rho[1][4] = `rot_up(theat[1][4], 02);	//10
	
	assign rho[2][0] = `rot_up(theat[2][0], 62);	//18
	assign rho[2][1] = `rot_up(theat[2][1], 06);	//2
	assign rho[2][2] = `rot_up(theat[2][2], 43);	//17
	assign rho[2][3] = `rot_up(theat[2][3], 15);	//4
	assign rho[2][4] = `rot_up(theat[2][4], 61);	//21
	
	assign rho[3][0] = `rot_up(theat[3][0], 28);	//6
	assign rho[3][1] = `rot_up(theat[3][1], 55);	//9
	assign rho[3][2] = `rot_up(theat[3][2], 25);	//16
	assign rho[3][3] = `rot_up(theat[3][3], 21);	//5
	assign rho[3][4] = `rot_up(theat[3][4], 56);	//14
	
	assign rho[4][0] = `rot_up(theat[4][0], 27);	//12
	assign rho[4][1] = `rot_up(theat[4][1], 20);	//22
	assign rho[4][2] = `rot_up(theat[4][2], 39);	//20
	assign rho[4][3] = `rot_up(theat[4][3], 08);	//15
	assign rho[4][4] = `rot_up(theat[4][4], 14);	//11
	
	//pi
	assign pi[0][0] = rho[0][0];
	assign pi[0][1] = rho[3][0];
	assign pi[0][2] = rho[1][0];
	assign pi[0][3] = rho[4][0];
	assign pi[0][4] = rho[2][0];
	
	assign pi[1][0] = rho[1][1];
	assign pi[1][1] = rho[4][1];
	assign pi[1][2] = rho[2][1];
	assign pi[1][3] = rho[0][1];	
	assign pi[1][4] = rho[3][1];
	
	assign pi[2][0] = rho[2][2];
	assign pi[2][1] = rho[0][2];
	assign pi[2][2] = rho[3][2];
	assign pi[2][3] = rho[1][2];
	assign pi[2][4] = rho[4][2];
	
	assign pi[3][0] = rho[3][3];
	assign pi[3][1] = rho[1][3];
	assign pi[3][2] = rho[4][3];
	assign pi[3][3] = rho[2][3];
	assign pi[3][4] = rho[0][3];
	
	assign pi[4][0] = rho[4][4];
	assign pi[4][1] = rho[2][4];
	assign pi[4][2] = rho[0][4];
	assign pi[4][3] = rho[3][4];
	assign pi[4][4] = rho[1][4];
	
	//chi
	generate
	for(i = 0; i < SIZE; i = i + 1'b1) begin:X5
		for(j = 0; j < SIZE; j = j + 1'b1) begin:X6
			assign chi[i][j] = pi[i][j] ^ (~pi[`add_1(i)][j] & pi[`add_2(i)][j]);
		end
	end
	endgenerate
	
	//iota
	generate
	for(i = 0; i < SIZE; i = i + 1'b1) begin:X7 
		for(j = 0; j < SIZE; j = j + 1'b1) begin:X8
			if(i == 0 && j == 0) begin
				assign iota[i][j] = chi[i][j] ^ constant;
			end else
				assign iota[i][j] = chi[i][j];
		end
	end
	endgenerate
	
	//storage
	generate
	for(i = 0; i < SIZE; i = i + 1'b1) begin:T2
		for(j = 0; j < SIZE; j = j + 1'b1) begin:T3
			assign tmpout[i][j][63:56] = iota[i][j][ 7: 0];
			assign tmpout[i][j][55:48] = iota[i][j][15: 8];
			assign tmpout[i][j][47:40] = iota[i][j][23:16];
			assign tmpout[i][j][39:32] = iota[i][j][31:24];
			assign tmpout[i][j][31:24] = iota[i][j][39:32];
			assign tmpout[i][j][23:16] = iota[i][j][47:40];
			assign tmpout[i][j][15: 8] = iota[i][j][55:48];
			assign tmpout[i][j][ 7: 0] = iota[i][j][63:56];
		end
	end
	endgenerate
	
	generate
	for(i = 0; i < SIZE; i = i + 1) begin:X9
		for(j = 0; j < SIZE; j = j + 1) begin:X10
			assign stateout[`high_pos(i, j) : `low_pos(i, j)] = tmpout[i][j];
		end
	end
	endgenerate
	
	// rconstant
	Rcont Rcon_Inst( .rcnt(rcnt), .constant(constant) );
	
endmodule

// Round Constant
module Rcont(
	input		[4:0]		rcnt,
	output	reg [63:0]		constant
    );
	
	always @(rcnt)
	case(rcnt)
		5'd0: constant = 64'h0000000000000001;	//63
		5'd1: constant = 64'h0000000000008082;	//48 56 62
		5'd2: constant = 64'h800000000000808a;
		5'd3: constant = 64'h8000000080008000;
		5'd4: constant = 64'h000000000000808b;
		5'd5: constant = 64'h0000000080000001;
		5'd6: constant = 64'h8000000080008081;
		5'd7: constant = 64'h8000000000008009;
		5'd8: constant = 64'h000000000000008a;
		5'd9: constant = 64'h0000000000000088;
		5'd10:constant = 64'h0000000080008009;
		5'd11:constant = 64'h000000008000000a;
		5'd12:constant = 64'h000000008000808b;
		5'd13:constant = 64'h800000000000008b;
		5'd14:constant = 64'h8000000000008089;
		5'd15:constant = 64'h8000000000008003;
		5'd16:constant = 64'h8000000000008002;
		5'd17:constant = 64'h8000000000000080;
		5'd18:constant = 64'h000000000000800a;
		5'd19:constant = 64'h800000008000000a;
		5'd20:constant = 64'h8000000080008081;
		5'd21:constant = 64'h8000000000008080;
		5'd22:constant = 64'h0000000080000001;
		5'd23:constant = 64'h8000000080008008;
		default:
			constant = 64'b0;
	endcase
	
endmodule

