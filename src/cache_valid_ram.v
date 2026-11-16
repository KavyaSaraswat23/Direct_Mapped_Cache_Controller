
module cache_valid_ram (
    input wire clk,
    input wire rst,

    input wire we,
    input wire [5:0] index,
    input wire valid_in,

    output reg valid_out
);

    // 64 cache lines, each with one valid bit
    reg valid_mem [0:63];

    integer i;

    always @(posedge clk) begin

        // Reset all valid bits
        if (rst) begin
            for (i = 0; i < 64; i = i + 1) begin
                valid_mem[i] <= 1'b0;
            end

            valid_out <= 1'b0;
        end

        else begin

            // Update selected valid bit
            if (we) begin
                valid_mem[index] <= valid_in;
            end

            // Read valid bit
            valid_out <= valid_mem[index];

        end

    end

endmodule
