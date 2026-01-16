`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/21 17:36:20
// Design Name: 
// Module Name: MatrixMACSet
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


module MatrixMACSet #(parameter
	PARALLEL_NUM = 28)(
	input clk,
	input rstn,
	
	input [PARALLEL_NUM*16-1:0] mulaSet,
	input [PARALLEL_NUM*16-1:0] mulbSet,
	input [63:0] addcSet,
	
	input mulabSet_val,
	
	output [63:0] macabSet,
	output [63:0] macadd,
	output reg macabSet_val
    );
	
	// Intermediate;
	wire [15:0] mula[0:PARALLEL_NUM-1];
	wire [15:0] mulb[0:PARALLEL_NUM-1];
	wire [15:0] mulab[0:PARALLEL_NUM-1];
	reg [15:0] mulab_sum;
	
	reg [63:0] macabSetr;
	
	reg [1:0] cnt;
	
	genvar i;
	integer j;
	
	// mulaSet-->mula;
	generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign mula[i] = mulaSet[i*16 +: 16];
        end
    endgenerate
	
	// mulbSet-->mulb;
	generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign mulb[i] = mulbSet[i*16 +: 16];
        end
    endgenerate
	
	// mulab;
	generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign mulab[i] = mula[i] * mulb[i];
        end
    endgenerate
	
	// Sum(ai*bi);
	always @(*) begin
        mulab_sum = 16'b0;
        for(j = 0; j < PARALLEL_NUM; j = j + 1) begin
            mulab_sum = mulab_sum + mulab[j];
        end
    end
	
	// cnt;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			cnt <= 2'b0;
		else if(mulabSet_val)
			cnt <= cnt + 1'b1;
		else
			cnt <= cnt;
	end
	
	// macabSetr;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			macabSetr <= 64'b0;
		else if(mulabSet_val)
			macabSetr <= (macabSetr << 16) | mulab_sum;
		else
			macabSetr <= macabSetr;
	end
	
	// macabSet;
	assign macabSet = macabSetr;
	
	// macabSet_val;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			macabSet_val <= 1'b0;
		else if(cnt == 3 && mulabSet_val)
			macabSet_val <= 1'b1;
		else
			macabSet_val <= 1'b0;
	end

	
endmodule
