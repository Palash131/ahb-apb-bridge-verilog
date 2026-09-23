module apb_controller(
    input hclk, 
    input hresetn, 
    input valid, 
    input hwrite, 
    input [31:0] haddr, 
    input [31:0] hwdata, 
    input [31:0] haddr1, 
    input [31:0] haddr2, 
    input [31:0] hwdata1, 
    input [31:0] hwdata2, 
    input hwritereg, 
    input [2:0] tempselx, 
    
    output reg pwrite, 
    output reg penable, 
    output reg [2:0] pselx, 
    output reg hreadyout, 
    output reg [31:0] pwdata, 
    output reg [31:0] paddr
);

    parameter st_idle    = 3'b000;
    parameter st_wait    = 3'b001;
    parameter st_write   = 3'b010;
    parameter st_writep  = 3'b011;
    parameter st_wenablep= 3'b100;
    parameter st_wenable = 3'b101;
    parameter st_read    = 3'b110;
    parameter st_renable = 3'b111;

    reg [2:0] state, next_state;
    reg [31:0] paddr_temp, pwdata_temp;
    reg penable_temp, pwrite_temp, hreadyout_temp;
    reg [2:0] pselx_temp;

    // --- State Register (Asynchronous Reset) ---
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn)
            state <= st_idle;
        else
            state <= next_state;
    end

    // --- Next State Logic ---
    always @(*) begin
        next_state = st_idle; 
        
        case(state)
            st_idle : begin
                if (valid == 1'b1 && hwrite == 1'b1)
                    next_state = st_wait;
                else if (valid == 1'b1 && hwrite == 1'b0)
                    next_state = st_read;
                else
                    next_state = st_idle;
            end
            
            st_wait : begin
                if (valid == 1'b1)
                    next_state = st_writep; // Pending write
                else
                    next_state = st_write;
            end
            
            st_read : begin
                next_state = st_renable;    // APB Enable phase for read
            end
            
            st_renable : begin
                if (valid == 1'b1 && hwrite == 1'b1)
                    next_state = st_wait;
                else if (valid == 1'b1 && hwrite == 1'b0)
                    next_state = st_read;
                else
                    next_state = st_idle;
            end
            
            st_write : begin
                if (valid == 1'b1)
                    next_state = st_wenablep;
                else
                    next_state = st_wenable;
            end
            
            st_wenable : begin
                if (valid == 1'b1 && hwrite == 1'b1)
                    next_state = st_wait;
                else if (valid == 1'b1 && hwrite == 1'b0)
                    next_state = st_read;
                else
                    next_state = st_idle;
            end
            
            st_writep : begin
                next_state = st_wenablep;
            end
            
            st_wenablep : begin
                if (valid == 1'b1 && hwritereg == 1'b1)
                    next_state = st_writep;
                else if (valid == 1'b0 && hwritereg == 1'b1)
                    next_state = st_write;
                else if (hwritereg == 1'b0)
                    next_state = st_read;
            end
            
            default : begin
                next_state = st_idle;
            end
        endcase
    end

    // --- Output Combinational Logic ---
    always @(*) begin
        // Initialize defaults to prevent inferred latches
        paddr_temp     = paddr;
        pwdata_temp    = pwdata;
        pwrite_temp    = pwrite;
        pselx_temp     = 3'b000;
        penable_temp   = 1'b0;
        hreadyout_temp = 1'b1;

        case(state) // Fixed from 'present' to 'state'
            st_idle : begin
                if(valid == 1 && hwrite == 0) begin
                    paddr_temp       = haddr;
                    pwrite_temp      = hwrite;
                    pselx_temp       = tempselx;
                    penable_temp     = 0;
                    hreadyout_temp   = 0;
                end
                else if(valid == 1 && hwrite == 1) begin
                    pselx_temp       = 0;
                    penable_temp     = 0;
                    hreadyout_temp   = 1;
                end
                else begin
                    pselx_temp       = 0;
                    penable_temp     = 0;
                    hreadyout_temp   = 1;
                end
            end

            st_wait : begin
                paddr_temp       = haddr1;
                pwdata_temp      = hwdata;
                pwrite_temp      = 1;
                pselx_temp       = tempselx;
                penable_temp     = 0;
                hreadyout_temp   = 0;
            end

            st_read : begin
                penable_temp     = 1;
                hreadyout_temp   = 1;
                pselx_temp       = tempselx; // Added to maintain select during enable
            end

            st_write, st_writep : begin
                penable_temp     = 1;
                hreadyout_temp   = 1;
                pselx_temp       = tempselx; // Added to maintain select during enable
            end

            st_renable, st_wenable : begin
                if(valid == 1 && hwrite == 0) begin
                    paddr_temp       = haddr;
                    pwrite_temp      = hwrite;
                    pselx_temp       = tempselx;
                    penable_temp     = 0;
                    hreadyout_temp   = 0;
                end
                else if(valid == 1 && hwrite == 1) begin
                    pselx_temp       = 0;
                    penable_temp     = 0;
                    hreadyout_temp   = 1;
                end
                else begin
                    pselx_temp       = 0;
                    penable_temp     = 0;
                    hreadyout_temp   = 1;
                end
            end

            st_wenablep : begin
                if(valid == 1 && hwritereg == 1) begin
                    paddr_temp       = haddr2;
                    pwdata_temp      = hwdata;
                    pwrite_temp      = 1;
                    pselx_temp       = tempselx;
                    penable_temp     = 0;
                    hreadyout_temp   = 0;
                end
                else if(valid == 1 && hwrite == 0) begin
                    paddr_temp       = haddr;
                    pwrite_temp      = hwrite;
                    pselx_temp       = tempselx;
                    penable_temp     = 0;
                    hreadyout_temp   = 0;
                end
                else begin
                    pselx_temp       = 0;
                    penable_temp     = 0;
                    hreadyout_temp   = 1;
                end
            end

            default : begin
                pselx_temp       = 0;
                penable_temp     = 0;
                hreadyout_temp   = 1;
            end
        endcase
    end

    // --- Output Registers (Asynchronous Reset) ---
    always @(posedge hclk or negedge hresetn) begin
        if(!hresetn) begin
            paddr     <= 32'd0;
            pwdata    <= 32'd0;
            pwrite    <= 1'b0;
            pselx     <= 3'd0;
            penable   <= 1'b0;
            hreadyout <= 1'b1;
        end
        else begin
            paddr     <= paddr_temp;
            pwdata    <= pwdata_temp;
            pwrite    <= pwrite_temp;
            pselx     <= pselx_temp;
            penable   <= penable_temp;
            hreadyout <= hreadyout_temp;
        end
    end

endmodule