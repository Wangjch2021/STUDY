`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/14 21:44:36
// Design Name: 
// Module Name: UnpackSet
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
module UnpackSet (
	input clk,
	input rstn,
	
	input [1:0] sec_lvl,
	
	input [63:0] unpackIn,
	input unpackIn_val,
	
	output reg [63:0] unpackOut,
	output unpackOut_val,
	output full
    );
	
	// Internal registers;
	reg [127:0] buffer;
	reg [6:0] buf_bits;
	reg [3:0] outcnt;
	
	// buffer, buf_bits;
	always @(posedge clk or negedge rstn) begin
		if(~rstn) begin
			buffer <= 128'b0;
			buf_bits <= 7'b0;
		end else begin
			// buffer;
			if(unpackIn_val) begin
				buffer <= (buffer << 64) | unpackIn;
			end
			
			// buf_bits;
			case({unpackIn_val, unpackOut_val})
				2'b00: buf_bits <= buf_bits;
				2'b01: buf_bits <= buf_bits - 7'd60;
				2'b10: buf_bits <= buf_bits + 7'd64;
				2'b11: buf_bits <= buf_bits + 7'd4;
			endcase
		end
	end
	
	// outcnt;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			outcnt <= 4'b0;
		else begin
			if(unpackOut_val)
				outcnt <= outcnt + 1'b1;
			else
				outcnt <= outcnt;
		end
	end
	
	// unpackOut;
	always @(*) begin
		if(sec_lvl == 2'b0) begin
			case(outcnt)
				4'h0: unpackOut <= {1'b0, buffer[63:49],  1'b0, buffer[48:34], 
									1'b0, buffer[33:19],  1'b0, buffer[18: 4]};
				4'h1: unpackOut <= {1'b0, buffer[67:53],  1'b0, buffer[52:38], 
									1'b0, buffer[37:23],  1'b0, buffer[22: 8]};
				4'h2: unpackOut <= {1'b0, buffer[71:57],  1'b0, buffer[56:42], 
									1'b0, buffer[41:27],  1'b0, buffer[26:12]};
				4'h3: unpackOut <= {1'b0, buffer[75:61],  1'b0, buffer[60:46], 
									1'b0, buffer[45:31],  1'b0, buffer[30:16]}; 
				4'h4: unpackOut <= {1'b0, buffer[79:65],  1'b0, buffer[64:50], 
									1'b0, buffer[49:35],  1'b0, buffer[34:20]};
				4'h5: unpackOut <= {1'b0, buffer[83:69],  1'b0, buffer[68:54], 
									1'b0, buffer[53:39],  1'b0, buffer[38:24]};
				4'h6: unpackOut <= {1'b0, buffer[87:73],  1'b0, buffer[72:58], 
									1'b0, buffer[57:43],  1'b0, buffer[42:28]};
				4'h7: unpackOut <= {1'b0, buffer[91:77],  1'b0, buffer[76:62], 
									1'b0, buffer[61:47],  1'b0, buffer[46:32]};					
				4'h8: unpackOut <= {1'b0, buffer[95:81],  1'b0, buffer[80:66], 
									1'b0, buffer[65:51],  1'b0, buffer[50:36]};						
				4'h9: unpackOut <= {1'b0, buffer[99:85],  1'b0, buffer[84:70], 
									1'b0, buffer[69:55],  1'b0, buffer[54:40]};
				4'ha: unpackOut <= {1'b0, buffer[103:89], 1'b0, buffer[88:74], 
									1'b0, buffer[73:59],  1'b0, buffer[58:44]};					
				4'hb: unpackOut <= {1'b0, buffer[107:93], 1'b0, buffer[92:78], 
									1'b0, buffer[77:63],  1'b0, buffer[62:48]};
				4'hc: unpackOut <= {1'b0, buffer[111:97], 1'b0, buffer[96:82], 
									1'b0, buffer[81:67],  1'b0, buffer[66:52]};
				4'hd: unpackOut <= {1'b0, buffer[115:101],1'b0, buffer[100:86], 
									1'b0, buffer[85:71],  1'b0, buffer[70:56]};
				4'he: unpackOut <= {1'b0, buffer[119:105],1'b0, buffer[104:90], 
									1'b0, buffer[89:75],  1'b0, buffer[74:60]};
				4'hf: unpackOut <= {1'b0, buffer[59:45],  1'b0, buffer[44:30], 
									1'b0, buffer[29:15],  1'b0, buffer[14: 0]};					
			endcase
		end else begin
			unpackOut <= unpackIn;
		end
	end
	
	// unpackOut_val;
	assign unpackOut_val = (sec_lvl == 2'b0) ? ((buf_bits >= 60) ? 1'b1 : 1'b0) : unpackIn_val;
	
	// full;
	assign full = (buf_bits == 116) ? 1'b1 : 1'b0;
	
endmodule