module fixed_32_comp(
    input signed [31:0] a_in,      // Input operand A (Q24.8)
    input signed [31:0] b_in,      // Input operand B (Q24.8)
    output wire comp_result       // output 1 if a_in < b_in, else 0
);
    assign comp_result = a_in < b_in;
endmodule
