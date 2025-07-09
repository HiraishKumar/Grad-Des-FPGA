module fixed_64_clamp(
    input signed [63:0] a_in,      // Input operand A (Q56.8 format)
    output signed [15:0] b_out,    // Product P (Q8.8 format, 16 bits)
    output wire overflow,         // Flag for positive overflow (capped at max)
    output wire underflow_q       // Flag for negative underflow (capped at min)
);
    localparam signed [15:0] Q8_8_MAX = 16'h7FFF; // Corresponds to 127.99609375
    localparam signed [15:0] Q8_8_MIN = 16'h8000; // Corresponds to -128.0
    
    localparam signed [63:0] Q8_8_MAX_EXT = 64'h0000_0000_0000_7FFF;
    localparam signed [63:0] Q8_8_MIN_EXT = 64'hFFFF_FFFF_FFFF_8000;
    
    // Overflow/Underflow detection for the final 16-bit Q8.8 output
    assign overflow = (a_in > Q8_8_MAX_EXT);
    assign underflow_q = (a_in < Q8_8_MIN_EXT);
    
    // Capping wire
    assign b_out = overflow ? Q8_8_MAX :underflow_q ? Q8_8_MIN :a_in[15:0];

endmodule