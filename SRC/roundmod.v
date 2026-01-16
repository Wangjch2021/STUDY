`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/21 03:57:06
// Design Name: 
// Module Name: roundmod
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


module roundmod #(
    parameter B = 2,        
    parameter Q = 15)(
    input [15:0] data_in,
    output [B-1:0] data_out
);
    
    localparam SCALE_BITS = B;
    
    wire [31:0] scaled;
    wire [15:0] divided;
    wire [Q-1:0] fractional_part;
    wire round_up;
    wire [B-1:0] rounded;
    
    assign scaled = data_in << SCALE_BITS;
    assign divided = scaled >> Q;
    assign fractional_part = scaled[Q-1:0];
    assign round_up = (fractional_part >= (1 << (Q-1))) ? 1 : 0;
    assign rounded = divided + round_up;
    assign data_out = rounded;
    
endmodule
