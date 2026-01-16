    //待定:loop真的需要每个abcd都有一个吗    
    //注意：init需要提前两个进行放置
    //注意：addr_cnt 放置原则 放置4-共5个数 放置para=2-》有三个a
    // addr a 的base、prefix、loop0max单独分堆；SKIP0不需压堆，通常都是1
module instDecoder (
    input                   clk,
    input                   rstn,

    input       [1:0]       lvl             ,
    input       [1:0]       mode            ,    

    input                   en              ,//一个算法的第一条指令运行
    input                   ex_done         ,//外部工作结束
    output  reg             encode_done     ,//一次解码工作结束
    output  reg             workdone        ,//一个算法结束


    input                   addr_load       ,//切换地址    
    input                   reg_clr         ,//一次指令结束，全部复位所有寄存器   
        

    output      [35:0]      inst_all           ,    

    //解码得到的参数
        //操作码扩展
    output      [3:0]       opcode             ,
    output      [2:0]       addr_rd_num        ,
    output      [2:0]       addr_run_num       , 

    output                  width448           ,


    output  reg [2:0]       pad                 ,
    output  reg [8:0]       sqz_num             ,
    output  reg [8:0]       string0             ,

        //地址相关

    output  reg     [2:0]       addr_run_cnt    ,    

    output  reg     [2:0]       prefixa         ,
    output          [2:0]       prefixb         ,
    output          [2:0]       prefixc         ,
    output          [2:0]       prefixd         ,
            //地址基
    output  reg     [12:0]    ADDRa_base         ,
    output          [12:0]    ADDRb_base         ,
    output          [12:0]    ADDRc_base         ,
    output          [12:0]    ADDRd_base         ,
            //跳转步长      
    output  reg     [8:0]     ADDRa_skip0        ,////0部分默认是1     
    output  reg     [8:0]     ADDRa_skip1        ,////1部分默认是0
    output  reg     [8:0]     ADDRb_skip0        ,     
    output  reg     [8:0]     ADDRb_skip1        ,
    output  reg     [8:0]     ADDRc_skip0        ,     
    output  reg     [8:0]     ADDRc_skip1        ,
    output  reg     [8:0]     ADDRd_skip0        ,     
    output  reg     [8:0]     ADDRd_skip1        ,
            //循环节最值
    output  reg     [12:0]    aloop0_max         ,//均默认0   
    output  reg     [12:0]    aloop1_max         ,   
    output  reg     [12:0]    aloop2_max         ,   
    output  reg     [12:0]    aloop3_max         , 

    output  reg     [12:0]    bloop0_max         ,
    output  reg     [12:0]    bloop1_max         ,
    output  reg     [12:0]    bloop2_max         ,
    output  reg     [12:0]    bloop3_max         ,  

    output  reg     [12:0]    cloop0_max         ,
    output  reg     [12:0]    cloop1_max         ,
    output  reg     [12:0]    cloop2_max         ,
    output  reg     [12:0]    cloop3_max         ,

    output  reg     [12:0]    dloop0_max         ,
    output  reg     [12:0]    dloop1_max         ,
    output  reg     [12:0]    dloop2_max         ,
    output  reg     [12:0]    dloop3_max         



);


   


    
    

    


//本模块内部所用寄存器
    //均放置在一个指令里,注（先放置固定地址后放置切换地址，后用先入）    
    reg             [2:0]   addr_cnt;//标记当前初始化地址数
    reg             [2:0]   paralell;//固定地址数
    reg             [2:0]   addr_num;//总地址数   
    reg             [2:0]   rd_num;

   assign       addr_rd_num    =     rd_num;
   assign       addr_run_num   =     addr_num - paralell;


//--------------------------------------------------------取址操作
    parameter   IDLE    =   3'd0;//指令地址保持0
    parameter   START   =   3'd1;//提供指令起始地址
    parameter   LOAD    =   3'd2;//地址+1ing，从中取寄存器值
    parameter   BUFF    =   3'd3;
    parameter   ADDR    =   3'd4;//初始化地址寄存器堆 地址不增
    parameter   BUFF0   =   3'd7;
    parameter   RUN     =   3'd5;//外部的执行，在其中从寄存器堆取运行地址 地址不增
    parameter   DONE    =   3'd6;//指令完成一次

