
module tag_comparator (

    input wire [21:0] requested_tag,
    input wire [21:0] stored_tag,

    input wire valid_bit,

    output wire cache_hit

);

    // Cache hit occurs only when
    // valid bit is 1 and both tags match

    assign cache_hit = valid_bit &&
                       (requested_tag == stored_tag);

endmodule
