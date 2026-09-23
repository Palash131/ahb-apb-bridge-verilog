module intel_4004_datapath (
    input  wire        clk,
    input  wire        reset,
    
    // External Bi-Directional Data Bus (D0-D3)
    inout  wire  [3:0] d_bus,

    // --------------------------------------------------------
    // Control Signals (Driven by an external Control Unit)
    // --------------------------------------------------------
    
    // External Bus Buffer Control
    input  wire        dbus_to_internal, // Route D0-D3 inward
    input  wire        internal_to_dbus, // Route internal outward
    
    // Accumulator & Temp Register Control
    input  wire        temp_ld,          // Load Temp Reg from bus
    input  wire        acc_ld,           // Load Accumulator from ALU
    input  wire        acc_to_bus,       // Route ACC to internal bus
    
    // ALU Control
    input  wire  [3:0] alu_op,           // Select arithmetic/logic operation
    input  wire        alu_to_bus,       // Route ALU result to internal bus
    
    // Instruction Register Control
    input  wire        ir_ld,            // Load Instruction Register
    output reg   [7:0] ir_out,           // Exported to external Decoder
    
    // Scratch Pad Control
    input  wire  [3:0] reg_sel,          // Index Register Select (0-15)
    input  wire        reg_we,           // Scratch Pad Write Enable
    input  wire        reg_to_bus,       // Route Scratch Pad to internal bus
    
    // Address Stack (Program Counter) Control
    input  wire        pc_inc,           // Increment active PC
    input  wire        pc_push,          // Push to address stack
    input  wire        pc_pop,           // Pop from address stack
    input  wire        bus_to_pc,        // Load PC from internal bus (jump)
    input  wire        pc_to_bus         // Route PC to internal bus
);

    // --------------------------------------------------------
    // Internal Nets and Registers
    // --------------------------------------------------------
    reg  [3:0] internal_data_bus;
    wire [3:0] d_bus_in;
    
    reg  [3:0] temp_reg;
    reg  [3:0] acc_reg;
    reg  [3:0] alu_result;
    reg        carry_flag;
    
    wire [3:0] scratch_pad_out;
    wire [11:0] active_pc;

    integer i; // Used for looping in the Scratch Pad reset

    // --------------------------------------------------------
    // Bi-Directional Data Bus Buffer
    // --------------------------------------------------------
    assign d_bus_in = d_bus;
    
    // Synthesizable Tri-state driver for external pins
    assign d_bus = internal_to_dbus ? internal_data_bus : 4'bz;

    // --------------------------------------------------------
    // Central Internal Bus Routing (Multiplexer)
    // --------------------------------------------------------
    always @* begin
        internal_data_bus = 4'b0000; // Default state prevents latches
        
        if (dbus_to_internal)      internal_data_bus = d_bus_in;
        else if (acc_to_bus)       internal_data_bus = acc_reg;
        else if (alu_to_bus)       internal_data_bus = alu_result;
        else if (reg_to_bus)       internal_data_bus = scratch_pad_out;
        else if (pc_to_bus)        internal_data_bus = active_pc[3:0]; 
    end

    // --------------------------------------------------------
    // Instruction Register (8-bit)
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            ir_out <= 8'b0;
        end else if (ir_ld) begin
            // Shift in 4 bits at a time from the internal bus
            ir_out <= {ir_out[3:0], internal_data_bus};
        end
    end

    // --------------------------------------------------------
    // Accumulator, Temp Register, and ALU
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            temp_reg   <= 4'b0;
            acc_reg    <= 4'b0;
            carry_flag <= 1'b0;
        end else begin
            if (temp_ld) temp_reg <= internal_data_bus;
            if (acc_ld)  acc_reg  <= alu_result;
        end
    end

    // Purely combinational ALU
    always @* begin
        alu_result = acc_reg; // Default assignment to avoid latches
        case (alu_op)
            4'b0000: alu_result = acc_reg + temp_reg; 
            4'b0001: alu_result = acc_reg - temp_reg; 
            4'b0010: alu_result = acc_reg & temp_reg;
            4'b0011: alu_result = acc_reg | temp_reg;
            4'b0100: alu_result = ~acc_reg;
            default: alu_result = acc_reg;
        endcase
    end

    // --------------------------------------------------------
    // Scratch Pad (16 x 4-bit Register File)
    // --------------------------------------------------------
    reg [3:0] registers [0:15];

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 4'b0;
            end
        end else if (reg_we) begin
            registers[reg_sel] <= internal_data_bus;
        end
    end

    assign scratch_pad_out = registers[reg_sel];

    // --------------------------------------------------------
    // Address Stack (Program Counter & Levels 1-3)
    // --------------------------------------------------------
    reg [11:0] stack [0:3]; 
    reg [1:0]  sp; // Stack Pointer

    assign active_pc = stack[sp];

    always @(posedge clk) begin
        if (reset) begin
            sp <= 2'b00;
            stack[0] <= 12'b0; 
            stack[1] <= 12'b0;
            stack[2] <= 12'b0; 
            stack[3] <= 12'b0;
        end else begin
            if (pc_push) begin
                sp <= sp + 1'b1;
                stack[sp + 1'b1] <= active_pc; 
            end else if (pc_pop) begin
                sp <= sp - 1'b1;
            end else if (bus_to_pc) begin
                // Loads lower 4 bits from bus, retains upper 8 bits
                stack[sp] <= {stack[sp][11:4], internal_data_bus};
            end else if (pc_inc) begin
                stack[sp] <= active_pc + 1'b1;
            end
        end
    end

endmodule