//流水线式有效信号(同周期指示)
    reg init_addr_valid;//初始化指令地址有效
    reg init_data_valid;//初始化指令数据有效
    reg init_reg_valid; //初始化指令数据存入  
    reg work_addr_valid;//工作地址有效
    reg work_data_valid;//工作数据有效
    reg index_req;
    reg index_valid;//同时也是index取出的addr有效
    reg index_req_done;
    reg index_reg_valid;//addr数据存入的周期  
    
//状态指示

    reg load_done;
    reg run_done;
    reg buff_done;//工作指令所有数据全部存入拉高
    reg work_done;

//-------------------------------------------------------取址状态机
    reg [2:0]   CS,NS;

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            CS <= 0;
        else
            CS <= NS;    
    end


    always@(*)begin
        case(NS)
            IDLE:begin
                if(en)
                    NS = START;
                else
                    NS = IDLE;    
            end
            START:begin//加载初始的指令地址
                NS = LOAD;
            end
            LOAD:begin//通过在最后一个init指令添加done，补足一个时钟差距
                if(load_done)
                    NS =   BUFF;
                else
                    NS =   LOAD;    
            end
            ADDR:begin//执行取工作指令的+1
                    NS =   BUFF;    
            end
            BUFF:begin//我们希望所有数据准备好之后进入运算
                if(buff_done)
                    NS = RUN;
                else
                    NS = BUFF;    
            end
            RUN:begin
                if(ex_done)//等待外部给出运行结束信号
                    NS =   DONE;
                else
                    NS =   RUN;    
            end
            DONE:begin
                if(workdone)//我们希望在进入DONE时所有数据已经运算存储完毕
                    NS =   IDLE;
                else
                    NS =   LOAD;        
            end
        endcase
    end
                           
//2.-----------------------------------------------------------指令rom 控制                        
    //wire           [35:0]  inst_all;
    reg            [3:0]   index;//地址索引
    reg            [10:0]  idle_addr; 
    reg            [10:0]  inst_addr; 

    always@(*)begin
        case({lvl,mode})
            4'b0101:idle_addr = 10'd1;
            4'b0110:idle_addr = 10'd103;
            4'b0111:idle_addr = 10'd238;
            4'b1001:idle_addr = 10'd335;
            4'b1010:idle_addr = 10'd446;
            4'b1011:idle_addr = 10'd597;
            4'b1101:idle_addr = 10'd693;
            4'b1110:idle_addr = 10'd781;
            4'b1111:idle_addr = 10'd854;
            default:idle_addr = 10'd0;
        endcase
    end

    always@(*)begin  
            case({lvl,mode})
            4'b0101:workdone = inst_addr == 10'd102;
            4'b0110:workdone = inst_addr == 10'd237;
            4'b0111:workdone = inst_addr == 10'd334;
            4'b1001:workdone = inst_addr == 10'd445;
            4'b1010:workdone = inst_addr == 10'd596;
            4'b1011:workdone = inst_addr == 10'd692;
            4'b1101:workdone = inst_addr == 10'd780;
            4'b1110:workdone = inst_addr == 10'd853;
            4'b1111:workdone = inst_addr == 10'd1001;
            default:workdone = 0;
            endcase
    end

    //此处设计是为了让地址的变化出现在状态的第一个周期
    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            inst_addr <= 0;
        else    if(en)
            inst_addr <= idle_addr;
        else    if(NS == LOAD)
            inst_addr <= inst_addr + 1'b1;
        else    if(NS == ADDR)
            inst_addr <= inst_addr + 1'b1;    
        else    if(NS == DONE)
            inst_addr <= 0;
        else
            inst_addr <= inst_addr;                
    end

    always@(*)begin
        load_done = inst_all[35];
    end






