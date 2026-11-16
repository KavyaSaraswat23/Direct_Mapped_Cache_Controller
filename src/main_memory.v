
module main_memory (

    input wire clk,
    input wire rst,

    input wire req,
    input wire write_en,

    input wire [27:0] block_addr,
    input wire [127:0] write_data,

    output reg [127:0] read_data,
    output reg ready

);

    // Simulation memory: 256 blocks of 128 bits
    reg [127:0] memory [0:255];

    integer i;

    // Initialize memory with deterministic data
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = {16{i[7:0]}};
        end
    end

    always @(posedge clk) begin

        if (rst) begin
            ready <= 1'b0;
            read_data <= 128'b0;
        end

        else begin

            // Default: ready is low
            ready <= 1'b0;

            if (req) begin

                if (write_en) begin

                    // Write block to main memory
                    memory[block_addr[7:0]] <= write_data;

                end

                else begin

                    // Read block from main memory
                    read_data <= memory[block_addr[7:0]];

                end

                // Signal operation completion
                ready <= 1'b1;

            end

        end

    end

endmodule
