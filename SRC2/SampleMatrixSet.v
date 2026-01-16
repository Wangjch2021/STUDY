`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/30 11:08:51
// Design Name: 
// Module Name: SampleMatrixSet
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
module SampleMatrixSet #(
    parameter PARALLEL_NUM = 28)(
    input [16*PARALLEL_NUM-1:0] smInSet,
	input [1:0] sec_lvl,
    output [16*PARALLEL_NUM-1:0] smOutSet
);
	
    // Intermediate;
    wire [16-1:0] smIn [0:PARALLEL_NUM-1];
    wire [16-1:0] smOut [0:PARALLEL_NUM-1];
    
	wire [14:0] prng [0:PARALLEL_NUM-1];
	wire sign [0:PARALLEL_NUM-1];
	reg [14:0] threshold [0:12];
	wire [12:0] cmp_result [0:PARALLEL_NUM-1];
	wire [15:0] sum [0:PARALLEL_NUM-1];
	
    genvar i, j;
    // smInSet --> smIn;
    generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin: X0
            assign smIn[i] = {smInSet[i*16+: 8], smInSet[i*16+8+: 8]};
        end
    endgenerate
    
	// cmp_result;
	generate
		for (i = 0; i < PARALLEL_NUM; i = i + 1) begin : outer_loop
			for (j = 0; j < 13; j = j + 1) begin : inner_loop
				assign cmp_result[i][j] = prng[i] > threshold[j];
			end
		end
	endgenerate
	
	// sum;
	generate
		for(i = 0; i < PARALLEL_NUM; i = i + 1) begin: X1
			assign sum[i] = cmp_result[i][ 0] + cmp_result[i][1]  + cmp_result[i][ 2] + cmp_result[i][ 3] + 
                            cmp_result[i][ 4] + cmp_result[i][5]  + cmp_result[i][ 6] + cmp_result[i][ 7] + 
                            cmp_result[i][ 8] + cmp_result[i][9]  + cmp_result[i][10] + cmp_result[i][11] + 
                            cmp_result[i][12];
		end
	endgenerate
	
	// smout;
	generate
		for(i = 0; i < PARALLEL_NUM; i = i + 1) begin: X2
			assign smOut[i] = sign[i] ? (~sum[i] + 16'd1) : sum[i];
		end
	endgenerate
	
    // smOut --> smOutSet;
    generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin: X3
            assign smOutSet[i*16 +: 16] = smOut[i];
        end
    endgenerate
	
	// Threshold;
	always @(*) begin
		case(sec_lvl)
			2'b00: begin
				threshold[ 0] = 15'd4643 ;
				threshold[ 1] = 15'd13363;
				threshold[ 2] = 15'd20579;
				threshold[ 3] = 15'd25843;
				threshold[ 4] = 15'd29227;
				threshold[ 5] = 15'd31145;
				threshold[ 6] = 15'd32103;
				threshold[ 7] = 15'd32525;
				threshold[ 8] = 15'd32689;
				threshold[ 9] = 15'd32745;
				threshold[10] = 15'd32762;
				threshold[11] = 15'd32766;
				threshold[12] = 15'd32767;
			end
			2'b01: begin
				threshold[ 0] = 15'd5638;
				threshold[ 1] = 15'd15915;
				threshold[ 2] = 15'd23689;
				threshold[ 3] = 15'd28571;
				threshold[ 4] = 15'd31116;
				threshold[ 5] = 15'd32217;
				threshold[ 6] = 15'd32613;
				threshold[ 7] = 15'd32731;
				threshold[ 8] = 15'd32760;
				threshold[ 9] = 15'd32766;
				threshold[10] = 15'd32767;
				threshold[11] = 15'd32767;
				threshold[12] = 15'd32767;
			end
			2'b10: begin
				threshold[ 0] = 15'd9142;
				threshold[ 1] = 15'd23462;
				threshold[ 2] = 15'd30338;
				threshold[ 3] = 15'd32361;
				threshold[ 4] = 15'd32725;
				threshold[ 5] = 15'd32765;
				threshold[ 6] = 15'd32767;
				threshold[ 7] = 15'd32767;
				threshold[ 8] = 15'd32767;
				threshold[ 9] = 15'd32767;
				threshold[10] = 15'd32767;
				threshold[11] = 15'd32767;
				threshold[12] = 15'd32767;
			end
			default: begin
				threshold[ 0] = 15'd32767;
				threshold[ 1] = 15'd32767;
				threshold[ 2] = 15'd32767;
				threshold[ 3] = 15'd32767;
				threshold[ 4] = 15'd32767;
				threshold[ 5] = 15'd32767;
				threshold[ 6] = 15'd32767;
				threshold[ 7] = 15'd32767;
				threshold[ 8] = 15'd32767;
				threshold[ 9] = 15'd32767;
				threshold[10] = 15'd32767;
				threshold[11] = 15'd32767;
				threshold[12] = 15'd32767;
			end
		endcase
	end
	
endmodule
