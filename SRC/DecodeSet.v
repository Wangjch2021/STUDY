`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//增补：1. ready信号，为了消除读地址带来的气泡
//		  不再设置en信号，直接让其输入满后自行输出	
module DecodeSet(
	input clk,
	input rstn,
	
	input [1:0] sec_lvl,
	
	input [63:0] msg,
	input msg_val,
	
//	input en,
	output ready,   
	output reg [63:0] decodeOut,
	output reg        decodeOut_val
    );
	
	// Intermediate;
	localparam RECEIVE = 2'b00;
	localparam OUTPUT  = 2'b01;
	localparam CLEAR   = 2'b10;
	localparam [119:0] RM976_MAP_PACKED = {
		// rm976_r;
		5'h14, 5'h13, 5'h18, 5'h17, 5'h16, 5'h1B,
		5'h1A, 5'h19, 5'h06, 5'h0B, 5'h0A, 5'h09,
		// rm976_tmp; 
		5'h12, 5'h11, 5'h10, 5'h15, 5'h02, 5'h01,
		5'h00, 5'h05, 5'h04, 5'h03, 5'h08, 5'h07
	};
	
	reg [1:0] CS;
	reg [1:0] NS;
	
	wire [15:0] msg_segments[3:0];
	
	reg [255:0] buffer;
	reg [3:0] buf_cnt;
	reg [1:0] out_cnt;
	
	wire [7:0] rm640;
	wire [4:0] rm976_map [0:23];
	wire [23:0] rm976;
	wire [11:0] rm976_tmp;
	reg  [11:0] rm976_r;
	wire [15:0] rm1344;
	
	// CS;
	always @(posedge clk) CS <= NS;
	
	// NS;
	always @(*) begin
		case(CS)
			RECEIVE: begin
				if(buf_cnt == 15 && msg_val)
					NS <= OUTPUT;
				else
					NS <= RECEIVE;
			end
			OUTPUT: begin
				case(sec_lvl)
					2'b00: if(out_cnt == 1 && decodeOut_val) NS <= CLEAR;
					2'b01: if(out_cnt == 2 && decodeOut_val) NS <= CLEAR;
					2'b10: if(out_cnt == 3 && decodeOut_val) NS <= CLEAR;
					default: 								 NS <= OUTPUT;
				endcase
			end
			CLEAR:	NS <= RECEIVE;
			default: NS <= CLEAR;
		endcase
	end
	
	// msg_segments;
	genvar i;
	generate
		for(i = 0; i < 4; i = i + 1'b1) begin: X0
			assign msg_segments[i] = msg[i*16+15:i*16];
		end
	endgenerate
	
	// rm640;
	generate
		for(i = 0; i < 4; i = i + 1'b1) begin: X1
			roundmod #(.B(2), .Q(15)) u_roundmod640 (
				.data_in(msg_segments[i]),
				.data_out(rm640[(3-i)*2+1:(3-i)*2])
			);
		end
	endgenerate
	
	// rm976_map;
	generate
		for (i = 0; i < 24; i = i + 1) begin
			assign rm976_map[i] = RM976_MAP_PACKED[i*5+4:i*5];
		end
	endgenerate
	
	// rm976;
	generate
		for(i = 0; i < 4; i = i + 1'b1) begin: X2
			roundmod #(.B(3), .Q(16)) u_roundmod976 (
				.data_in(msg_segments[i]), 
				.data_out(rm976_tmp[i*3+2:i*3])
			);
		end
		//rm976_r;
		always @(posedge clk) rm976_r <= rm976_tmp;
		// rm976;
		assign rm976 = {
			rm976_r[4],   rm976_r[ 3],  rm976_r[ 8],  rm976_r[7], 
			rm976_r[6],   rm976_r[11],  rm976_r[10],  rm976_r[9],  // 16-23
			rm976_tmp[6], rm976_tmp[11],rm976_tmp[10],rm976_tmp[9], 
			rm976_r[2],   rm976_r[1],   rm976_r[0],   rm976_r[5],   // 8-15
			rm976_tmp[2], rm976_tmp[1], rm976_tmp[0], rm976_tmp[5], 
			rm976_tmp[4], rm976_tmp[3], rm976_tmp[8], rm976_tmp[7]      // 0-7
		};
	endgenerate
	
	// rm1344;
	generate
		for(i = 0; i < 4; i = i + 1'b1) begin: X3
			roundmod #(.B(4), .Q(16)) u_roundmod1344 (
				.data_in(msg_segments[i]),
				.data_out({rm1344[(3-i)*4+1], rm1344[(3-i)*4+0], 
						   rm1344[(3-i)*4+3], rm1344[(3-i)*4+2]})
			);
		end
	endgenerate
	
	// buffer, buf_cnt, out_cnt;
	always @(posedge clk or negedge rstn) begin
		if(~rstn) begin
			buffer <= 256'b0;
			buf_cnt <= 4'b0;
			out_cnt <= 2'b0;
		end else begin
			case(CS)
				RECEIVE: begin
					if(msg_val) begin
						case(sec_lvl)
							2'b00: buffer <= (buffer <<  8) | rm640;
							2'b01: if(buf_cnt[0]) buffer <= (buffer << 24) | rm976;
							2'b10: buffer <= (buffer << 16) | rm1344;
							default: buffer <= buffer;
						endcase
						buf_cnt <= buf_cnt + 1'b1;
					end
				end
				OUTPUT: begin
						buffer <= buffer << 64;
						out_cnt <= out_cnt + 1'b1;
				end
				CLEAR: begin
					buffer <= 256'b0;
					buf_cnt <= 4'b0;
					out_cnt <= 2'b0;
				end
				default: begin
					buffer <= 256'b0;
					buf_cnt <= 4'b0;
					out_cnt <= 2'b0;
				end
			endcase
		end
	end
	
	// decodeOut;
	always @(*) begin
		case(sec_lvl)
			2'b00:   decodeOut <= buffer[127:64];
			2'b01:   decodeOut <= buffer[191:128];
			2'b10:   decodeOut <= buffer[255:192];
			default: decodeOut <= 64'b0;
		endcase
	end
	
	// encodeOut_val;
//	assign decodeOut_val = (CS == OUTPUT) ? en : 1'b0;
	assign ready = (CS == RECEIVE);
	
	always@(posedge clk or negedge rstn)begin
		if(!rstn)
			decodeOut_val <= 1'b0;
		else if(CS == OUTPUT)
			decodeOut_val <= 1'b1;
		else
			decodeOut_val <= 1'b0;
	end



endmodule
