
module cache_controller (
    // Clock and reset
    input wire clk,
    input wire rst,

    // CPU interface
    input wire cpu_req,
    input wire cpu_write,
    input wire [31:0] cpu_addr,
    input wire [127:0] cpu_write_data,
    output reg cpu_ready,
    output reg [127:0] cpu_read_data,

    // Cache status
    input wire tag_match,
    input wire valid_bit,
    input wire [127:0] cache_read_data,

    // Cache control signals
    output reg tag_we,
    output reg valid_we,
    output reg data_we,
    output reg valid_in,
    output wire [5:0] cache_index,
    output wire [21:0] cache_tag_in,
    output reg [127:0] cache_data_in,

    // Main memory interface
    input wire mem_ready,
    input wire [127:0] mem_read_data,
    output reg mem_req,
    output reg mem_write_en,
    output reg [27:0] mem_addr,
    output reg [127:0] mem_write_data
);

    // FSM state definitions
    localparam [3:0]
        IDLE       = 4'd0,
        LOOKUP     = 4'd1,
        CHECK      = 4'd2,
        READ_REQ   = 4'd3,
        READ_WAIT  = 4'd4,
        REFILL     = 4'd5,
        WRITE_REQ  = 4'd6,
        WRITE_WAIT = 4'd7,
        COMPLETE   = 4'd8;

    // Current state and next state
    reg [3:0] state;
    reg [3:0] next_state;

    // Registers to store CPU request
    reg [31:0] address_reg;
    assign cache_index  = address_reg[9:4];
    assign cache_tag_in = address_reg[31:10];
    reg write_reg;
    reg [127:0] write_data_reg;


    // Remember whether the read request was a cache miss
    reg miss_reg;

    // State register and CPU request capture
    always @(posedge clk) begin
        if (rst) begin
            state          <= IDLE;
            address_reg    <= 32'b0;
            write_reg      <= 1'b0;
            write_data_reg <= 128'b0;
            miss_reg       <= 1'b0;
        end
        else begin
            state <= next_state;

            // Capture CPU request when accepted
            if (state == IDLE && cpu_req) begin
                address_reg    <= cpu_addr;
                write_reg      <= cpu_write;
                write_data_reg <= cpu_write_data;
            end
            // Remember whether the cache lookup was a hit or miss
            if (state == CHECK) begin
                miss_reg <= !(valid_bit && tag_match);
            end
        end

    end


    // Next-state combinational logic
    always @(*) begin

        // Default: remain in current state
        next_state = state;

        case (state)

            IDLE: begin
                if (cpu_req)
                    next_state = LOOKUP;
            end

            LOOKUP: begin
                next_state = CHECK;
            end

            CHECK: begin
                if (valid_bit && tag_match) begin
                    if (write_reg)
                        next_state = WRITE_REQ;
                    else
                        next_state = COMPLETE;
                end
                else begin
                    if (write_reg)
                        next_state = WRITE_REQ;
                    else
                        next_state = READ_REQ;
                end
            end

            READ_REQ: begin
                next_state = READ_WAIT;
            end

            READ_WAIT: begin
                if (mem_ready)
                    next_state = REFILL;
            end

            REFILL: begin
                next_state = COMPLETE;
            end

            WRITE_REQ: begin
                next_state = WRITE_WAIT;
            end

            WRITE_WAIT: begin
                if (mem_ready)
                    next_state = COMPLETE;
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    // Output control logic
    always @(*) begin

        // Default output values
        cpu_ready       = 1'b0;
        cpu_read_data   = 128'b0;
        cache_data_in  = 128'b0;

        tag_we          = 1'b0;
        valid_we        = 1'b0;
        data_we         = 1'b0;
        valid_in        = 1'b0;

        mem_req         = 1'b0;
        mem_write_en    = 1'b0;
        mem_addr        = 28'b0;
        mem_write_data  = 128'b0;

        case (state)

            IDLE: begin
                // Wait for CPU request
            end
            LOOKUP: begin
                // Cache RAM read is initiated by the address/index
                // connected to the RAM modules.
            end
            CHECK: begin
                // Hit/miss decision is handled by next-state logic.
            end
            READ_REQ: begin
                mem_req      = 1'b1;
                mem_write_en = 1'b0;
                mem_addr     = address_reg[31:4];
            end
            READ_WAIT: begin
                // Wait for memory to complete the read request
                mem_req = 1'b0;
            end
            REFILL: begin
                // Store the returned memory block in cache
                data_we  = 1'b1;
                tag_we   = 1'b1;
                valid_we = 1'b1;
                valid_in = 1'b1;
                cache_data_in = mem_read_data;
            end

            WRITE_REQ: begin
                // Request a block write to main memory
                mem_req        = 1'b1;
                mem_write_en   = 1'b1;
                mem_addr       = address_reg[31:4];
                mem_write_data = write_data_reg;

                // Update cache only if this is a write hit
                if (valid_bit && tag_match) begin
                    data_we       = 1'b1;
                    cache_data_in = write_data_reg;
                end
            end
            WRITE_WAIT: begin
                // Wait for memory to complete the write request
                mem_req = 1'b0;
            end
            COMPLETE: begin
                cpu_ready = 1'b1;

                // Return data only for read operations
                if (!write_reg) begin
                    if (miss_reg)
                        cpu_read_data = mem_read_data;
                    else
                        cpu_read_data = cache_read_data;
                end
            end
        endcase

    end

endmodule

