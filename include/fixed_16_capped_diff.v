module fixed_16_capped_diff(
    input signed [15:0] a_in,      // Input operand A (Q8.8 format)
    input signed [15:0] b_in,      // Input operand B (Q8.8 format)
    output signed [15:0] next_val, // next value (Q8.8 format, 16 bits)
    output wire overflow,         // Flag for positive overflow (capped at max)
    output wire underflow_q       // Flag for negative underflow (capped at min)
);
    localparam integer FRACT_BITS = 8;

    localparam signed [15:0] Q8_8_MAX = 16'h7FFF; // Corresponds to 127.99609375
    localparam signed [15:0] Q8_8_MIN = 16'h8000; // Corresponds to -128.0
    wire signed [16:0] temp_result;
    
    assign temp_result = a_in - b_in;
    
    // Overflow/Underflow detection for the final 16-bit Q8.8 output
    assign overflow = (temp_result > Q8_8_MAX);
    assign underflow_q = (temp_result < Q8_8_MIN);
    
    // Capping wire
    assign next_val = overflow ? Q8_8_MAX :underflow_q ? Q8_8_MIN :temp_result[15:0];

endmodule