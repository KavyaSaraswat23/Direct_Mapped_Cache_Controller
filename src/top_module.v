module top_module (
    input wire clk,
    input wire rst,

    // CPU interface
    input wire cpu_req,
    input wire cpu_write,
    input wire [31:0] cpu_addr,
    input wire [127:0] cpu_write_data,
    output wire cpu_ready,
    output wire [127:0] cpu_read_data
);
    // Address decoder signals
    wire [21:0] tag;
    wire [5:0] index;
    wire [3:0] offset;

    // Cache status signals
    wire [21:0] stored_tag;
    wire valid_bit;
    wire [127:0] cache_read_data;
    wire cache_hit;

    // Cache controller signals
    wire tag_we;
    wire valid_we;
    wire data_we;
    wire valid_in;
    wire [5:0] cache_index;
    wire [21:0] cache_tag_in;
    wire [127:0] cache_data_in;

    // Main memory signals
    wire mem_req;
    wire mem_write_en;
    wire [27:0] mem_addr;
    wire [127:0] mem_write_data;
    wire [127:0] mem_read_data;
    wire mem_ready;

    // Address Decoder
    address_decoder decoder (
        .address(cpu_addr),
        .tag(tag),
        .index(index),
        .offset(offset)
    );

    // Cache Controller
    cache_controller controller (
        .clk(clk),
        .rst(rst),

        // CPU interface
        .cpu_req(cpu_req),
        .cpu_write(cpu_write),
        .cpu_addr(cpu_addr),
        .cpu_write_data(cpu_write_data),
        .cpu_ready(cpu_ready),
        .cpu_read_data(cpu_read_data),

        // Cache status
        .tag_match(cache_hit),
        .valid_bit(valid_bit),
        .cache_read_data(cache_read_data),

        // Cache control
        .tag_we(tag_we),
        .valid_we(valid_we),
        .data_we(data_we),
        .valid_in(valid_in),
        .cache_index(cache_index),
        .cache_tag_in(cache_tag_in),
        .cache_data_in(cache_data_in),

        // Main memory interface
        .mem_ready(mem_ready),
        .mem_read_data(mem_read_data),
        .mem_req(mem_req),
        .mem_write_en(mem_write_en),
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data)
    );
    // Cache Tag RAM
    cache_tag_ram tag_ram (
        .clk(clk),
        .we(tag_we),
        .index(cache_index),
        .tag_in(cache_tag_in),
        .tag_out(stored_tag)
    );
    // Cache Valid RAM
    cache_valid_ram valid_ram (
        .clk(clk),
        .rst(rst),
        .we(valid_we),
        .index(cache_index),
        .valid_in(valid_in),
        .valid_out(valid_bit)
    );
    // Cache Data RAM
    cache_data_ram data_ram (
        .clk(clk),
        .we(data_we),
        .index(cache_index),
        .data_in(cache_data_in),
        .data_out(cache_read_data)
    );
    // Tag Comparator
    tag_comparator comparator (
        .requested_tag(cache_tag_in),
        .stored_tag(stored_tag),
        .valid_bit(valid_bit),
        .cache_hit(cache_hit)
    );
    // Main Memory
    main_memory memory (
        .clk(clk),
        .rst(rst),
        .req(mem_req),
        .write_en(mem_write_en),
        .block_addr(mem_addr),
        .write_data(mem_write_data),
        .read_data(mem_read_data),
        .ready(mem_ready)
    );
endmodule