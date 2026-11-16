module cache_data_ram (
    input wire clk,

    input wire we,
    input wire [5:0] index,

    input wire [127:0] data_in,

    output reg [127:0] data_out
);

    // 64 cache lines, each storing 128 bits
    reg [127:0] data_mem [0:63];

    always @(posedge clk) begin

        // Write data into selected cache line
        if (we) begin
            data_mem[index] <= data_in;
        end

        // Read data from selected cache line
        data_out <= data_mem[index];

    end

endmodule
