`timescale 1ns / 1ps
/*
使用场景分析：
64-448：输入，存储S/E'，unpack
		尾部数据，直接连接ram，做成连续输出形式，末64+首64，连续出，outdata接buffer，控制val
		S，E‘，麻烦，需要增添en，截断64处en生效，首64出的时候直接输入到最前端
------：可能存有的问题：1.硬件开销大，2.大小端序出现问题		


*/
module bidirectional_fifo(
    input clk,
    input rstn,

    input mode, // 0:448->64; 1:64->448;

    // 448-->64,
    input  [447:0] data_448_in,
    input          wr_en_448,
    output reg     full_448,

    input          rd_en_64,
    output [63:0]  data_64_out,
    output reg     data_64_out_val,
    output reg     empty_64,

    // 64-->448;
    input  [63:0]  data_64_in,
    input          wr_en_64,

    // 新增：突发结束/提前输出标志（与最后一个64同周期给）
    input          last_en_64,

    output [447:0] data_448_out,
    output reg     data_448_out_val
);

    // Intermediate;
    localparam RECEIVE = 1'b0;
    localparam OUTPUT  = 1'b1;

    reg CS;
    reg NS;

    reg [447:0] buffer;
    reg [2:0]   wr_cnt;
    reg [2:0]   rd_cnt;

    // CS;
    always @(posedge clk or negedge rstn) begin
        if(~rstn)
            CS <= RECEIVE;
        else
            CS <= NS;
    end

    // NS;
    always @(*) begin
        case(CS)
            RECEIVE: begin
                if(mode == 0) begin
                    NS = (wr_cnt == 0 && wr_en_448) ? OUTPUT : RECEIVE;
                end else begin
                    // mode==1：满7个 或 last_en_64 提前flush -> 下一周期OUTPUT
                    NS = (wr_en_64 && (wr_cnt == 3'd6 || last_en_64)) ? OUTPUT : RECEIVE;
                end
            end

            OUTPUT: begin
                if(mode == 0) begin
                    NS = (rd_cnt == 3'd6 && rd_en_64) ? RECEIVE : OUTPUT;
                end else begin
                    // mode==1：输出只维持1个周期（自动输出，无需rd_en_448）
                    NS = RECEIVE;
                end
            end
        endcase
    end

    // buffer, wr_cnt, rd_cnt;
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            buffer <= 448'b0;
            wr_cnt <= 3'b0;
            rd_cnt <= 3'b0;
        end else begin
            // -------- 448->64 原逻辑保留 --------
            if(mode == 0) begin
                case(CS)
                    RECEIVE: begin
                        buffer <= wr_en_448 ? data_448_in : buffer;
                    end
                    OUTPUT: begin
                        buffer <= rd_en_64 ? ({buffer[383:0], buffer[447:384]}) : buffer;
                        rd_cnt <= rd_en_64 ? ((rd_cnt == 3'd6) ? 3'b0 : (rd_cnt + 1'b1)) : rd_cnt;
                    end
                endcase
            end

            // -------- 64->448 新逻辑：连续输入 + 可flush --------
            else begin
                // 只要 wr_en_64=1，不管CS处于RECEIVE/OUTPUT，都把输入吞掉（实现无气泡连续）
                if(wr_en_64) begin
                    // 每个包的第1个word：清高位，保证flush时高位补0且不会残留上一个包的数据
                    if(wr_cnt == 3'd0)
                        buffer <= {384'b0, data_64_in};
                    else
                        buffer <= (buffer << 64) | data_64_in;

                    // 计数：满7个 或 last_en_64 flush -> 归零开始下一个包
                    if(wr_cnt == 3'd6 || last_en_64)
                        wr_cnt <= 3'd0;
                    else
                        wr_cnt <= wr_cnt + 1'b1;
                end
            end
        end
    end

    // full_448;
    always @(posedge clk or negedge rstn) begin
        if(~rstn)
            full_448 <= 1'b0;
        else if(mode == 0 && wr_cnt == 0 && wr_en_448== 1'b1)
            full_448 <= 1'b1;
        else if(mode == 0 && rd_cnt == 6 && rd_en_64 == 1'b1)
            full_448 <= 1'b0;
        else
            full_448 <= full_448;
    end

    // empty_64;
    always @(posedge clk or negedge rstn) begin
        if(~rstn)
            empty_64 <= 1'b1;
        else if(mode == 0 && rd_cnt == 6 && rd_en_64 == 1'b1)
            empty_64 <= 1'b1;
        else if(mode == 0 && wr_cnt == 0 && wr_en_448== 1'b1)
            empty_64 <= 1'b0;
        else
            empty_64 <= empty_64;
    end

    // data_64_out;
    assign data_64_out = buffer[63:0];

    // data_64_out_val;
    always @(posedge clk) data_64_out_val <= (rd_en_64 && full_448) ? 1'b1 : 1'b0;

    // data_448_out;
    assign data_448_out = buffer;

    // data_448_out_val：mode==1时，OUTPUT周期打一拍脉冲（自动输出下一周期）
    always @(posedge clk or negedge rstn) begin
        if(~rstn)
            data_448_out_val <= 1'b0;
        else
            data_448_out_val <= (mode == 1'b1 && CS == OUTPUT);
    end

endmodule





/*
module bidirectional_fifo(
	input clk,
	input rstn,
	
	input mode, // 0:448->64; 1:64->448;
	
	// 448-->64,
	input [447:0] data_448_in,
	input wr_en_448,
	output reg full_448,
	
	input rd_en_64,
	output [63:0] data_64_out,
	output reg data_64_out_val,
    output reg empty_64,
	
	// 64-->448;
	input [63:0] data_64_in,
    input wr_en_64,
//  output reg full_64,
    
//	input rd_en_448,
    output [447:0] data_448_out,
	output reg data_448_out_val
//    output reg empty_448
    );
	
	// Intermediate;
	localparam RECEIVE = 1'b0;
	localparam OUTPUT = 1'b1;
	
	reg CS;
	reg NS;
	
	reg [447:0] buffer;
	reg [2:0] wr_cnt;
	reg [2:0] rd_cnt;
	
	// CS;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			CS <= 1'b0;
		else
			CS <= NS;
	end
	
	// NS;
	always @(*) begin
		case(CS)
			1'b0: begin
				if(mode == 0)
					NS <= (wr_cnt == 0 && wr_en_448)? OUTPUT : RECEIVE;
				else
					NS <= (wr_cnt == 6 && wr_en_64) ? OUTPUT : RECEIVE;
			end 
			1'b1: begin
				if(mode == 0)
					NS <= (rd_cnt == 6 && rd_en_64) ? RECEIVE : OUTPUT;
				else
					NS <= (wr_en_64				   )? RECEIVE : OUTPUT;
				
			end
		endcase
	end
	
	// buffer, wr_cnt, rd_cnt;
	always @(posedge clk or negedge rstn) begin
		if(~rstn) begin
			buffer <= 448'b0;
			wr_cnt <= 3'b0;
			rd_cnt <= 3'b0;
		end else begin
			case(CS)
				1'b0: begin
					if(mode == 0) begin
						buffer <= wr_en_448? data_448_in : buffer;
					end else begin
						buffer <= wr_en_64 ? ((buffer << 64) | data_64_in) : buffer;
						wr_cnt <= wr_en_64 ? ((wr_cnt == 6) ? 3'b0 : (wr_cnt + 1'b1)) : wr_cnt;
					end
				end
				1'b1: begin
					if(mode == 0) begin
						buffer <= rd_en_64 ? ({buffer[383:0], buffer[447:384]}) : buffer;
						rd_cnt <= rd_en_64 ? ((rd_cnt == 6) ? 3'b0 : (rd_cnt + 1'b1)): rd_cnt;
					end else begin
						buffer <= wr_en_64 ? ((buffer << 64) | data_64_in) : buffer;
					end
				end
			endcase
		end
	end
	
	// full_448;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			full_448 <= 1'b0;
		else if(mode == 0 && wr_cnt == 0 && wr_en_448== 1'b1)
			full_448 <= 1'b1;
		else if(mode == 0 && rd_cnt == 6 && rd_en_64 == 1'b1)
			full_448 <= 1'b0;
		else
			full_448 <= full_448;
	end
	
	// empty_64;
	always @(posedge clk or negedge rstn) begin
		if(~rstn)
			empty_64 <= 1'b1;
		else if(mode == 0 && rd_cnt == 6 && rd_en_64 == 1'b1)
			empty_64 <= 1'b1;
		else if(mode == 0 && wr_cnt == 0 && wr_en_448== 1'b1)
			empty_64 <= 1'b0;
		else
			empty_64 <= empty_64;
	end
	
	// data_64_out;
	assign data_64_out = buffer[63:0];
	
	// data_64_out_val;
	always @(posedge clk) data_64_out_val <= (rd_en_64 && full_448) ? 1'b1 : 1'b0;
	
	
	
	// data_448_out;
	assign data_448_out = buffer;
	
	// data_448_out_val;
	always @(*) data_448_out_val <= (CS == 1'b1);
	
endmodule
*/