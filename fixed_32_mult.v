module fixed_32_mult(
    input signed [31:0] a_in,    // Input operand A (Q24.8 format)
    input signed [31:0] b_in,    // Input operand B (Q24.8 format)
    output signed [31:0] p_out,  // Product P (Q24.8 format)
    output wire overflow,        // Flag for overflow detection
    output wire underflow_q       // Flag for underflow detection (going below minimum negative)
);

    localparam integer FRACT_BITS = 8;
    wire signed [63:0] product_full;

    assign product_full = a_in * b_in;
    assign p_out = product_full >>> FRACT_BITS;

    wire expected_sign = p_out[31]; // The sign bit of the result
    wire [23:0] msb_of_product_full = product_full[63:40]; // 63 - 40 + 1 = 24 bits
    assign overflow = (expected_sign == 1'b0) && (|msb_of_product_full); // Positive overflow if any MSB is 1
    assign underflow_q = (expected_sign == 1'b1) && (~(&msb_of_product_full)); // Negative overflow/underflow if any MSB is 0


endmodule