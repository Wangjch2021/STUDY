`timescale 1ns / 1ps
module Frodo_top
(   input wire clk_p,
    input wire clk_n,
    input wire rstn,
    input wire [1:0] sec_lvl,
    input wire [1:0] mode,
    input wire swtich,
    output valid
);

wire        clk;
wire        locked;

//pack
reg  [63:0] packIn;
wire [63:0] packOut;
wire        packIn_val;
wire        packOut_val;
//unpack
wire [63:0] unpackIn;
wire [63:0] unpackOut;
wire        unpackIn_val;
wire        unpackOut_val;
wire        unpack_full;
//encode
wire [63:0] encode_in;
wire        encode_inval;
wire [63:0] encode_out;
wire        encode_outval;
wire        encode_en;
//decode
wire [63:0] decode_in;
wire        decode_inval;
wire [63:0] decode_out;
wire        decode_outval;
wire        decode_ready;     
//fifo
wire [1:0]   fifo_mode;
wire [447:0] fifo_data_448_in;
wire         fifo_wr_en_448;
wire         fifo_full_448;
wire         fifo_rd_en_64;
wire [63:0]  fifo_data_64_out;
wire         fifo_data_64_out_val;
wire         fifo_empty_64;
wire  [63:0] fifo_data_64_in;
wire         fifo_wr_en_64;
wire         fifo_last_en_64;
wire [447:0] fifo_data_448_out;
wire         fifo_data_448_out_val;
//sample
wire [63:0]  sample_in;
wire [63:0]  sample_out;    
//hash
wire         hash_mode;
reg  [63:0]  hash_in;
wire         msg_val;
wire         lastmsg_val;
wire [7:0]   indexa;
wire         indexa_val;
wire [7:0]   indexb;
wire         indexb_val;      
wire [2:0]   padflag;
wire [8:0]   sqzcnt;
wire         sqzout64_en;
wire         sqzout448_en;
wire [63:0]  sqzout64;
wire [447:0] sqzout448;
wire         sqzout64_val;
wire         sqzout448_val;
wire         hash_done;   
wire         onehash_val;
//add
wire [447:0] adda;
wire [447:0] addb;
wire [447:0] sum;
//sub
wire [63:0] suba;
wire [63:0] subb;
wire [63:0] diff;
//mac
wire [15:0]  ma0mula;
wire [447:0] ma0mulb;
wire [447:0] ma0addc;   
wire [447:0] muladd0;
//mac inner
wire [447:0] ma1mula;
wire [447:0] ma1mulb;
wire [63:0]  ma1addc;   
wire [63:0]  muladd1;


//伪双端口ram，一个地址专读，一个地址专写；定0读，1写
wire [8:0]   addr_448ramr;
wire [8:0]   addr_448ramw;
wire [12:0]  addr_64ramb0;
wire [12:0]  addr_64ramb1;
wire [11:0]  addr_64rama0;
wire [11:0]  addr_64rama1;

wire         we_448ram ;
wire         we_64ramb0;
wire         we_64ramb1;
wire         we_64rama0;                            
wire         we_64rama1;
//实际上会让一些口闲置
reg  [63:0]  din_ram64a0;
wire [63:0]  dout_ram64a0;
wire [63:0]  din_ram64a1;
wire [63:0]  dout_ram64a1;
reg  [63:0]  din_ram64b0;
wire [63:0]  dout_ram64b0;
reg  [63:0]  din_ram64b1;
wire [63:0]  dout_ram64b1;
wire [447:0] din_ram448;
wire [447:0] dout_ram448;     





//--------------------------------------------------------数据通路连线
    wire  [1:0]  packinsel;         //0-64a 1-64b 2-fifo64out
    wire         unpackinsel;       //0-64a 1-64b
    wire         fifo_data_64_insel;//0-外部 1-hash64out
    wire  [1:0]  hash_insel;        //0-64a 1-64b 2-fifo64out  
    wire         addsel;           //0-hashout 1-ram448out     
    wire         ma0mulasel;        //0-hashout 1-ram64a  
    wire  [2:0]  din_ram64a0sel;
    wire  [2:0]  din_ram64b0sel;  



    //--sample 仅hash64out
        assign sample_in = sqzout64;
    //--encode 仅μ，ram64b0
        assign encode_in = dout_ram64b0;
    //--decode 仅M，ram64a0
        assign decode_in = dout_ram64a0;
    //pack，B，B’，C ram64a0和ram64b0和Fifo64out            
        always@(*)begin
            case(packinsel)
                2'b00: packIn = dout_ram64a0;
                2'b01: packIn = dout_ram64b0;
                2'b10: packIn = fifo_data_64_out;
                2'b11: packIn = fifo_data_64_out;
             default:;
            endcase    
        end
    //unpack，Bb，B‘c0，Cc1，ram64a0和ramb0
        assign unpackIn = packinsel? dout_ram64a0 : dout_ram64b0;
    //fifo64in:S，E’，外部，hash64out和din
        assign fifo_data_64_in = fifo_data_64_insel ? sqzout64 : dout_ram64a0;
    //fifo448:B,ram448out
        assign fifo_data_448_in = dout_ram448;
    //hash，ram64a,64b,fifo64out
        always@(*)begin
            case(hash_insel)
                2'b00: hash_in = dout_ram64a0;
                2'b01: hash_in = dout_ram64b0;
                2'b10: hash_in = fifo_data_64_out;
                2'b11: hash_in = fifo_data_64_out;
                default:;
            endcase    
        end
    //RAM448
    assign din_ram448 = fifo_data_448_out;
    
    //RMA64a,b
    
    always@(*)begin
        case(din_ram64a0sel)
                3'd0:din_ram64b0 =  dout_ram64a0;
                3'd1:din_ram64b0 =  sqzout64;
                3'd2:din_ram64b0 =  packOut;
                3'd3:din_ram64b0 =  unpackOut;
                3'd4:din_ram64b0 =  fifo_data_64_out;
                3'd5:din_ram64b0 =  muladd1;
            default:din_ram64a0 = 64'd0;
        endcase
    end
    
    always@(*)begin
        case(din_ram64b0sel)
                //3'd0:din_ram64b0 =  data_in;
                3'd1:din_ram64b0 =  sqzout64;
                3'd2:din_ram64b0 =  packOut;
                3'd3:din_ram64b0 =  unpackOut;
                3'd4:din_ram64b0 =  fifo_data_64_out;
                3'd5:din_ram64b0 =  muladd1;
            default:din_ram64b0 = 64'd0;
        endcase
    end
    
    

    //MAC部分
    assign    ma1mula = dout_ram448;
    assign    ma1mulb = addsel ? dout_ram448 : sqzout448;
    assign    ma1addc = dout_ram64a0;

    reg [63:0] shift64a;
    wire       shift64out;
    wire       shift64inen;
    wire       shift16outen; 
    wire[63:0] shift64in; 

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            shift64a <= 64'd0;
        else if(shift64inen)
            shift64a <= shift64in;
        else if(shift16outen) 
            shift64a <= {shift64a[47:0],16'd0};
        else
            shift64a <= shift64a;         
    end

    assign ma0mula = addsel ? {384'd0,dout_ram64a0} : sqzout448;   
    assign ma0mulb = dout_ram64b0;
    assign ma0addc = dout_ram64b1;

    assign adda    = muladd0;
    assign addb    = dout_ram64a0;
 
    
    assign suba = muladd1;
    assign subb = dout_ram64a0;
    



//--------------------------------------------------------数据遍历对比部分控制


(* dont_touch = "true" *) PackSet u_PackSet(
    .clk        ( clk        ),
    .rstn       ( rstn       ),
    .sec_lvl    ( sec_lvl    ),
    .packIn     ( packIn     ),
    .packIn_val ( packIn_val ),
    .packOut    ( packOut    ),
    .packOut_val  ( packOut_val  )
);


(* dont_touch = "true" *) UnpackSet u_UnpackSet(
    .clk           ( clk           ),
    .rstn          ( rstn          ),
    .sec_lvl       ( sec_lvl       ),
    .unpackIn      ( unpackIn      ),
    .unpackIn_val  ( unpackIn_val  ),
    .unpackOut     ( unpackOut     ),
    .unpackOut_val ( unpackOut_val ),
    .full          ( unpack_full   )
);



(* dont_touch = "true" *) EncodeSet u_EncodeSet(
    .clk       ( clk       ),
    .rstn      ( rstn      ),
    .sec_lvl   ( sec_lvl   ),
    .msg       ( encode_in       ),
    .msg_val   ( encode_in_val   ),
    .en        ( encode_en        ),
    .encodeOut ( encode_out ),
    .encodeOut_val  ( encode_outval  )
);


(* dont_touch = "true" *) DecodeSet u_DecodeSet(
    .clk       ( clk       ),
    .rstn      ( rstn      ),
    .sec_lvl   ( sec_lvl   ),
    .msg       ( decode_in       ),
    .msg_val   ( decode_inval   ),
    .ready     ( decode_ready     ),
    .decodeOut ( decode_out ),
    .decodeOut_val  ( decode_outval  )
);

(* dont_touch = "true" *) bidirectional_fifo u_bidirectional_fifo(
    .clk             ( clk             ),
    .rstn            ( rstn            ),
    .mode            ( fifo_mode            ),
    .data_448_in     ( fifo_data_448_in     ),
    .wr_en_448       ( fifo_wr_en_448       ),
    .full_448        ( fifo_full_448        ),
    .rd_en_64        ( fifo_rd_en_64        ),
    .data_64_out     ( fifo_data_64_out     ),
    .data_64_out_val ( fifo_data_64_out_val ),
    .empty_64        ( fifo_empty_64        ),
    .data_64_in      ( fifo_data_64_in      ),
    .wr_en_64        ( fifo_wr_en_64        ),
    .last_en_64      ( fifo_last_en_64      ),
    .data_448_out    ( fifo_data_448_out    ),
    .data_448_out_val( fifo_data_448_out_val  )
);

(* dont_touch = "true" *) SampleMatrixSet#(
    .PARALLEL_NUM ( 4 )
)u_SampleMatrixSet(
    .smInSet ( sample_in ),
    .sec_lvl ( sec_lvl ),
    .smOutSet  ( sample_out  )
);

(* dont_touch = "true" *) SHAKE u_SHAKE(
    .clk           ( clk           ),
    .rstn          ( rstn          ),
    .model_sel     ( hash_mode     ),
    .msg           ( msg           ),
    .msg_val       ( msg_val       ),
    .lastmsg_val   ( lastmsg_val   ),
    .indexa        ( indexa        ),
    .indexa_val    ( indexa_val    ),
    .indexb        ( indexb        ),
    .indexb_val    ( indexb_val    ),
    .padflag       ( padflag       ),
    .sqzcnt        ( sqzcnt        ),
    .onehash_val   ( onehash_val   ),
    .sqzout64_en   ( sqzout64_en   ),
    .sqzout64      ( sqzout64      ),
    .sqzout64_val  ( sqzout64_val  ),
    .sqzout448_en  ( sqzout448_en  ),
    .sqzout448     ( sqzout448     ),
    .sqzout448_val ( sqzout448_val ),
    .done          ( done          )
);


(* dont_touch = "true" *)RAM64a uRAM64a (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(we_ram64a0),      // input wire [0 : 0] wea
  .addra(addr_ram64a0),  // input wire [11 : 0] addra
  .dina(din_ram64a0),    // input wire [63 : 0] dina
  .douta(dout_ram64a0),  // output wire [63 : 0] douta
  .clkb(clk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(we_ram64a1),      // input wire [0 : 0] web
  .addrb(addr_ram64a1),  // input wire [11 : 0] addrb
  .dinb(din_ram64a1),    // input wire [63 : 0] dinb
  .doutb(dout_ram64a1)  // output wire [63 : 0] doutb
);

(* dont_touch = "true" *)RAM64b uRAM64b (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(we_64b0),      // input wire [0 : 0] wea
  .addra(addr_ram64b0),  // input wire [11 : 0] addra
  .dina(din_ram64b0),    // input wire [63 : 0] dina
  .douta(dout_ram64b0),  // output wire [63 : 0] douta
  .clkb(clk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(we_64b1),      // input wire [0 : 0] web
  .addrb(addr_ram64b1),  // input wire [11 : 0] addrb
  .dinb(dout_ram64b1),    // input wire [63 : 0] dinb
  .doutb(dout_ram64b1)  // output wire [63 : 0] doutb
);


(* dont_touch = "true" *)RAM448 uRAM448 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(we_ram448),      // input wire [0 : 0] wea
  .addra(addr_448ramw),  // input wire [9 : 0] addra
  .dina(dina),    // input wire [447 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .addrb(addr_448ramr),  // input wire [9 : 0] addrb
  .doutb(doutb)  // output wire [447 : 0] doutb
);


(* dont_touch = "true" *) MatrixAddSet#(
    .PARALLEL_NUM ( 28 )
)u_MatrixAddSet(
    .addaSet ( adda ),
    .addbSet ( addb ),
    .addabSet  ( sum  )
);

(* dont_touch = "true" *) MatrixMACSet#(
    .PARALLEL_NUM ( 28 )
)u_MatrixMACSet(
    .clk          ( clk          ),
    .rstn         ( rstn         ),
    .mulaSet      ( mulaSet      ),
    .mulbSet      ( mulbSet      ),
    .addcSet      ( addcSet      ),
    .mulabSet_val ( mulabSet_val ),
    .macabSet     ( macabSet     ),
    .macabSet_val  ( macabSet_val  )
);


(* dont_touch = "true" *) MatrixMulAddSet#(
    .PARALLEL_NUM ( 28 )
)u_MatrixMulAddSet(
    .mulaSet ( mulaSet ),
    .mulbSet ( mulbSet ),
    .addcSet ( addcSet ),
    .result  ( result  )
);

(* dont_touch = "true" *) MatrixSubSet#(
    .PARALLEL_NUM ( 4 )
)u_MatrixSubSet(
    .subaSet ( suba ),
    .subbSet ( subb ),
    .subabSet  ( diff )
);


clk_wiz_0 pll
   (
    // Clock out ports
    .clk_out1(clk),     // output clk_out1
    // Status and control signals
    .reset(rstn), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1_p(clk_p),    // input clk_in1_p
    .clk_in1_n(clk_n)    // input clk_in1_n
);



(* dont_touch = "true" *) control u_control(
    .clk                ( clk                ),
    .rstn               ( rstn               ),
    .sec_lvl            ( sec_lvl            ),
    .opermode           ( mode           ),
    .start              ( swtich              ),

    .addr_448ramr       ( addr_448ramr         ),
    .addr_448ramw       ( addr_448ramw       ),
    .addr_64ramb0       ( addr_64ramb0       ),
    .addr_64ramb1       ( addr_64ramb1       ),
    .addr_64rama0       ( addr_64rama0       ),
    .addr_64rama1       ( addr_64rama1       ),
    .we_448ram          ( we_448ram          ),
    .we_64ramb0         ( we_64ramb0         ),
    .we_64ramb1         ( we_64ramb1         ),
    .we_64rama0         ( we_64rama0         ),
    .we_64rama1         ( we_64rama1         ),
    .decode_ival        ( decode_ival        ),
    .decode_ready       ( decode_ready       ),
    .decode_oval        ( decode_oval        ),
    .encode_msg_val     ( encode_msg_val     ),
    .encode_en          ( encode_en          ),
    .encodeOut_val      ( encodeOut_val      ),
    .pack_ival          ( pack_ival          ),
    .pack_oval          ( pack_oval          ),
    .unpackIn_val       ( unpackIn_val       ),
    .unpackOut_val      ( unpackOut_val      ),
    .unpack_full        ( unpack_full        ),
    .fifo_mode          ( fifo_mode          ),
    .fifo_last_en_64    ( fifo_last_en_64    ),
    .full_448           ( full_448           ),
    .empty_64           ( empty_64           ),
    .fifo_wr_en_448     ( fifo_wr_en_448     ),
    .fifo_rd_en_64      ( fifo_rd_en_64      ),
    .fifo_wr_en_64      ( fifo_wr_en_64      ),
    .fifo_64_out_val    ( fifo_64_out_val    ),
    .fifo_448_out_val   ( fifo_448_out_val   ),
    .shakedone          ( shakedone          ),
    .onehash_val        ( onehash_val        ),
    .sqzout64_val       ( sqzout64_val       ),
    .sqzout448_val      ( sqzout448_val      ),
    .shake_model_sel    ( shake_model_sel    ),
    .msg_val            ( msg_val            ),
    .lastmsg_val        ( lastmsg_val        ),
    .indexa             ( indexa             ),
    .indexa_val         ( indexa_val         ),
    .indexb             ( indexb             ),
    .indexb_val         ( indexb_val         ),
    .padflag            ( padflag            ),
    .sqznum             ( sqznum             ),
    .sqzout64_en        ( sqzout64_en        ),
    .sqzout448_en       ( sqzout448_en       ),
    .work_done          ( valid          )
);





endmodule

