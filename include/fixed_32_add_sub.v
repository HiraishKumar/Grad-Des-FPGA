module fixed_32_add_sub(
    input signed [31:0] a_in,      // Input operand A (Q24.8)
    input signed [31:0] b_in,      // Input operand B (Q24.8)
    input               sub_n_add, // Control signal: 0 for Add, 1 for Subtract
    output signed [31:0] sum_diff_out, // Result (A+B or A-B) (Q24.8)
    output wire         overflow    // Flag for overflow detection
);
    wire signed [32:0] temp_result_wide; // 1 bit extra wide to deetect overflow 

    assign temp_result_wide = (sub_n_add == 1'b1) ?
                              ({{1{a_in[31]}}, a_in} - {{1{b_in[31]}}, b_in}) :
                              ({{1{a_in[31]}}, a_in} + {{1{b_in[31]}}, b_in});

    // Assign the lower 32 bits of the wide result to the output
    assign sum_diff_out = temp_result_wide[31:0];

    // Overflow detection
    assign overflow = (temp_result_wide[32] != sum_diff_out[31]);

endmodule
