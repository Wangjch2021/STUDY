//内嵌 inst rom 输出指令 控制指令的跳转
module control (
    input               clk,
    input               rstn,

    input       [1:0]   sec_lvl         ,
    input       [1:0]   opermode        ,   

    input               start           ,
    
    /*
    //io data
    input               data_ival,
    output              data_iready,
    output              data_oval, 
    */
    //ram 
    output      [8:0]   addr_448ramr    ,
    output      [8:0]   addr_448ramw    ,
    output      [12:0]  addr_64ramb0    ,
    output      [12:0]  addr_64ramb1    ,  
    output      [11:0]  addr_64rama0    ,
    output      [11:0]  addr_64rama1    ,

    output              we_448ram       ,
    output              we_64ramb0      ,
    output              we_64ramb1      ,
    output              we_64rama0      ,                            
    output              we_64rama1      ,
    
    //decode
    output reg          decode_ival     ,
    input               decode_ready    ,//decode新增ready信号
    input               decode_oval     ,

    //encode
    output reg          encode_msg_val  ,
	output reg          encode_en       ,

	input               encodeOut_val   ,                 
    //pack
	output reg          pack_ival       ,
	input               pack_oval       ,

    //unpack
    output reg          unpackIn_val    ,
    input               unpackOut_val   ,
    input               unpack_full     ,//unapck新增full信号
	
    //fifo
    output reg          fifo_mode       ,//0:448->64; 1:64->448;
	output reg          fifo_last_en_64 ,//64-448通路新增en信号

    input               full_448        ,//只有448-64通路有状态辛信号
	input               empty_64        ,

	output reg          fifo_wr_en_448  ,
	output reg          fifo_rd_en_64   ,
	output reg          fifo_wr_en_64   ,
	
	input               fifo_64_out_val ,
	input               fifo_448_out_val,

    //shake
	input               shakedone       ,//总hash做完
    input               onehash_val     ,//一次keccak做完
    input               sqzout64_val    ,
    input               sqzout448_val   ,   

    output reg          shake_model_sel ,	

	output reg          msg_val         ,
	output reg          lastmsg_val     ,


	output reg  [7:0]   indexa          ,
	output reg          indexa_val      ,
	output reg  [7:0]   indexb          ,
	output reg          indexb_val      ,

	output     [2:0]    padflag         ,
    output     [8:0]    sqznum          ,

	output reg          sqzout64_en     ,
	output reg          sqzout448_en    ,


    output  [1:0]  packinsel,
    output         unpackinsel,
    output         fifo_data_64_insel,
    output  [1:0]  hash_insel, 
    output         addsel,     
    output         ma0mulasel,
    output  [2:0]  din_ram64a0sel,
    output  [2:0]  din_ram64b0sel,  



    //done

    output              work_done//一个算法结束
    
    );

//----------------------------------------------

    wire shake_lvl = sec_lvl[0] ? 1'b0: 1'b1;
    
    wire [2:0] agumode = {sec_lvl[0],opermode};




/////FSM常量组 
    parameter WAIT   = 4'b0000;
    parameter DIN    = 4'b0001;    
    parameter DOUT   = 4'b0010;
    parameter ABS    = 4'b0011;
    parameter RUN    = 4'b0100;
    parameter SQZ    = 4'b0101;   
    parameter MAT64  = 4'b0110;
    parameter MAT448 = 4'b0111;
    parameter MATEpp = 4'b1000;
    parameter PACK   = 4'b1001;
    parameter UNPACK = 4'b1010;
/*    parameter MAC0   = 4'b1011;      
    parameter MAC1   = 4'b1100; 
    parameter MAC2   = 4'b1101; 
    parameter MAC3   = 4'b1110; */
    parameter unpack = 4'b1110;
    parameter MATCAL = 4'b1101;
    parameter DONE   = 4'b1100;
    parameter DECODE = 4'b1111;


    reg     [2:0]  state,state_nxt;
    reg     [3:0]  substate,substate_nxt;
    reg            fifoin448;




