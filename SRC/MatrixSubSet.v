`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/21 20:07:09
// Design Name: 
// Module Name: MatrixSubSet
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


module MatrixSubSet #(parameter   
    PARALLEL_NUM = 28)(
	input  [16*PARALLEL_NUM-1:0] subaSet,
    input  [16*PARALLEL_NUM-1:0] subbSet,
    output [16*PARALLEL_NUM-1:0] subabSet
);
    // Intermediate;
    wire signed [15:0] suba [0:PARALLEL_NUM-1];
    wire signed [15:0] subb [0:PARALLEL_NUM-1];
    wire signed [15:0] subab [0:PARALLEL_NUM-1];
    
    genvar i;
    // aset --> suba, bset --> subb;
    generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign suba[i] = subaSet[i*16 +: 16];
            assign subb[i] = subbSet[i*16 +: 16];
        end
    endgenerate
    
    // suba - subb;
    generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign subab[i] = suba[i] - subb[i];
        end
    endgenerate
    
    // subab --> subabSet
    generate
        for(i = 0; i < PARALLEL_NUM; i = i + 1) begin
            assign subabSet[i*16 +: 16] = subab[i];
        end
    endgenerate
    
endmodule
