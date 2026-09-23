`timescale 1ns / 1ps

module AHB_slave_tb;

    reg         Hclk;
    reg         Hresetn;
    reg         Hwrite;
    reg         Hreadyin;
    reg  [1:0]  Htrans;
    reg  [31:0] Haddr;
    reg  [31:0] Hwdata;
    reg  [31:0] Prdata;

    wire [1:0]  Hresp;
    wire [31:0] Hrdata;
    wire        valid;
    wire [31:0] Haddr1;
    wire [31:0] Haddr2;
    wire [31:0] Hwdata1;
    wire [31:0] Hwdata2;
    wire        Hwritereg;
    wire        Hwritereg1;
    wire [2:0]  tempselx;

    AHB_slave uut (
        .Hclk(Hclk), 
        .Hresetn(Hresetn), 
        .Hwrite(Hwrite), 
        .Hreadyin(Hreadyin), 
        .Htrans(Htrans), 
        .Haddr(Haddr), 
        .Hwdata(Hwdata), 
        .Prdata(Prdata), 
        .Hresp(Hresp), 
        .Hrdata(Hrdata), 
        .valid(valid), 
        .Haddr1(Haddr1), 
        .Haddr2(Haddr2), 
        .Hwdata1(Hwdata1), 
        .Hwdata2(Hwdata2), 
        .Hwritereg(Hwritereg), 
        .Hwritereg1(Hwritereg1), 
        .tempselx(tempselx)
    );

    initial begin
        Hclk = 0;
        forever #5 Hclk = ~Hclk; 
    end

    initial begin
        Hresetn  = 0;
        Hwrite   = 0;
        Hreadyin = 1'b1;     
        Htrans   = 2'b00;    
        Haddr    = 32'h0;
        Hwdata   = 32'h0;
        Prdata   = 32'hDEADBEEF; 

        #15;
        Hresetn = 1;

        #10;
        Htrans = 2'b10;          
        Haddr  = 32'h8000_0004;  
        Hwrite = 1'b0;           
        
        #10;
        Htrans = 2'b10;          
        Haddr  = 32'h8400_0008;  
        Hwrite = 1'b1;           
        
        #10;
        Haddr  = 32'h8800_000C;  
        Hwdata = 32'hAABBCCDD;   
        
        #10;
        Htrans = 2'b00;          
        Haddr  = 32'h0;
        Hwrite = 1'b0;
        Hwdata = 32'h11223344;   

        #30;
        
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t | rst=%b | Addr=%h | Wdata=%h | valid=%b | sel=%b | Addr1=%h | Addr2=%h", 
                 $time, Hresetn, Haddr, Hwdata, valid, tempselx, Haddr1, Haddr2);
    end

endmodule