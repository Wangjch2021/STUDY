//功能:纯组合逻辑MUX与接线，从外部给予不定向地址、使能与编号，产出定向到RAM的地址与使能
    //prefix 表 1写(1口) 00 无对应ram(很关键)
    //          0读(0口) 01 ram448
    //                   10 ram64a   
    //                   11 ram64b   
module RAM_Arbitration (

    input        [2:0]       prefix0         ,
	input        [2:0]       prefix1         ,
    input        [2:0]       prefix2         ,
    input        [2:0]       prefix3         ,
      
    input        [12:0]      ADDR0           ,
    input        [12:0]      ADDR1           ,
    input        [12:0]      ADDR2           ,
    input        [12:0]      ADDR3           , 

    input                    we0             ,     
    input                    we1             ,
    input                    we2             ,
    input                    we3             ,              

    
    //仲裁后实际输出地址
	output reg  [8:0]        addr_448ramr    ,
    output reg  [8:0]        addr_448ramw    ,  
    output reg  [11:0]       addr_64rama0    ,
    output reg  [11:0]       addr_64rama1    ,
    output reg  [12:0]       addr_64ramb0    ,
    output reg  [12:0]       addr_64ramb1    ,

    output reg               we_448ram        ,
    output reg               we_64rama0       ,
    output reg               we_64rama1       ,
    output reg               we_64ramb0       ,
    output reg               we_64ramb1       

   
    );

   
    always@(*)begin
        addr_448ramr = 0;
        if(prefix0[2:0] == 3'b001)
            addr_448ramr = ADDR0[8:0];
        else if(prefix1[2:0] == 3'b001)
            addr_448ramr = ADDR1[8:0];
        else if(prefix2[2:0] == 3'b001)
            addr_448ramr = ADDR2[8:0];
        else if(prefix3[2:0] == 3'b001)
            addr_448ramr = ADDR3[8:0];
    end


    always@(*)begin
        addr_448ramw = 0;
             if(prefix0[2:0] == 3'b101)
            addr_448ramw = ADDR0[8:0];
        else if(prefix1[2:0] == 3'b101)
            addr_448ramw = ADDR1[8:0];
        else if(prefix2[2:0] == 3'b101)
            addr_448ramw = ADDR2[8:0];
        else if(prefix3[2:0] == 3'b101)
            addr_448ramw = ADDR3[8:0];
    end

    always@(*)begin
        we_448ram = 0;
             if(prefix0[2:0] == 3'b101)
            we_448ram = we0;
        else if(prefix1[2:0] == 3'b101)
            we_448ram = we1;
        else if(prefix2[2:0] == 3'b101)
            we_448ram = we2;
        else if(prefix3[2:0] == 3'b101)
            we_448ram = we3;
    end
    


    always@(*)begin
        addr_64rama0 = 0;
             if(prefix0[2:0] == 3'b010)
            addr_64rama0 = ADDR0;
        else if(prefix1[2:0] == 3'b010)
            addr_64rama0 = ADDR1;
        else if(prefix2[2:0] == 3'b010)
            addr_64rama0 = ADDR2;
        else if(prefix3[2:0] == 3'b010)
            addr_64rama0 = ADDR3;
    end

    always@(*)begin
        we_64rama0 = 0;
             if(prefix0[2:0] == 3'b010)
            we_64rama0 = we0;
        else if(prefix1[2:0] == 3'b010)
            we_64rama0 = we1;
        else if(prefix2[2:0] == 3'b010)
            we_64rama0 = we2;
        else if(prefix3[2:0] == 3'b010)
            we_64rama0 = we3;
    end



    always@(*)begin
        addr_64rama1 = 0;
             if(prefix0[2:0] == 3'b110)
            addr_64rama1 = ADDR0;
        else if(prefix1[2:0] == 3'b110)
            addr_64rama1 = ADDR1;
        else if(prefix2[2:0] == 3'b110)
            addr_64rama1 = ADDR2;
        else if(prefix3[2:0] == 3'b110)
            addr_64rama1 = ADDR3;
    end

    always@(*)begin
        we_64rama1 = 0;
             if(prefix0[2:0] == 3'b110)
            we_64rama1 = we0;
        else if(prefix1[2:0] == 3'b110)
            we_64rama1 = we1;
        else if(prefix2[2:0] == 3'b110)
            we_64rama1 = we2;
        else if(prefix3[2:0] == 3'b110)
            we_64rama1 = we3;
    end




    always@(*)begin
        addr_64ramb0 = 0;
             if(prefix0[2:0] == 3'b011)
            addr_64ramb0 = ADDR0;
        else if(prefix1[2:0] == 3'b011)
            addr_64ramb0 = ADDR1;
        else if(prefix2[2:0] == 3'b011)
            addr_64ramb0 = ADDR2;
        else if(prefix3[2:0] == 3'b011)
            addr_64ramb0 = ADDR3;
    end

    always@(*)begin
        we_64ramb0 = 0;
             if(prefix0[2:0] == 3'b011)
            we_64ramb0 = we0;
        else if(prefix1[2:0] == 3'b011)
            we_64ramb0 = we1;
        else if(prefix2[2:0] == 3'b011)
            we_64ramb0 = we2;
        else if(prefix3[2:0] == 3'b011)
            we_64ramb0 = we3;
    end


    always@(*)begin
        addr_64ramb1 = 0;
             if(prefix0[2:0] == 3'b111)
            addr_64ramb1 = ADDR0;
        else if(prefix1[2:0] == 3'b111)
            addr_64ramb1 = ADDR1;
        else if(prefix2[2:0] == 3'b111)
            addr_64ramb1 = ADDR2;
        else if(prefix3[2:0] == 3'b111)
            addr_64ramb1 = ADDR3;
    end

    always@(*)begin
        we_64ramb1 = 0;
             if(prefix0[2:0] == 3'b111)
            we_64ramb1 = we0;
        else if(prefix1[2:0] == 3'b111)
            we_64ramb1 = we1;
        else if(prefix2[2:0] == 3'b111)
            we_64ramb1 = we2;
        else if(prefix3[2:0] == 3'b111)
            we_64ramb1 = we3;
    end



endmodule
