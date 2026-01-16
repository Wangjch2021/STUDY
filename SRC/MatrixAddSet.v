`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/21 20:03:51
// Design Name: 
// Module Name: MatrixAddSet
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


module MatrixAddSet #(parameter
	PARALLEL_NUM = 28)(
	input [16*PARALLEL_NUM-1:0] addaSet,
    input [16*PARALLEL_NUM-1:0] addbSet,
    output [16*PARALLEL_NUM-1:0] addabSet
    );
	// Intermediate;
    wire [16-1:0] adda [0:PARALLEL_NUM-1];
    wire [16-1:0] addb [0:PARALLEL_NUM-1];
    wire [16-1:0] addab [0:PARALLEL_NUM-1];
	
	genvar i;
    // aset --> a, bset --> b;
    generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign adda[i] = addaSet[i*16 +: 16];
            assign addb[i] = addbSet[i*16 +: 16];
        end
    endgenerate
    
    // a + b;
    generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign addab[i] = adda[i] + addb[i];
        end
    endgenerate
    
    // ab --> abset
    generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign addabSet[i*16 +: 16] = addab[i];
        end
    endgenerate
	
endmodule
