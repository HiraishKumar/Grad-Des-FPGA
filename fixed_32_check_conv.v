module fixed_32_check_conv #(
    parameter signed LOWER_CONV_BOUND = 32'hFFFF_FFC0,
    parameter signed UPPER_CONV_BOUND = 32'h0000_0040

)(
    input signed [31:0] a_in,      // Input operand A (Q24.8)
    input signed [31:0] b_in,      // Input operand B (Q24.8)
    output wire converged    // Flag for convergence detection
    // if (a_in - b_in) ∈ (-0.0625, 0.0625)
);


wire less_than;
wire greater_than;
wire signed [31:0] diff;
assign diff = a_in - b_in;              // Diff between the two numbers

assign less_than    = LOWER_CONV_BOUND < diff;         //-0.0625 in decimal
assign greater_than = diff  < UPPER_CONV_BOUND;         // 0.0625 in decimal

// if the diff ∈ (-0.0625, 0.0625) then the output has converged   
assign converged = less_than & greater_than;    

endmodule