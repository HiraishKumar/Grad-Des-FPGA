module fixed_32_capped_mult(
    input signed [31:0] a_in,      // Input operand A (Q24.8 format)
    input signed [31:0] b_in,      // Input operand B (Q24.8 format)
    output signed [15:0] p_out,    // Product P (Q8.8 format, 16 bits)
    output wire overflow,         // Flag for positive overflow (capped at max)
    output wire underflow_q       // Flag for negative underflow (capped at min)
);
    localparam integer FRACT_BITS = 8;

    localparam signed [15:0] Q8_8_MAX = 16'h7FFF; // Corresponds to 127.99609375
    localparam signed [15:0] Q8_8_MIN = 16'h8000; // Corresponds to -128.0
    
    localparam signed [63:0] Q8_8_MAX_EXT = 64'h0000_0000_0000_7FFF;
    localparam signed [63:0] Q8_8_MIN_EXT = 64'hFFFF_FFFF_FFFF_8000;
    
    wire signed [63:0] product_full;
    wire signed [63:0] p_raw_shifted; 
    
    assign product_full = a_in * b_in;
    assign p_raw_shifted = product_full >>> FRACT_BITS;
    
    // Overflow/Underflow detection for the final 16-bit Q8.8 output
    assign overflow = (p_raw_shifted > Q8_8_MAX_EXT);
    assign underflow_q = (p_raw_shifted < Q8_8_MIN_EXT);
    
    // Capping wire
    assign p_out = overflow ? Q8_8_MAX :underflow_q ? Q8_8_MIN :p_raw_shifted[15:0];

endmodule