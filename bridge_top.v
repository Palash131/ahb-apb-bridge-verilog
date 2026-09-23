module bridge_top(input hclk,hresetn,hwrite,hreadyin,
                  input [31:0]hwdata,haddr,prdata,
                  input [1:0]htrans,
                  output pwrite,penable,hr_readyout,
                  output [2:0]psel,
                  output [31:0]paddr,pwdata,hrdata, output [1:0] hresp);
    
    wire valid;
    wire [31:0]hwdata_1,hwdata_2,haddr_1,haddr_2;
    wire [2:0]temp_selx;

    AHB_slave_interface  ahb_s(hclk,hresetn,hwrite,hreadyin,htrans,hresp,hwdata,haddr,prdata,
                               valid,hwrite_reg,
                               haddr_1,haddr_2,hwdata_1,hwdata_2,temp_selx,hrdata);

    APB_Controller  apb_c(hclk,hresetn,hwrite,hwrite_reg,valid,
                          haddr,haddr_1,haddr_2,hwdata,hwdata_1, hwdata_2,prdata,
                          temp_selx,penable,pwrite,hr_readyout,paddr,pwdata,psel);

endmodule