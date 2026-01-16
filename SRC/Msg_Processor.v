`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/26 15:55:01
// Design Name: 
// Module Name: Msg_Processor
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


module Msg_Processor(
	input clk,
    input rstn,
    
    input [63:0] msg,
    input msg_val,
    input lastmsg_val,
    
    // indexa
    input [7:0] indexa,
    input indexa_val,
    
    // indexb
    input [7:0] indexb,
    input indexb_val,
    
    // padflag
    input [2:0] padflag,
    
    // msgr;
    output [63:0] msgn,
    output msgn_val,
    output lastmsgn_val
    );
	
	// Intermediate;
	reg [7:0] indexar;
	reg indexar_val;
	
	reg [7:0] indexbr;
	reg indexbr_val;
	
	reg [7:0] indexcr;
	reg indexcr_val;

	reg [63:0] msgr;
	reg msgr_val;
	reg lastmsgr_val;
	
	reg [1:0] CS;
	reg [1:0] NS;
	
	localparam PROCESSMSG = 2'b00;
	localparam FINALPROCESS = 2'b01;
	localparam CLEAR = 2'b10;
	
	// CS;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			CS <= PROCESSMSG;
		else 
			CS <= NS;
	end
	
	// NS;
	always @(*) begin
		case(CS)
			PROCESSMSG: 
				if(lastmsg_val) 
					NS <= FINALPROCESS;
				else 
					NS <= PROCESSMSG;
			FINALPROCESS: NS <= CLEAR;
			CLEAR: NS <= PROCESSMSG;
			default: NS <= CLEAR;
		endcase
	end
	
	// indexar, indexbr, msgr;
	always @(posedge clk or negedge rstn) begin
		if(~rstn) begin
			indexar <= 8'b0;
			indexar_val <= 1'b0;
			
			indexbr <= 8'b0;
			indexbr_val <= 1'b0;
			
			indexcr <= 8'b0;
			indexcr_val <= 1'b0;

			msgr <= 64'b0;
			msgr_val <= 1'b0;
			lastmsgr_val <= 1'b0;
		end else begin
			case(CS)
				PROCESSMSG: begin
					if(msg_val) begin
						if(indexa_val && indexb_val) begin
							msgr <= {indexa, indexb, msg[63:16]};
							msgr_val <= 1'b1;
							lastmsgr_val <= 1'b0;
							
							indexar <= msg[15:8];
							indexar_val <= 1'b1;
							
							indexbr <= msg[7:0];
							indexbr_val <= 1'b1;

							indexcr <= 8'b0;
							indexcr_val <= 1'b0;
						end else if(indexa_val) begin
							msgr <= {indexa, msg[63:8]};
							msgr_val <= 1'b1;
							lastmsgr_val <= 1'b0;
							
							indexar <= msg[7:0];
							indexar_val <= 1'b1;
							
							indexbr <= 8'b0;
							indexbr_val <= 1'b0;

							indexcr <= 8'b0;
							indexcr_val <= 1'b0;
						end else if(indexar_val && indexbr_val) begin
							if(lastmsg_val) begin
								case(padflag)
									3'b000: begin
										msgr <= {indexar, indexbr, msg[63:16]};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b0;
										
										indexar <= msgr[15:8];
										indexar_val <= 1'b1;
										
										indexbr <= 8'h1F;
										indexbr_val <= 1'b1;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b001: begin
										msgr <= {indexar, indexbr, msg[63:16]};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b0;
										
										indexar <= 8'h1F;
										indexar_val <= 1'b1;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b1;
										
										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b010: begin
										msgr <= {indexar, indexbr, msg[63:24], 8'h1F};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b011: begin
										msgr <= {indexar, indexbr, msg[63:32], 8'h1F, 8'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b100: begin
										msgr <= {indexar, indexbr, msg[63:40], 8'h1F, 16'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b101: begin
										msgr <= {indexar, indexbr, msg[63:48], 8'h1F, 24'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b110: begin
										msgr <= {indexar, indexbr, msg[63:56], 8'h1F, 32'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b111: begin // check;
										msgr <= {indexar, indexbr, msg[63:16]};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b0;
										
										indexar <= msg[15:8];
										indexar_val <= 1'b1;
										
										indexbr <= msg[ 7:0];
										indexbr_val <= 1'b1;

										indexcr <= 8'h1F;
										indexcr_val <= 1'b1;
									end
								endcase
							end else begin
								msgr <= {indexar, indexbr, msg[63:16]};
								msgr_val <= 1'b1;
								lastmsgr_val <= 1'b0;
								
								indexar <= msg[15:8];
								indexar_val <= 1'b1;
								
								indexbr <= msg[7:0];
								indexbr_val <= 1'b1;

								indexcr <= 8'b0;
								indexcr_val <= 1'b0;
							end
						end else if(indexar_val) begin
							if(lastmsg_val) begin
								case(padflag)
									3'b000: begin
										msgr <= {indexar, msg[63:8]};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b0;
										
										indexar <= 8'h1F;
										indexar_val <= 1'b1;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b001: begin
										msgr <= {indexar, msg[63:16], 8'h1F};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b010: begin
										msgr <= {indexar, msg[63:24], 8'h1F, 8'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b011: begin
										msgr <= {indexar, msg[63:32], 8'h1F, 16'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b100: begin
										msgr <= {indexar, msg[63:40], 8'h1F, 24'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b101: begin
										msgr <= {indexar, msg[63:48], 8'h1F, 32'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b110: begin
										msgr <= {indexar, msg[63:56], 8'h1F, 40'b0};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b1;
										
										indexar <= 8'b0;
										indexar_val <= 1'b0;
										
										indexbr <= 8'b0;
										indexbr_val <= 1'b0;

										indexcr <= 8'b0;
										indexcr_val <= 1'b0;
									end
									3'b111: begin // check;
										msgr <= {indexar, msg[63:8]};
										msgr_val <= 1'b1;
										lastmsgr_val <= 1'b0;
										
										indexar <= msg[7:0];
										indexar_val <= 1'b1;
										
										indexbr <= 8'h1F;
										indexbr_val <= 1'b1;

										indexcr <= 8'b0;
										indexcr_val <= 1'b1;
									end
								endcase
							end else begin
								msgr <= {indexar, msg[63:8]};
								msgr_val <= 1'b1;
								lastmsgr_val <= 1'b0;
									
								indexar <= msg[7:0];
								indexar_val <= 1'b1;
									
								indexbr <= 8'b0;
								indexbr_val <= 1'b0;

								indexcr <= 8'b0;
								indexcr_val <= 1'b0;
							end
						end else begin
							if(lastmsg_val) begin
								msgr <= msg[63:0];
								msgr_val <= 1'b1;
								lastmsgr_val <= 1'b0;
								
								indexar <= 8'h1F;
								indexar_val <= 1'b1;
								
								indexbr <= 8'b0;
								indexbr_val <= 1'b1;

								indexcr <= 8'b0;
								indexcr_val <= 1'b1;
							end else begin
								msgr <= msg[63:0];
								msgr_val <= 1'b1;
								lastmsgr_val <= 1'b0;
								
								indexar <= 8'b0;
								indexar_val <= 1'b0;
								
								indexbr <= 8'b0;
								indexbr_val <= 1'b0;

								indexcr <= 8'b0;
								indexcr_val <= 1'b0;
							end
						end
					end else begin
						msgr <= msgr;
						msgr_val <= 1'b0;
						lastmsgr_val <= 1'b0;
								
						indexar <= indexar;
						indexar_val <= indexar_val;
								
						indexbr <= indexbr;
						indexbr_val <= indexbr_val;

						indexcr <= indexcr;
						indexcr_val <= indexcr_val;
					end
				end
				FINALPROCESS: begin
					if(indexar_val && indexbr_val && indexcr_val) begin
						msgr <= {indexar, indexbr, indexcr, 40'b0};
						msgr_val <= 1'b1;
						lastmsgr_val <= 1'b1;
					end else begin
						msgr <= msgr;
						msgr_val <= 1'b0;
						lastmsgr_val <= 1'b0;
					end
				end
				CLEAR: begin
					indexar <= 8'b0;
					indexar_val <= 1'b0;
					
					indexbr <= 8'b0;
					indexbr_val <= 1'b0;
					
					indexcr <= 8'b0;
					indexcr_val <= 1'b0;

					msgr <= 64'b0;
					msgr_val <= 1'b0;
					lastmsgr_val <= 1'b0;
				end
				default: begin
					indexar <= 8'b0;
					indexar_val <= 1'b0;
					
					indexbr <= 8'b0;
					indexbr_val <= 1'b0;
					
					indexcr <= 8'b0;
					indexcr_val <= 1'b0;

					msgr <= 64'b0;
					msgr_val <= 1'b0;
					lastmsgr_val <= 1'b0;
				end
			endcase
		end
	end
	
	// msgn,msgn_val,lastmsgn_val;
	assign msgn = msgr;
	assign msgn_val = msgr_val;
	assign lastmsgn_val = lastmsgr_val;
	
endmodule
