`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/30 11:40:55
// Design Name: 
// Module Name: EncodeSet
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
// Yes;
module EncodeSet(
    input clk,
    input rstn,
    
	input [1:0] sec_lvl,
	
	input [63:0] msg,
	input msg_val,
	
	input en,
	
	output reg [63:0] encodeOut,
	output encodeOut_val
);
    
    // Intermediate;
	localparam RECEIVE = 2'b00;
	localparam OUTPUT  = 2'b01;
	localparam CLEAR   = 2'b10;
	
	reg [1:0] CS;
	reg [1:0] NS;
	
	reg [255:0] buffer;
	reg [2:0] buf_cnt;
	reg [3:0] out_cnt;
	
	// CS;
	always @(posedge clk) CS <= NS;
	
	// NS;
	always @(*) begin
		case(CS)
			RECEIVE: begin
				case(sec_lvl)
					2'b00: if(buf_cnt == 1 && msg_val) NS <= OUTPUT;
					2'b01: if(buf_cnt == 2 && msg_val) NS <= OUTPUT;
					2'b10: if(buf_cnt == 3 && msg_val) NS <= OUTPUT;
					default:						   NS <= RECEIVE;
				endcase
			end
			OUTPUT: begin
				if(out_cnt == 15 && encodeOut_val)
					NS <= CLEAR;
				else
					NS <= OUTPUT;
			end
			CLEAR:	NS <= RECEIVE;
			default: NS <= CLEAR;
		endcase
	end
	
	// buffer, buf_cnt, out_cnt;
	always @(posedge clk or negedge rstn) begin
		if(~rstn) begin
			buffer <= 256'b0;
			buf_cnt <= 3'b0;
			out_cnt <= 4'b0;
		end else begin
			case(CS)
				RECEIVE: begin
					if(msg_val) begin
						buffer <= (buffer << 64) | msg;
						buf_cnt <= buf_cnt + 1'b1;
					end
				end
				OUTPUT: begin
					if(en) begin
						case(sec_lvl) 
							2'b00: buffer <= buffer <<  8;
							2'b01: if(out_cnt[0]) buffer <= buffer << 24;
							2'b10: buffer <= buffer << 16;
							default: buffer <= buffer;
						endcase
						out_cnt <= out_cnt + 1'b1;
					end
				end
				CLEAR: begin
					buffer <= 256'b0;
					buf_cnt <= 3'b0;
					out_cnt <= 3'b0;
				end
				default: begin
					buffer <= 256'b0;
					buf_cnt <= 3'b0;
					out_cnt <= 3'b0;
				end
			endcase
		end
	end
	
	// encodeOut;
	always @(*) begin
		case(sec_lvl)
			2'b00: begin
				encodeOut[63:48] <= {1'b0, buffer[121:120], 13'b0};
				encodeOut[47:32] <= {1'b0, buffer[123:122], 13'b0};
				encodeOut[31:16] <= {1'b0, buffer[125:124], 13'b0};
				encodeOut[15: 0] <= {1'b0, buffer[127:126], 13'b0};
			end
			2'b01: begin
				if(out_cnt[0] == 0) begin
					encodeOut[63:48] <= {buffer[186:184], 13'b0};
					encodeOut[47:32] <= {buffer[189:187], 13'b0};
					encodeOut[31:16] <= {buffer[176], buffer[191:190], 13'b0};
					encodeOut[15: 0] <= {buffer[179:177], 13'b0};
				end else begin
					encodeOut[63:48] <= {buffer[182:180], 13'b0};
					encodeOut[47:32] <= {buffer[169:168], buffer[183], 13'b0};
					encodeOut[31:16] <= {buffer[172:170], 13'b0};
					encodeOut[15: 0] <= {buffer[175:173], 13'b0};
				end
			end
			2'b10: begin
				encodeOut[63:48] <= {buffer[251:248], 12'b0};
				encodeOut[47:32] <= {buffer[255:252], 12'b0};
				encodeOut[31:16] <= {buffer[243:240], 12'b0};
				encodeOut[15: 0] <= {buffer[247:244], 12'b0};
			end
			default: begin
				encodeOut <= 64'b0;
			end
		endcase
	end
	
	// encodeOut_val;
	assign encodeOut_val = (CS == OUTPUT) ? en : 1'b0;
	
endmodule