//===========================================================================================================================================
//解码器输出与输入信号(重要)
    //输入
        
        reg   instdecoder_en;//算法的第一条指令，解码器启动
        reg   ex_done       ;//外部工作结束信号  
        reg   reg_clr       ;//一次指令结束，解码器内部寄存器清零
        reg   addr_load     ;//a通路地址切换  
        

    //输出

        wire   [35:0]  inst_all ; 
        wire   encode_done      ;//一个解码工作结束,开始ex
        //wire   work_done      ; 
        wire   opcode           ;
        wire   addr_rd_num      ;//切换地址中几个读地址
        wire   addr_run_num     ;//几个切换地址  
        wire   width448         ;//是否448参与
        wire   [8:0] string0    ;//S，E‘，在第几个大cnt位置填充          
        wire   [2:0] addr_cnt   ;//当前正在操作第几个地址 
        //wire   [8:0] sqznum     ;//挤压次数

        //待添加逻辑的输出--------------重要
            //wire [7:0] indexa
            //wire [7:0] indexb
            wire   [1:0] hash_index ;//00不用，01indexb情况1，11情况2，10indexa 
            wire   hash_lvl         ;//hashlvl 
            //wire   [2:0] padflag    ;


        wire    [7:0]     prefixa;
        wire    [7:0]     prefixb;
        wire    [3:0]     prefixc;
        wire    [3:0]     prefixd;
        wire    [12:0]    addrbasea;
        wire    [12:0]    addrbaseb;
        wire    [12:0]    addrbasec;
        wire    [12:0]    addrbased;
        wire    [8:0]     ADDRa_skip0; 
        wire    [8:0]     ADDRa_skip1; 
        wire    [8:0]     ADDRb_skip0; 
        wire    [8:0]     ADDRb_skip1; 
        wire    [8:0]     ADDRc_skip0; 
        wire    [8:0]     ADDRc_skip1; 
        wire    [8:0]     ADDRd_skip0; 
        wire    [8:0]     ADDRd_skip1; 
        wire    [12:0]    aloop0_max;
        wire    [12:0]    aloop1_max;
        wire    [12:0]    aloop2_max;
        wire    [12:0]    aloop3_max;
        wire    [12:0]    bloop0_max;
        wire    [12:0]    bloop1_max;
        wire    [12:0]    bloop2_max;
        wire    [12:0]    bloop3_max;
        wire    [12:0]    cloop0_max;
        wire    [12:0]    cloop1_max;
        wire    [12:0]    cloop2_max;
        wire    [12:0]    cloop3_max;
        wire    [12:0]    dloop0_max;
        wire    [12:0]    dloop1_max;
        wire    [12:0]    dloop2_max;
        wire    [12:0]    dloop3_max;
        wire   aloop0full;
        wire   aloop1full;
        wire   aloop2full;
        wire   aloop3full;
        wire   bloop0full;
        wire   bloop1full;
        wire   bloop2full;
        wire   bloop3full;
        wire   cloop0full;
        wire   cloop1full;
        wire   cloop2full;
        wire   cloop3full;
        wire   dloop0full;
        wire   dloop1full;
        wire   dloop2full;
        wire   dloop3full;


    ////addrgen引出信号
    wire    loopamaxval;//本周期其loopmax达到
    wire    loopbmaxval;
    wire    loopcmaxval;
    wire    loopdmaxval;

    wire    we0;
    wire    we1;
    wire    we2;
    wire    we3;
    
//===========================================================================================================================================
    wire    data_ival   = inst_all[35:31] == 4'b0001;
    wire    ABS448      = inst_all[35:31] == 4'b1010;
    
    assign  packinsel    = inst_all[6:5];
    assign  unpackinsel  = inst_all[7];
    assign  fifo_data_64_insel =  inst_all[8];
    assign  hash_insel   = inst_all[11:10];
    assign  addsel       = inst_all[9];     
    assign  ma0mulasel   = inst_all[9];  
    assign  din_ram64a0sel = inst_all[20:18]; 
    assign  din_ram64b0sel = inst_all[20:18];  
//===========================================================================================================================================



