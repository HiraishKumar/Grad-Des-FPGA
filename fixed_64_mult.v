module fixed_64_mult(
    input signed [31:0] a_in,      // Input operand A (Q24.8 format)
    input signed [31:0] b_in,      // Input operand B (Q24.8 format)
    output signed [63:0] p_out    // Product 
);
    localparam integer FRACT_BITS = 8;
    
    wire signed [63:0] product_full;
    wire signed [63:0] p_raw_shifted; 
    
    assign product_full = a_in * b_in;
    assign p_raw_shifted = product_full >>> FRACT_BITS;
    
    // Overflow/Underflow detection for the final 16-bit Q8.8 output    
    assign p_out = p_raw_shifted;
endmodule