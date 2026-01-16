//对于loop操作不对齐数据和地址的导致的loopmax时钟误差，
//可能需要对4个loop进行时钟上的修正
//可能问题,操作切换至mac上，直接开始计算了就，但是有气泡，加mac使能
module AddrGenUnit (
    input                    clk             ,
    input                    rstn            ,
	
    //地址控制
    input                    ADDRa_add          ,
    input                    ADDRb_add          ,
    input                    ADDRc_add          ,
    input                    ADDRd_add          ,  

    input                    ADDR_clr           ,//很关键，此位置容易出错
    input          [2:0]     macmode               ,
    input                    mac_en             ,//矩阵的运行是自动的，不用en，但是要暂停

    //地址基
    input          [12:0]    ADDRa_base         ,
    input          [12:0]    ADDRb_base         ,
    input          [12:0]    ADDRc_base         ,
    input          [12:0]    ADDRd_base         ,

    //跳转步长      
    input          [8:0]     ADDRa_skip0        ,     
    input          [8:0]     ADDRa_skip1        ,
    input          [8:0]     ADDRb_skip0        ,     
    input          [8:0]     ADDRb_skip1        ,
    input          [8:0]     ADDRc_skip0        ,     
    input          [8:0]     ADDRc_skip1        ,
    input          [8:0]     ADDRd_skip0        ,     
    input          [8:0]     ADDRd_skip1        ,

    //循环节最值
    input          [12:0]    aloop0max         ,   
    input          [12:0]    aloop1max         ,   
    input          [12:0]    aloop2max         ,   
    input          [12:0]    aloop3max         , 

    input          [12:0]    bloop0max         ,
    input          [12:0]    bloop1max         ,
    input          [12:0]    bloop2max         ,
    input          [12:0]    bloop3max         ,  


    input          [12:0]    cloop0max         ,
    input          [12:0]    cloop1max         ,
    input          [12:0]    cloop2max         ,
    input          [12:0]    cloop3max         ,

    input          [12:0]    dloop0max         ,
    input          [12:0]    dloop1max         ,
    input          [12:0]    dloop2max         ,
    input          [12:0]    dloop3max         ,

    //实际地址状态

    output                  aloop0full         ,
    output                  aloop1full         ,
    output                  aloop2full         ,
    output                  aloop3full         ,

    output                  bloop0full         ,
    output                  bloop1full         ,
    output                  bloop2full         ,
    output                  bloop3full         ,

    output                  cloop0full         ,
    output                  cloop1full         ,
    output                  cloop2full         ,
    output                  cloop3full         ,

    output                  dloop0full         ,
    output                  dloop1full         ,
    output                  dloop2full         ,
    output                  dloop3full         ,

    //输出实际地址

    output        [12:0]    ADDRa               ,
    output        [12:0]    ADDRb               ,
    output        [12:0]    ADDRc               ,
    output        [12:0]    ADDRd               

    );
    parameter normal    =  3'b000; 
    parameter ASE       =  3'b001;
    parameter SAE       =  3'b010;
    parameter SBE       =  3'b011;
    parameter CBS       =  3'b100;
 
    //循环体
    reg     [12:0]  aloop0;
    reg     [12:0]  aloop1;  
    reg     [12:0]  aloop2;
    reg     [12:0]  aloop3;      

    reg     [12:0]  bloop0;
    reg     [12:0]  bloop1; 
    reg     [12:0]  bloop2;
    reg     [12:0]  bloop3; 

    reg     [12:0]  cloop0;
    reg     [12:0]  cloop1; 
    reg     [12:0]  cloop2;
    reg     [12:0]  cloop3; 

    reg     [12:0]  dloop0;
    reg     [12:0]  dloop1;
    reg     [12:0]  dloop2;
    reg     [12:0]  dloop3;


   
    //-----------------------------------------------地址中间值
    reg     [12:0]   addr0_temp0;
    reg     [12:0]   addr0_temp1;
    reg     [12:0]   addr1_temp0;
    reg     [12:0]   addr1_temp1;
    reg     [12:0]   addr2_temp0;
    reg     [12:0]   addr2_temp1;
    reg     [12:0]   addr3_temp0;
    reg     [12:0]   addr3_temp1;

   
    //------------------------------------------实际相加地址

    assign  ADDRa   =   ADDRa_base + addr0_temp0 + addr0_temp1;
    assign  ADDRb   =   ADDRb_base + addr1_temp0 + addr1_temp1;
    assign  ADDRc   =   ADDRc_base + addr2_temp0 + addr2_temp1;
    assign  ADDRd   =   ADDRd_base + addr3_temp0 + addr3_temp1;
        //对于普通地址操作模式我们希望只对temp1操作

    
    //loop满信号
    assign    aloop0full = aloop0 == aloop0max;
    assign    aloop1full = aloop0 == aloop0max && aloop1 == aloop1max;
    assign    aloop2full = aloop0 == aloop0max && aloop1 == aloop1max && aloop2 == aloop2max;
    assign    aloop3full = aloop0 == aloop0max && aloop1 == aloop1max && aloop2 == aloop2max && aloop3 == aloop3max;


    // ---------- b ----------
    assign    bloop0full = bloop0 == bloop0max;
    assign    bloop1full = bloop0 == bloop0max && bloop1 == bloop1max;
    assign    bloop2full = bloop0 == bloop0max && bloop1 == bloop1max && bloop2 == bloop2max;
    assign    bloop3full = bloop0 == bloop0max && bloop1 == bloop1max && bloop2 == bloop2max && bloop3 == bloop3max;

    // ---------- c ----------
    assign    cloop0full = cloop0 == cloop0max;
    assign    cloop1full = cloop0 == cloop0max && cloop1 == cloop1max;
    assign    cloop2full = cloop0 == cloop0max && cloop1 == cloop1max && cloop2 == cloop2max;
    assign    cloop3full = cloop0 == cloop0max && cloop1 == cloop1max && cloop2 == cloop2max && cloop3 == cloop3max;

    // ---------- d ----------
    assign    dloop0full = dloop0 == dloop0max;
    assign    dloop1full = dloop0 == dloop0max && dloop1 == dloop1max;
    assign    dloop2full = dloop0 == dloop0max && dloop1 == dloop1max && dloop2 == dloop2max;
    assign    dloop3full = dloop0 == dloop0max && dloop1 == dloop1max && dloop2 == dloop2max && dloop3 == dloop3max;






    //---------------------------------------------------变动地址行为
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            addr0_temp0 <= 0;
            addr0_temp1 <= 0; 
        end
        else if(ADDR_clr)begin
            addr0_temp0 <= 0;
            addr0_temp1 <= 0;     
        end
        else case(macmode)
            normal:begin
                if(ADDRa_add)begin
                    addr0_temp0 <= addr0_temp0 + 1'b1;
                    addr0_temp1 <= addr0_temp1;
                end    
                else begin
                    addr0_temp0 <= addr0_temp0;
                    addr0_temp1 <= addr0_temp1;
                end
            end
            ASE:begin//控制ASE中得S
                if(mac_en)begin//判断有先后的顺序
                    if(aloop3full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= 13'd0;     
                    end
                    else if(aloop2full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= 13'd0;     
                    end
                    else if(aloop1full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= addr0_temp1;     
                    end
                    else if(aloop0full)begin
                        addr0_temp0 <= addr0_temp0 + ADDRa_skip0;
                        addr0_temp1 <= addr0_temp1;     
                    end
                    else begin 
                        addr0_temp0 <= addr0_temp0 + ADDRa_skip0;
                        addr0_temp1 <= addr0_temp1; 
                    end
                end
                else begin
                    addr0_temp0 <= addr0_temp0;
                    addr0_temp1 <= addr0_temp1;
                end
            end    
            SAE:begin//控制ASE中得S
                if(mac_en)begin//判断有先后的顺序
                    if(aloop3full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= 13'd0;     
                    end
                    else if(aloop2full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= addr0_temp1 + 1'b1;     
                    end
                    else if(aloop1full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= addr0_temp1;     
                    end
                    else if(aloop0full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= addr0_temp1;     
                    end
                    else begin 
                        addr0_temp0 <= addr0_temp0 + ADDRa_skip0;
                        addr0_temp1 <= addr0_temp1; 
                    end
                end
                else begin
                    addr0_temp0 <= addr0_temp0;
                    addr0_temp1 <= addr0_temp1;
                end
            end
            SBE:begin//控制ASE中得S
                if(mac_en)begin//判断有先后的顺序
                    if(aloop3full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= 13'd0;     
                    end
                    else if(aloop2full)begin
                        addr0_temp0 <= addr0_temp0;
                        addr0_temp1 <= addr0_temp1 + 1'b1;     
                    end
                    else if(aloop1full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= addr0_temp1;     
                    end
                    else if(aloop0full)begin
                        addr0_temp0 <= 13'd0;
                        addr0_temp1 <= addr0_temp1;     
                    end
                    else begin 
                        addr0_temp0 <= addr0_temp0 + ADDRa_skip0;
                        addr0_temp1 <= addr0_temp1; 
                    end
                end
                else begin
                    addr0_temp0 <= addr0_temp0;
                    addr0_temp1 <= addr0_temp1;
                end
            end
            default:begin
                    addr0_temp0 <= 13'd0;
                    addr0_temp1 <= 13'd0;
                    end
        endcase    
    end            
                
                
                
                
           


    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            addr1_temp0 <= 0;
            addr1_temp1 <= 0; 
        end
        else case(macmode)
            ASE:begin//控制ASE中得E
                if(bloop3full)begin
                    addr1_temp0 <= 0;
                    addr1_temp1 <= 0;
                end
                else if(bloop2full)begin
                    addr1_temp0 <= 13'd0;
                    addr1_temp1 <= addr1_temp1 + 1'b1;
                end
                else if(bloop1full)begin
                    addr1_temp0 <= 13'd0;
                    addr1_temp1 <= addr1_temp1;
                end
                else if(bloop0full)begin
                    addr1_temp0 <= addr1_temp0 + 1'b1;
                    addr1_temp1 <= addr1_temp1;
                end
                else begin
                    addr1_temp0 <= addr1_temp0;
                    addr1_temp1 <= addr1_temp1;
                end
            end    
            SAE:begin//控制S'AE'中的E'
                if(bloop3full)begin
                    addr1_temp0 <= 13'd0;
                    addr1_temp1 <= 13'd0;
                end
                else if(bloop2full)begin
                    addr1_temp0 <= 13'd0;
                    addr1_temp1 <= 13'd0;
                end
                else if(bloop1full)begin
                    addr1_temp0 <= 13'd0;
                    addr1_temp1 <= 13'd0;
                end
                else if(bloop0full)begin
                    addr1_temp0 <= addr1_temp0 + 1'b1;
                    addr1_temp1 <= addr1_temp1;
                end
                else begin
                    addr1_temp0 <= addr1_temp0 + ADDRa_skip0;
                    addr1_temp1 <= addr1_temp1;
                end
            end
            SBE:begin//控制S'BE''中得E''
                if(bloop3full)begin
                    addr1_temp0 <= 13'd0;
                    addr1_temp1 <= 13'd0;
                end
                else if(bloop2full)begin
                    addr1_temp0 <= 13'd0;
                    addr1_temp1 <= 13'd0;
                end
                else if(bloop1full)begin
                    addr1_temp0 <= 13'd0;
                    addr1_temp1 <= 13'd0;
                end
                else if(bloop0full)begin
                    addr1_temp0 <= addr1_temp0 + 1'b1;
                    addr1_temp1 <= addr1_temp1;
                end
                else begin
                    addr1_temp0 <= addr1_temp0 + ADDRa_skip0;
                    addr1_temp1 <= addr1_temp1;
                end
            end
            CBS:begin//控制B'SC中得C 
                 if(bloop3full)begin
                    addr1_temp0 <= 0;
                    addr1_temp1 <= 0; 
                end
                else if(bloop2full)begin
                    addr1_temp1 <= addr1_temp1 + 1'b1;
                end
                else if(bloop1full)begin
                    addr1_temp1 <= addr1_temp1 + 1'b1;
                    addr1_temp0 <= 0;
                end
                else if(bloop0full)begin
                    addr1_temp0 <= addr1_temp0 + 1'b1;
                end
            end    
            default:begin
                    addr1_temp0 <= 0;
                    addr1_temp1 <= 0; 
            end
        endcase
    end    
/*
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            addr2_temp0 <= 0;
            addr2_temp1 <= 0;
        end
        else case(macmode)
            SpBEpp:begin//控制S'BE''中得B
                
            end
            BpSC:begin//控制B'SC中得BP 
            
            end
            default:begin
                    addr0_temp0 <= 0;
                    addr0_temp1 <= 0;   
            end
        endcase
    end    
 */   


    



    
    
    //---------------------------------------------------矩阵写使能（仅一个地址，其余恒为0）
 /*   always@(posedge clk or negedge rstn)begin
        if(!rstn)
            ADDR3_we <= 0;
        else
            ADDR3_we <= mac_en;    
    end
*/

    //---------------------------------------------------循环行为
    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            aloop0 <= 0;
        else if(ADDRa_add)begin
            if(aloop0 == aloop0max)
                aloop0 <= 0;
            else
                aloop0 <= aloop0 + 1'b1;
        end
        else if(ADDR_clr)
                aloop0 <= aloop0;    
        else
            aloop0 <= aloop0;            
        end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            bloop0 <= 0;
        else if(ADDRb_add)begin
            if(bloop0 == bloop0max)
                bloop0 <= 0;
            else
                bloop0 <= bloop0 + 1'b1;
        end
        else if(ADDR_clr)
                bloop0 <= bloop0;    
        else
            bloop0 <= bloop0;            
        end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            cloop0 <= 0;
        else if(ADDRc_add)begin
            if(cloop0 == cloop0max)
                cloop0 <= 0;
            else
                cloop0 <= cloop0 + 1'b1;
        end
        else if(ADDR_clr)
                cloop0 <= cloop0;    
        else
            cloop0 <= cloop0;            
        end    
    
    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            dloop0 <= 0;
        else if(ADDRd_add)begin
            if(dloop0 == dloop0max)
                dloop0 <= 0;
            else
                dloop0 <= dloop0 + 1'b1;
        end
        else if(ADDR_clr)
                dloop0 <= dloop0;    
        else
            dloop0 <= dloop0;            
        end


    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            aloop1 <= 0;
        else if(aloop0 == aloop0max && ADDRa_add)begin
            if(aloop1 == aloop1max)
                aloop1 <= 0;
            else
                aloop1 <= aloop1 + 1'b1;    
        end
        else
            aloop1 <= aloop1;            
        end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            aloop2 <= 0;
        else if(aloop0 == aloop0max && aloop1 == aloop1max && ADDRa_add)begin
            if(aloop2 == aloop2max)
                aloop2 <= 0;
            else
                aloop2 <= aloop2 + 1'b1;    
        end
        else
            aloop2 <= aloop2;            
        end


    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            aloop3 <= 0;
        else if(aloop0 == aloop0max && aloop1 == aloop1max && aloop2 == aloop2max && ADDRa_add)begin
            if(aloop3 == aloop3max)
                aloop3 <= 0;
            else
                aloop3 <= aloop3 + 1'b1;    
        end
        else
            aloop3 <= aloop3;            
        end


    

   
always@(posedge clk or negedge rstn)begin
    if(!rstn)
        bloop1 <= 0;
    else if(bloop0 == bloop0max && ADDRb_add)begin
        if(bloop1 == bloop1max)
            bloop1 <= 0;
        else
            bloop1 <= bloop1 + 1'b1;
    end
    else
        bloop1 <= bloop1;
end

always@(posedge clk or negedge rstn)begin
    if(!rstn)
        bloop2 <= 0;
    else if(bloop0 == bloop0max && bloop1 == bloop1max && ADDRb_add)begin
        if(bloop2 == bloop2max)
            bloop2 <= 0;
        else
            bloop2 <= bloop2 + 1'b1;
    end
    else
        bloop2 <= bloop2;
end

always@(posedge clk or negedge rstn)begin
    if(!rstn)
        bloop3 <= 0;
    else if(bloop0 == bloop0max && bloop1 == bloop1max && bloop2 == bloop2max && ADDRb_add)begin
        if(bloop3 == bloop3max)
            bloop3 <= 0;
        else
            bloop3 <= bloop3 + 1'b1;
    end
    else
        bloop3 <= bloop3;
end


//==================== cloop1 ~ cloop4 ====================

always@(posedge clk or negedge rstn)begin
    if(!rstn)
        cloop1 <= 0;
    else if(cloop0 == cloop0max && ADDRc_add)begin
        if(cloop1 == cloop1max)
            cloop1 <= 0;
        else
            cloop1 <= cloop1 + 1'b1;
    end
    else
        cloop1 <= cloop1;
end

always@(posedge clk or negedge rstn)begin
    if(!rstn)
        cloop2 <= 0;
    else if(cloop0 == cloop0max && cloop1 == cloop1max && ADDRc_add)begin
        if(cloop2 == cloop2max)
            cloop2 <= 0;
        else
            cloop2 <= cloop2 + 1'b1;
    end
    else
        cloop2 <= cloop2;
end

always@(posedge clk or negedge rstn)begin
    if(!rstn)
        cloop3 <= 0;
    else if(cloop0 == cloop0max && cloop1 == cloop1max && cloop2 == cloop2max && ADDRc_add)begin
        if(cloop3 == cloop3max)
            cloop3 <= 0;
        else
            cloop3 <= cloop3 + 1'b1;
    end
    else
        cloop3 <= cloop3;
end



//==================== dloop1 ~ dloop4 ====================

always@(posedge clk or negedge rstn)begin
    if(!rstn)
        dloop1 <= 0;
    else if(dloop0 == dloop0max && ADDRd_add)begin
        if(dloop1 == dloop1max)
            dloop1 <= 0;
        else
            dloop1 <= dloop1 + 1'b1;
    end
    else
        dloop1 <= dloop1;
end

always@(posedge clk or negedge rstn)begin
    if(!rstn)
        dloop2 <= 0;
    else if(dloop0 == dloop0max && dloop1 == dloop1max && ADDRd_add)begin
        if(dloop2 == dloop2max)
            dloop2 <= 0;
        else
            dloop2 <= dloop2 + 1'b1;
    end
    else
        dloop2 <= dloop2;
end

always@(posedge clk or negedge rstn)begin
    if(!rstn)
        dloop3 <= 0;
    else if(dloop0 == dloop0max && dloop1 == dloop1max && dloop2 == dloop2max && ADDRd_add)begin
        if(dloop3 == dloop3max)
            dloop3 <= 0;
        else
            dloop3 <= dloop3 + 1'b1;
    end
    else
        dloop3 <= dloop3;
end



    
    




endmodule