//===========================================================================================================================================
    //受限于语法，必须放置在前的控制信号们

    reg          ABS_448;//标记吸收的数据来自于448宽度经fifo

    reg          addrd_add_r;
    reg    [4:0] abs_cnt;
    reg    [4:0] abs_cnt_max;
    reg    [4:0] sqz_cnt;


////----3.子状态跳转
//----3.1跳出条件统一单独控制
    wire    DI_done     =  aloop0_max ;//即使带了FIFO最后也一定会存入一次导致ADDR+1
    //wire    DO_done     =  width448 ? (loopamaxval_r_r && empty_64) : aloop0max;//带FIFO时需要保证最后一个FIFO输出完
    wire    DO_done     =  width448 ? (aloop0_max && empty_64) : aloop0_max;//带FIFO时需要保证最后一个FIFO输出完
    wire    PACK_done   =  loopbmaxval;//用b存储写地址让写地址满就够了
    wire    UNPACK_done =  loopbmaxval;//同样存储写地址满了就够了
    wire    ABS_done    =  lastmsg_val || abs_cnt == abs_cnt_max;
    
    //
    wire    RUN_done    =  onehash_val;
    wire    SQZ_done    =   onehash_val;
    wire    MAT64_done  =   aloop0_max;
    wire    MAT448_done =   aloop0_max;
    wire    MATCAL_done =   bloop0_max;
    //
    wire    MATEpp_done =   aloop0_max;
    wire    DECODE_done =   aloop0_max;

//----3.2具体状态机
    always @(posedge clk or negedge rstn) begin
        if(!rstn)begin
            substate <= 0;
        end
        else begin
            substate <= substate_nxt;
        end
    end

    
    always@(*) begin
        substate_nxt = WAIT;  
        case(substate)
            WAIT:begin
                    if(encode_done)begin
                        case(opcode)
                            4'b0001: substate_nxt = DIN;
                            4'b0010: substate_nxt = DOUT;
                            4'b0011: substate_nxt = ABS;
                            4'b0100: substate_nxt = ABS;
                            4'b0110: substate_nxt = ABS;
                            4'b0101: substate_nxt = ABS;
                        default:substate_nxt = WAIT;
                        endcase
                    end
                    else
                        substate_nxt = WAIT;
                    end
            DIN:begin
                    if(DI_done)
                        substate_nxt = DONE;
                    else
                        substate_nxt = DIN;            
                    end   
            DOUT:begin
                    if(DO_done)
                        substate_nxt = DONE;
                    else
                        substate_nxt = DOUT;   
                    end
            PACK:begin
                    if(PACK_done)
                        substate_nxt = DONE;
                    else
                        substate_nxt = PACK;   
            end
            UNPACK:begin
                    if(UNPACK_done)
                        substate_nxt = DONE;
                    else
                        substate_nxt = UNPACK;   
            end
            DECODE:begin
                     if(UNPACK_done)
                        substate_nxt = DONE;
                    else
                        substate_nxt = DECODE;   
            end
            ABS:begin
                //ABS永远是第一个工作状态，分为短入，长入，长入下只可能在第一个数据块携带fifo
                //跳出永远是去RUN
                    if(ABS_done)
                        substate_nxt = RUN;
                    else
                        substate_nxt = ABS;        
            end
            RUN:begin//后会接ABS，SQZ,64,448,
                    if(onehash_val)begin
                        if(addr_cnt <= addr_rd_num)begin
                            case(opcode)
                                4'b0011:substate_nxt = SQZ;
                                4'b0110:substate_nxt = SQZ;               
                                4'b0100:substate_nxt = MAT448;
                                4'b0101:substate_nxt = MAT64;
                                default:substate_nxt = RUN; 
                            endcase
                        end    
                        else
                        substate_nxt = ABS; 
                    end
                    else 
                        substate_nxt = RUN;       
                    end
            SQZ:begin
                    if(SQZ_done)
                        substate_nxt = DONE;
                    else
                        substate_nxt = SQZ;     
                    end
            MAT448:begin
                    if(MAT448_done)begin
                        case(opcode)
                            4'b0100: substate_nxt = MAT64;
                            4'b0101: substate_nxt = MATEpp;
                            default:substate_nxt = WAIT;
                        endcase
                    end
                    else
                        substate_nxt = MAT448;         
                    end
            MAT64:begin
                    if(MAT64_done)begin
                        case(opcode)
                            4'b0100: substate_nxt = DONE;
                            4'b0101: substate_nxt = MAT448;
                            default:substate_nxt = WAIT;
                        endcase
                    end
                    else
                        substate_nxt = MAT448;         
                end
            MATEpp:begin
                    if(MATEpp_done)
                        substate_nxt = DONE;
                    else
                        substate_nxt = MATEpp;         
                end
            MATCAL:begin
                    if(MATCAL_done)
                        substate_nxt = DONE;
                    else
                        substate_nxt = MATCAL;
            end
            DONE:begin
                    substate_nxt = WAIT;    
                    end    
            default:substate_nxt = WAIT;
        endcase  
    end
   


