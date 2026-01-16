`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/14 21:43:27
// Design Name: 
// Module Name: PackSet
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
module PackSet(
	input clk,
	input rstn,
	
	input [1:0] sec_lvl,
	
	// datain;
	input [63:0] packIn,
	input packIn_val,
	
	output reg [63:0] packOut,
	output packOut_val
    );
	
	// Internal registers
	reg [119:0] buffer;   
	reg [6:0] buf_bits;
	wire [59:0] processed_data;
	reg [3:0] outcnt;
	
	// processed_data;
	genvar i;
	generate
		for (i = 0; i < 4; i = i + 1) begin : bit_processing
			assign processed_data[i*15+14:i*15] = packIn[i*16+14:i*16];
		end
	endgenerate
	
	// outcnt;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			outcnt <= 4'b0;
		else begin
			if(packOut_val)
				outcnt <= (outcnt == 4'he) ? 4'b0 : (outcnt + 1'b1);
			else
				outcnt <= outcnt;
		end
	end
	
	// buffer, buf_bits;
	always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            buffer <= 120'b0;
            buf_bits <= 7'b0;
        end else begin
			// buffer;
            if (packIn_val) begin
                buffer <= (buffer << 60) | processed_data;
            end
			
			// buf_bits;
			case({packIn_val, packOut_val})
				2'b00: buf_bits <= buf_bits        ;
				2'b01: buf_bits <= buf_bits - 7'd64;
				2'b10: buf_bits <= buf_bits + 7'd60;
				2'b11: buf_bits <= buf_bits - 7'd4;
            endcase
        end
    end
	
	// packOut;
	always @(*) begin
		if(sec_lvl == 2'b0) begin
			case (outcnt)
				4'h0: packOut <= buffer[119:56];  // 119:56
				4'h1: packOut <= buffer[115:52];  // 115:52
				4'h2: packOut <= buffer[111:48];  // 111:48
				4'h3: packOut <= buffer[107:44];  // 107:44
				4'h4: packOut <= buffer[103:40];  // 103:40
				4'h5: packOut <= buffer[ 99:36];  // 99:36
				4'h6: packOut <= buffer[ 95:32];  // 95:32
				4'h7: packOut <= buffer[ 91:28];  // 91:28
				4'h8: packOut <= buffer[ 87:24];  // 87:24
				4'h9: packOut <= buffer[ 83:20];  // 83:20
				4'ha: packOut <= buffer[ 79:16];  // 79:16
				4'hb: packOut <= buffer[ 75:12];  // 75:12
				4'hc: packOut <= buffer[ 71: 8];  // 71:8
				4'hd: packOut <= buffer[ 67: 4];  // 67:4
				4'he: packOut <= buffer[ 63: 0];  // 63:0
				default: packOut <= buffer[119:56];
			endcase
		end else begin
			packOut <= packIn;
		end
	end
	
	// packOut_val;
	assign packOut_val = (sec_lvl == 2'b0) ? ((buf_bits >= 64) ? 1'b1 : 1'b0) : packIn_val;
	
endmodule
