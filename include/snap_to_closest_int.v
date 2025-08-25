module snap_to_closest_int (
    input wire signed [15:0] fixed_point_in,    // 8.8 signed fixed point input
    output wire signed [7:0] rounded_integer_out       // 8-bit signed integer output
);
    localparam signed [7:0] MAX_8_BIT = 8'h7F; 
    localparam signed [15:0] MAX_8_BIT_16 = 16'h7F00; // Represents 127.0 in 8.8 fixed-point
    localparam signed [15:0] OVERFLOW_CONST = 16'h007F; // Represents a value slightly less than 0.5

    wire signed [16:0] temp_res; 
    wire overflow; 
    wire signed [7:0] truncated_integer; 
    assign temp_res = fixed_point_in + OVERFLOW_CONST; 

    assign overflow = (fixed_point_in > MAX_8_BIT_16);
    assign truncated_integer = temp_res[15:8];
    assign rounded_integer_out = overflow ? MAX_8_BIT : truncated_integer;
endmodule