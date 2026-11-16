module cache_tag_ram (
    input wire clk,
    input wire we,

    input wire [5:0] index,
    input wire [21:0] tag_in,

    output reg [21:0] tag_out
);

    // 64 cache lines, each storing a 22-bit tag
    reg [21:0] tag_mem [0:63];

    always @(posedge clk) begin

        // Write tag into selected cache line
        if (we) begin
            tag_mem[index] <= tag_in;
        end

        // Read tag from selected cache line
        tag_out <= tag_mem[index];

    end

endmodule