//3.-------------------------------------------------------数据从指令存入全局寄存器
        //----------------------------------------解码指令
        assign           opcode         = inst_all[3:0];    //操作码    
        wire             runinit        = inst_all[0];      //地址参数en
        wire             hashinit       = inst_all[1];      //hash参数en
        wire             askipinit      = inst_all[2];      //skip是偏移量
        wire             bskipinit      = inst_all[3];
        wire             cskipinit      = inst_all[4];
        wire             dskipinit      = inst_all[5];
        wire             aloop0init     = inst_all[6];      //loop是循环节最值
        wire             bloop0init     = inst_all[7];
        wire             cloop0init     = inst_all[8];
        wire             dloop0init     = inst_all[9];
        wire   [1:0]     bcdloopinit    = inst_all[11:10];
        wire   [1:0]     loop123        = inst_all[13:12];    

        wire   [12:0]    loopmax        = inst_all[26:14];
        wire   [8:0]     skip0          = inst_all[22:14];
        wire   [8:0]     skip1          = inst_all[31:23];


        wire   [15:0]    addr;                              //取出的地址 prefix + addrbase

        //3.1准备流水指示信号

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                init_addr_valid <= 1'b0;
            else if(NS == START || NS == LOAD)
                init_addr_valid <= 1'b1;
            else
                init_addr_valid <= 1'b0;         
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                init_data_valid <= 1'b0;
            else  
                init_data_valid <= init_addr_valid;  
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                init_reg_valid <= 1'b0;
            else
                init_reg_valid <= init_data_valid;
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                work_addr_valid <= 1'b0;
            else if(NS == ADDR)
                work_addr_valid <= 1'b1;
            else
                work_addr_valid <= 1'b0;         
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                index_req <= 1'b0;
            else if(index_req_done)
                index_req <= 1'b0;
            else if(NS == BUFF) 
                index_req <= 1'b1;
            else
                index_req <= index_req;

        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                index_valid <= 1'b0;
            else 
                index_valid <= index_req;
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                index_reg_valid <= 1'b0;
            else 
                index_reg_valid <= index_valid;
        end
    
        //3.2hash参数寄存器
        always@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                pad      <= 0;
                sqz_num  <= 0;
                string0  <= 0;      
            end
            else if(init_data_valid && hashinit)begin
                pad      <= inst_all[16:14];       
                sqz_num  <= inst_all[25:17];
                string0  <= inst_all[34:26];  
            end
            else if(CS == DONE)begin
                pad      <= 0;
                sqz_num  <= 0;
                string0  <= 0;      
            end
            else begin
                pad      <= pad    ;
                sqz_num  <= sqz_num;
                string0  <= string0;   
            end
        end    
        //3.3地址参数寄存器
        always@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                addr_num      <= 0;
                rd_num        <= 0;
                paralell      <= 0;      
            end
            else if(init_data_valid && runinit)begin
                addr_num  <= inst_all[16:14];       
                rd_num    <= inst_all[19:17];
                paralell  <= inst_all[22:20];  
            end
            else if(CS == DONE)begin
                addr_num  <= 0;
                rd_num    <= 0;
                paralell  <= 0;      
            end
            else begin
                addr_num  <= addr_num;
                rd_num    <= rd_num  ;
                paralell  <= paralell;   
            end
        end
        //3.4loop寄存器
            //只有aloopmax比较特殊，与addra一样需要一个堆
            //loop 13bit大小 65位 需要5个
        reg [64:0] aloop0_max_pile;

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                aloop0_max_pile <=  0;
            else    if(init_data_valid && aloop0init)
                aloop0_max_pile     <=  {aloop0_max_pile[51:0],loopmax};
            else    if(CS == DONE)
                aloop0_max_pile     <=  0;     
            else
                aloop0_max_pile     <=  aloop0_max_pile;     
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                bloop0_max <=  0;
            else    if(init_data_valid && bloop0init)
                bloop0_max     <=  loopmax;
            else    if(CS == DONE)
                bloop0_max     <=  0;     
            else
                bloop0_max     <=  bloop0_max;     
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                cloop0_max <=  0;
            else    if(init_data_valid && cloop0init)
                cloop0_max     <=  loopmax;
            else    if(CS == DONE)
                cloop0_max     <=  0;     
            else
                cloop0_max     <=  cloop0_max;     
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                dloop0_max <=  0;
            else    if(init_data_valid && dloop0init)
                dloop0_max     <=  loopmax;
            else    if(CS == DONE)
                dloop0_max     <=  0;     
            else
                dloop0_max     <=  dloop0_max;     
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                aloop1_max  <= 0;  
                aloop2_max  <= 0;
                aloop3_max  <= 0;    
                bloop1_max  <= 0;
                bloop2_max  <= 0;
                bloop3_max  <= 0;
                cloop1_max  <= 0;
                cloop2_max  <= 0;
                cloop3_max  <= 0;
                dloop1_max  <= 0;
                dloop2_max  <= 0;
                dloop3_max  <= 0;
            end
            else    if(init_data_valid )begin
                case({bcdloopinit,loop123})
                    4'b0001:aloop1_max <= loopmax;
                    4'b0010:aloop2_max <= loopmax;
                    4'b0011:aloop3_max <= loopmax;
                    4'b0101:bloop1_max <= loopmax;
                    4'b0110:bloop2_max <= loopmax;
                    4'b0111:bloop3_max <= loopmax;
                    4'b1001:cloop1_max <= loopmax;
                    4'b1010:cloop2_max <= loopmax;
                    4'b1011:cloop3_max <= loopmax;
                    4'b1001:dloop1_max <= loopmax;
                    4'b1010:dloop2_max <= loopmax;
                    4'b1011:dloop3_max <= loopmax;
                    default:;
                endcase
            end
            else    if(CS == DONE)begin
                aloop1_max  <= 0;  
                aloop2_max  <= 0;
                aloop3_max  <= 0;    
                bloop1_max  <= 0;
                bloop2_max  <= 0;
                bloop3_max  <= 0;
                cloop1_max  <= 0;
                cloop2_max  <= 0;
                cloop3_max  <= 0;
                dloop1_max  <= 0;
                dloop2_max  <= 0;
                dloop3_max  <= 0;
            end    
            else begin
                aloop1_max  <= aloop1_max;  
                aloop2_max  <= aloop2_max;
                aloop3_max  <= aloop3_max;    
                bloop1_max  <= bloop1_max;
                bloop2_max  <= bloop2_max;
                bloop3_max  <= bloop3_max;
                cloop1_max  <= cloop1_max;
                cloop2_max  <= cloop2_max;
                cloop3_max  <= cloop3_max;
                dloop1_max  <= dloop1_max;
                dloop2_max  <= dloop2_max;
                dloop3_max  <= dloop3_max;
            end
        end
        //3.5偏移值寄存器，比较特殊的是，我们希望在初态其有起始值1
        always@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                ADDRa_skip0 <= 0;
                ADDRa_skip1 <= 0;    
            end
            else if(init_data_valid && askipinit)begin
                ADDRa_skip0 <= skip0;
                ADDRa_skip1 <= skip1;    
            end
            else if(CS == DONE || CS == IDLE)begin
                ADDRa_skip0 <= 9'b1;
                ADDRa_skip1 <= 9'b1; 
            end
            else begin
                ADDRa_skip0 <= ADDRa_skip0;
                ADDRa_skip1 <= ADDRa_skip1; 
            end
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                ADDRb_skip0 <= 0;
                ADDRb_skip1 <= 0;    
            end
            else if(init_data_valid && bskipinit)begin
                ADDRb_skip0 <= skip0;
                ADDRb_skip1 <= skip1;    
            end
            else if(CS == DONE || CS == IDLE)begin
                ADDRb_skip0 <= 9'b1;
                ADDRb_skip1 <= 9'b1; 
            end
            else begin
                ADDRb_skip0 <= ADDRb_skip0;
                ADDRb_skip1 <= ADDRb_skip1; 
            end
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                ADDRc_skip0 <= 0;
                ADDRc_skip1 <= 0;    
            end
            else if(init_data_valid && cskipinit)begin
                ADDRc_skip0 <= skip0;
                ADDRc_skip1 <= skip1;    
            end
            else if(CS == DONE || CS == IDLE)begin
                ADDRc_skip0 <= 9'b1;
                ADDRc_skip1 <= 9'b1; 
            end
            else begin
                ADDRc_skip0 <= ADDRc_skip0;
                ADDRc_skip1 <= ADDRc_skip1; 
            end
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                ADDRd_skip0 <= 0;
                ADDRd_skip1 <= 0;    
            end
            else if(init_data_valid && dskipinit)begin
                ADDRd_skip0 <= skip0;
                ADDRd_skip1 <= skip1;    
            end
            else if(CS == DONE || CS == IDLE)begin
                ADDRd_skip0 <= 9'b1;
                ADDRd_skip1 <= 9'b1; 
            end
            else begin
                ADDRd_skip0 <= ADDRd_skip0;
                ADDRd_skip1 <= ADDRd_skip1; 
            end
        end

        //3.6工作指令地址寄存器 包括控制取index的的过程，和将数据存入对应寄存器
            //3.6.0取index控制
        always@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                addr_cnt <= 0;    
            end
            else if(index_req)begin
                addr_cnt <= addr_cnt + 1'b1 ;     
            end
            else
                addr_cnt <= 0;   
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                index_req_done = 1'b0; 
            else if(addr_cnt == addr_num - 1'b1)           
                index_req_done = 1'b1;
            else if(CS == DONE)
                index_req_done = 1'b0;
            else
                index_req_done = index_req_done;    
        end


        always@(*)begin
            index = 4'b0;     
            case(addr_cnt)
                3'd0:index = inst_all[7:4];
                3'd1:index = inst_all[11:8];
                3'd2:index = inst_all[15:12];
                3'd3:index = inst_all[19:16];
                3'd4:index = inst_all[23:20];
                3'd5:index = inst_all[27:24];
                3'd6:index = inst_all[31:28];
            endcase
        end
        
            //3.6.1存入地址
        //2位ram + 1位口 + 12位地址  地址共15位   
        //后入先出，将最先使用的地址放置在最后，先放置切换地址后放置固定地址

        reg [74:0]  addr0;//放运行中切换的地址 最多切换五次 75
        reg [44:0]  addrnum;//放固定的3个地址 45

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                addrnum     <=  0;
            else    if(CS == DONE)
                addrnum     <=  0;
            else    if(index_valid && addr_cnt >= paralell)
                addrnum     <=  {addrnum[29:0],addr};
            else
                addrnum     <=  addrnum;     
        end

        always@(posedge clk or negedge rstn)begin
            if(!rstn)
                addr0     <=  0;
            else    if(CS == DONE)
                addr0     <=  0;
            else    if(index_valid && addr_cnt < paralell)
                addr0     <=  {addr0[59:0],addr};
            else
                addr0     <=  addr0;     
        end        
    
    
//4.取出数据，addr/loop
    //reg [2:0] addr_run_cnt;

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            addr_run_cnt <= 3'd0;
        else if(addr_load)
            addr_run_cnt <= addr_run_cnt + 1'b1;
        else if(CS == DONE)
            addr_run_cnt <= 3'd0;
        else
            addr_run_cnt <= addr_run_cnt;   
    end

    always@(*)begin
            case(addr_run_cnt)
                3'd0:begin
                   aloop0_max = aloop0_max_pile[12:0];
                end
                3'd1:begin
                   aloop0_max = aloop0_max_pile[25:13];
                end
                3'd2:begin
                    aloop0_max = aloop0_max_pile[38:26];
                end
                3'd3:begin
                   aloop0_max = aloop0_max_pile[51:39];
                end
                3'd4:begin
                    aloop0_max = aloop0_max_pile[64:52];
                end
            default:begin
                    aloop0_max = 13'b0;
                end    
            endcase
    end



    always@(*)begin
            case(addr_run_cnt)
                3'd0:begin
                    ADDRa_base   = addr0[11:0];
                    prefixa = addr0[14:12];
                end
                3'd1:begin
                    ADDRa_base   = addr0[26:15];
                    prefixa = addr0[29:27];
                end
                3'd2:begin
                    ADDRa_base   = addr0[41:30];
                    prefixa = addr0[44:42];
                end
                3'd3:begin
                    ADDRa_base   = addr0[56:45];
                    prefixa = addr0[59:57];
                end
                3'd4:begin
                    ADDRa_base   = addr0[71:60];
                    prefixa = addr0[74:72];
                end
            default:begin
                    ADDRa_base   = addr0[71:60];
                    prefixa = addr0[74:72];
                end    
            endcase
        end

    assign  ADDRb_base = addrnum[11:0];
    assign  prefixb    = addrnum[14:12];       
    assign  ADDRc_base = addrnum[26:15];
    assign  prefixc    = addrnum[29:27]; 
    assign  ADDRd_base = addrnum[41:30];
    assign  prefixd    = addrnum[44:42];






    instrom your_instance_name (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .addra(inst_addr),  // input wire [9 : 0] addra
  .douta(inst_all)  // output wire [35 : 0] douta
);

endmodule