///----4.结构各状态下的地址控制在4.1，各模块的控制在后续小节
//----4.1FSM下的地址控制
        reg                 addra_add,addra_add_r,addra_add_r_r;
        reg                 addrb_add,addrb_add_r,addrb_add_r_r;
        reg                 addrc_add,addrc_add_r,addrc_add_r_r;
        reg                 addrd_add;

        reg                 addra_we;
        reg                 addrb_we;
        reg                 addrc_we;
        reg                 addrd_we;

        reg                 addra_load;

    //----4.1.1 地址1的控制 addr we load
        //--状态扩充
        reg decode_cs;

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                decode_cs <= 1'b1;
            else if(cloop0_max)
                decode_cs <= 1'b0;
            else if(substate == MATCAL)
                decode_cs <= 1'b1;
            else
                decode_cs <= decode_cs;
        end 

    always@(*)begin
        addra_add = 1'b0;
        addra_we  = 1'b0;
        if(substate != WAIT)begin
            case(substate)
            DIN:begin
                if(width448)begin//fifo64-448参与工作

                end
                else begin
                    addra_add = data_ival;
                    addra_we  = data_ival;
                end    
            end
            DECODE:begin//输入decode数据的读地址
                if(decode_ready)
                    addra_add = 1'b1;
                else
                    addra_add = 1'b0;    
            end                 
            ABS:begin//abs的流水时序起点
                if(!ABS448)
                    addra_add = (abs_cnt != abs_cnt_max) && (!aloop0_max);
                else
                    addra_add = (abs_cnt != abs_cnt_max) && (!aloop0_max);
            end
            MAT64:begin
                /*if(sqz_cnt != abs_cnt_max)begin//未输出完
                    addra_add = sqzout64_val;
                    addra_we  = sqzout64_val;               
                */if(sqz_cnt != abs_cnt_max  && aloop0_max)begin
                    addra_add = 1'b0;
                    addra_we  = 1'b0;
                    end
                  else begin
                    addra_add = sqzout64_val;
                    addra_we  = sqzout64_val;    
                  end  
                end
            MAT448:begin
                if(sqz_cnt != abs_cnt_max  && aloop0_max)begin
                    addra_add = 1'b0;
                    addra_we  = 1'b0;
                    end
                  else begin
                    addra_add = fifo_448_out_val;
                    addra_we  = fifo_448_out_val;    
                  end  
            end    
            PACK:begin
                if(!width448)begin//仅pack与ram相连
                    if(!aloop0_max)
                        addra_add = 1'b1;
                end
                else begin//pack前有fifo
                    if(!aloop0_max && !fifoin448) 
                        addra_add = 1'b1;           
                end
            end    
            UNPACK:begin
                if(!full_448 && !aloop0_max)
                    addra_add = 1'b1;
            end
            
            endcase
        end
    end

  

    always@(*)begin
        addr_load = 1'b0;
        if(aloop0_max)
        addr_load = 1'b0;
    end


    //----4.1.2 地址2的控制
    always@(*)begin
        addrb_add = 1'b0;
        addrb_we  = 1'b0;
        if(substate != WAIT)begin
            case(substate)
            MAT64:begin//decode输入数据的读地址
                if(decode_cs && !bloop0_max && decode_ready)
                    addrb_add = 1'b1;        
            end
            PACK:begin//pack模块的写地址
                if(!width448)begin
                    if(!bloop0_max)begin
                        addrb_add = pack_oval;
                        addrb_we  = pack_oval;
                    end
                end
                else begin
                    if(!bloop0_max)begin
                        addrb_add = pack_oval;
                        addrb_we  = pack_oval;
                    end
                end            
            end
            UNPACK:begin
                if(!width448)begin
                    if(!bloop0_max)begin
                        addrb_add = unpackOut_val;
                        addrb_we  = unpackOut_val;
                    end
                end
                else begin
                    if(!bloop0_max)begin
                        addrb_add = fifo_448_out_val;
                        addrb_we  = fifo_448_out_val;
                    end
                end
            end


      
            endcase
        end
    end
    //----4.1.3 地址3的控制
    always@(*)begin
        addrc_add = 1'b0;
        addrc_we  = 1'b0;
        if(substate != WAIT)begin
            case(substate)
            MAT64:begin//decode输入数据的读地址
                if(decode_cs)
                    addrc_add = decode_oval;
                    addrc_we  = decode_oval;        
            end
            endcase
        end
    end
    //----4.1.4 地址4的控制
    always@(*)begin
        addrd_add = 1'b0;
        addrd_we  = 1'b0;   
        case(substate)
            MAT448:begin
            if(opcode == 4'b0000 && !dloop0_max)
                addrd_add = 1'b1;    
            end
        endcase
    end



    //----4.1.4 地址4的控制

    //----4.1.5 地址相关信号的打拍
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            addra_add_r <= 1'b0;
            addra_add_r_r<= 1'b0;
        end
        else begin
            addra_add_r   <= addra_add;             
            addra_add_r_r <= addra_add_r;
        end
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            addrb_add_r <= 1'b0;
            addrb_add_r_r<= 1'b0;
        end
        else begin
            addrb_add_r   <= addrb_add;             
            addrb_add_r_r <= addrb_add_r;
        end
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            addrc_add_r <= 1'b0;
            addrc_add_r_r<= 1'b0;
        end
        else begin
            addrc_add_r   <= addrc_add;             
            addrc_add_r_r <= addrc_add_r;
        end
    end



//----4.2 FSM下Decode的控制(decode中确保已经拉出消除地址控制气泡的ready信号)
        //需控制信号 decode_dval 
    /*
    always@(*)begin//一样的信号
        decode_lvl = sec_lvl;
    end
    */
    always@(*)begin
        decode_ival = 1'b0;
        if(decode_cs)
            decode_ival = addrb_add_r;
    end

    





//----4.3 FSM下pack的控制
    //单pack+fifo配套pack
    //首先添加一组流水所用外围计数器
    always@(*)begin
        pack_ival = 1'b0;
        if(substate == PACK)begin
            if(!width448)
                pack_ival = addra_add;
            else
                pack_ival = fifo_64_out_val;
        end
    end





//----4.4 FSM下unpack的控制
    //unpack修改了相关的full信号
    always@(*)begin
        if(substate == unpack)
            unpackIn_val = addra_add;        
    end




//----4.5 FSM下fifo的控制（重要）
    /* 64-448,unpack，S，E’的存储（自动输出）
       448-64，pack，shake 
    */
    
//--4.5.1补充控制寄存器
    //reg fifoin448;//受控于add信号

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            fifoin448 <= 1'b0;
        else if(substate == PACK && width448 && addra_add)
            fifoin448 <= 1'b1;
        else if(empty_64)
            fifoin448 <= 1'b0;
        else
            fifoin448 <= fifoin448;            
    end

//--4.5.2 448-64场景

    always@(*)begin
        fifo_wr_en_448 = 1'b0;
        fifo_rd_en_64  = 1'b0;
        case(substate)
            PACK:begin
                if(width448)
                    fifo_wr_en_448 = addra_add;
                    fifo_rd_en_64  = full_448;
            end
            ABS:begin
                if(ABS448)
                    fifo_wr_en_64 = addra_add_r;
                    //fifo_rd_en_448= !fifo_wr_en_64;
            end
        endcase
    end

    

//--4.5.3 64-448场景
    always@(*)begin
        fifo_wr_en_64 = 1'b0;
        case(substate)
            UNPACK:begin
                if(width448)
                    fifo_wr_en_64 = unpackOut_val;
            end
          
        endcase
    end


    reg  [8:0]   cntstring0; 
    
    always@(*)begin
        fifo_last_en_64 = 1'b0;
        if(string0 == cntstring0)
            fifo_last_en_64 = 1'b1;    
    end




//----4.6 FSM下hash的控制(重要)
    //reg          shake_lvl;
    //reg          pad_flag;
    //reg          indexa_val;
    //reg          indexb_val;
    //reg          msg_val;
    //reg          lastmsg_val;
    //reg  ABS_448;
    reg  ABS_448_cs;//状态扩展

//----4.6.1补充控制计数器
    //reg  [4:0]   abs_cnt;
    //reg  [4:0]   abs_cnt_max;
    //reg  [4:0]   sqz_cnt;
    reg  [1:0]   sqz_cnt448;
    

    always@(*)begin
        if(shake_lvl == 1'b0)
            abs_cnt_max = 5'd21;
        else
            abs_cnt_max = 5'd17;             
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            abs_cnt <= 5'd0;
        else if(abs_cnt == abs_cnt_max)
            abs_cnt <= abs_cnt;   
        else if(onehash_val)
            abs_cnt <= 5'd0;    
        else if(msg_val)
            abs_cnt <= abs_cnt + 1'b1;
        else
            abs_cnt <= abs_cnt;    
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            sqz_cnt <= 5'd0;
        else if(sqz_cnt == abs_cnt_max)  
            sqz_cnt <= sqz_cnt;  
        else if(onehash_val)
            sqz_cnt <= 5'd0;  
        else if(sqzout64_en)    
            sqz_cnt <= sqz_cnt + 1'b1;
        else
            sqz_cnt <= sqz_cnt;
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            cntstring0 <= 9'd0;
        else if(fifo_448_out_val)begin
            if(cntstring0 == string0)
                cntstring0 <= 9'd0;
            else
                cntstring0 <= cntstring0 + 1'b1;         
        end 
        else
            cntstring0 <= cntstring0;     
    end


//----4.6.2输入部分
    
    //index部分
    always@(*)begin
        indexb = 8'd0;
        if(hash_index == 2'b01)
            indexb = 8'H5f;
        else if(hash_index == 2'b11)
            indexb = 8'H9E;
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            indexb_val <= 1'b0;
        else if(substate_nxt == ABS && hash_index[1])//在进入abs第一个周期会拉高一次 
            indexb_val <= 1'b1;
        else
            indexb_val <= 1'b0;       
    end


    always@(*)begin
        lastmsg_val = 1'b0;
        if(substate == ABS && aloop0_max && (addr_cnt == addr_rd_num))
            lastmsg_val = msg_val;      
    end

        
    always@(*)begin
        msg_val = 1'b0;
        if(substate == ABS)begin
            if(!ABS_448)
                msg_val = addra_add_r;
            else
                msg_val = fifo_64_out_val;    
        end
    end
    

    //对于ABS部分fifo参与的标志信号（FIFO参与的abs过程）
    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            ABS_448_cs <= 1'b0;
        else if(substate_nxt == ABS && width448)
            ABS_448_cs <= 1'b1;
        else if(substate == DONE)
            ABS_448_cs <= 1'b0;
        else
            ABS_448_cs <= ABS_448;             
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            ABS_448 <= 1'b0;
        else if(substate_nxt == ABS && width448 && !ABS_448_cs)
            ABS_448 <= 1'b1;
        else if(aloop0_max)
            ABS_448 <= 1'b0;
        else
            ABS_448 <= ABS_448;             
    end

//----4.6.3输出部分
    always@(*)begin
        sqzout64_en = 1'b0;
        if(substate == SQZ)begin
            sqzout64_en = sqz_cnt != abs_cnt_max;
        end
        else if(substate == MAT64)begin
            sqzout64_en = sqz_cnt != abs_cnt_max;
        end    
        else if(substate == MAT448)begin
            sqzout64_en = (sqz_cnt != abs_cnt_max);
        end 
        else if(substate == MATEpp)begin
        end    
    end


//----4.7 FSM下encode的控制

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            addrd_add_r <= 1'b1;
        else
            addrd_add_r <= addrd_add;    
    end

    always@(*)begin
        encode_en = 1'b0;
        if(substate == MATEpp)
            encode_en = sqzout64_en;
    end

    always@(*)begin
        encode_msg_val = 1'b0;
        if(substate == MAT448 && opcode == 4'b0000)
            encode_msg_val = addrd_add_r;    
    end


////////////////////////////////////////////////////////fifo cotrol
    








    wire        [12:0]      ADDRa           ;
    wire        [12:0]      ADDRb           ;
    wire        [12:0]      ADDRc           ;
    wire        [12:0]      ADDRd           ; 





        

        
(* dont_touch = "true" *) instDecoder u_instDecoder(
    .clk           ( clk           ),
    .rstn          ( rstn          ),
    .lvl           ( lvl           ),
    .mode          ( mode          ),
    .en            ( start            ),
    .inst_all      (inst_all        ), 
    .ex_done       ( ex_done       ),
    .encode_done   ( encode_done   ),
    .workdone      ( work_done      ),
    .addr_load     ( addra_load     ),
    .reg_clr       ( reg_clr       ),
    .opcode        ( opcode        ),
    .addr_rd_num   ( addr_rd_num   ),
    .addr_run_num  ( addr_run_num  ),
    .width448      ( width448      ),
    .pad           ( pad_flag      ),
    .sqz_num       ( sqz_num       ),
    .string0       ( string0       ),
    .addr_run_cnt  ( addr_run_cnt  ),
    .prefixa       ( prefixa       ),
    .prefixb       ( prefixb       ),
    .prefixc       ( prefixc       ),
    .prefixd       ( prefixd       ),
    .ADDRa_base    ( ADDRa_base    ),
    .ADDRb_base    ( ADDRb_base    ),
    .ADDRc_base    ( ADDRc_base    ),
    .ADDRd_base    ( ADDRd_base    ),
    .ADDRa_skip0   ( ADDRa_skip0   ),
    .ADDRa_skip1   ( ADDRa_skip1   ),
    .ADDRb_skip0   ( ADDRb_skip0   ),
    .ADDRb_skip1   ( ADDRb_skip1   ),
    .ADDRc_skip0   ( ADDRc_skip0   ),
    .ADDRc_skip1   ( ADDRc_skip1   ),
    .ADDRd_skip0   ( ADDRd_skip0   ),
    .ADDRd_skip1   ( ADDRd_skip1   ),
    .aloop0_max    ( aloop0_max    ),
    .aloop1_max    ( aloop1_max    ),
    .aloop2_max    ( aloop2_max    ),
    .aloop3_max    ( aloop3_max    ),
    .bloop0_max    ( bloop0_max    ),
    .bloop1_max    ( bloop1_max    ),
    .bloop2_max    ( bloop2_max    ),
    .bloop3_max    ( bloop3_max    ),
    .cloop0_max    ( cloop0_max    ),
    .cloop1_max    ( cloop1_max    ),
    .cloop2_max    ( cloop2_max    ),
    .cloop3_max    ( cloop3_max    ),
    .dloop0_max    ( dloop0_max    ),
    .dloop1_max    ( dloop1_max    ),
    .dloop2_max    ( dloop2_max    ),
    .dloop3_max    ( dloop3_max    )
);




(* dont_touch = "true" *) RAM_Arbitration u_RAM_Arbitration(
    .prefix0       ( prefix0       ),
    .prefix1       ( prefix1       ),
    .prefix2       ( prefix2       ),
    .prefix3       ( prefix3       ),
    .ADDR0         ( ADDRa         ),
    .ADDR1         ( ADDRb         ),
    .ADDR2         ( ADDRc         ),
    .ADDR3         ( ADDRd         ),
    .we0           ( we0           ),
    .we1           ( we1           ),
    .we2           ( we2           ),
    .we3           ( we3           ),
    .addr_448ramr  ( addr_448ramr  ),
    .addr_448ramw  ( addr_448ramw  ),
    .addr_64rama0  ( addr_64rama0  ),
    .addr_64rama1  ( addr_64rama1  ),
    .addr_64ramb0  ( addr_64ramb0  ),
    .addr_64ramb1  ( addr_64ramb1  ),
    .we_448ram     ( we_448ram     ),
    .we_64rama0    ( we_64rama0    ),
    .we_64rama1    ( we_64rama1    ),
    .we_64ramb0    ( we_64ramb0    ),
    .we_64ramb1    ( we_64ramb1    )
);



(* dont_touch = "true" *) AddrGenUnit u_AddrGenUnit(
    .clk          ( clk          ),
    .rstn         ( rstn         ),
    .ADDRa_add    ( ADDRa_add    ),
    .ADDRb_add    ( ADDRb_add    ),
    .ADDRc_add    ( ADDRc_add    ),
    .ADDRd_add    ( ADDRd_add    ),
    .ADDR_clr     ( ADDR_clr     ),
    .macmode         ( agumode       ),
    .mac_en       ( mac_en       ),
    .ADDRa_base   ( ADDRa_base   ),
    .ADDRb_base   ( ADDRb_base   ),
    .ADDRc_base   ( ADDRc_base   ),
    .ADDRd_base   ( ADDRd_base   ),
    .ADDRa_skip0  ( ADDRa_skip0  ),
    .ADDRa_skip1  ( ADDRa_skip1  ),
    .ADDRb_skip0  ( ADDRb_skip0  ),
    .ADDRb_skip1  ( ADDRb_skip1  ),
    .ADDRc_skip0  ( ADDRc_skip0  ),
    .ADDRc_skip1  ( ADDRc_skip1  ),
    .ADDRd_skip0  ( ADDRd_skip0  ),
    .ADDRd_skip1  ( ADDRd_skip1  ),
    .aloop0max    ( aloop0_max    ),
    .aloop1max    ( aloop1_max    ),
    .aloop2max    ( aloop2_max    ),
    .aloop3max    ( aloop3_max    ),
    .bloop0max    ( bloop0_max    ),
    .bloop1max    ( bloop1_max    ),
    .bloop2max    ( bloop2_max    ),
    .bloop3max    ( bloop3_max    ),
    .cloop0max    ( cloop0_max    ),
    .cloop1max    ( cloop1_max    ),
    .cloop2max    ( cloop2_max    ),
    .cloop3max    ( cloop3_max    ),
    .dloop0max    ( dloop0_max    ),
    .dloop1max    ( dloop1_max    ),
    .dloop2max    ( dloop2_max    ),
    .dloop3max    ( dloop3_max    ),
    .aloop0full   ( aloop0full   ),
    .aloop1full   ( aloop1full   ),
    .aloop2full   ( aloop2full   ),
    .aloop3full   ( aloop3full   ),
    .bloop0full   ( bloop0full   ),
    .bloop1full   ( bloop1full   ),
    .bloop2full   ( bloop2full   ),
    .bloop3full   ( bloop3full   ),
    .cloop0full   ( cloop0full   ),
    .cloop1full   ( cloop1full   ),
    .cloop2full   ( cloop2full   ),
    .cloop3full   ( cloop3full   ),
    .dloop0full   ( dloop0full   ),
    .dloop1full   ( dloop1full   ),
    .dloop2full   ( dloop2full   ),
    .dloop3full   ( dloop3full   ),
    .ADDRa        ( ADDRa        ),
    .ADDRb        ( ADDRb        ),
    .ADDRc        ( ADDRc        ),
    .ADDRd        ( ADDRd        )
);



endmodule
