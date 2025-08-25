module func(
    input clk,
    input rst_n,
    input start_func,
    input signed [15:0] a_in,       // Q8.8 format
    input signed [15:0] b_in,       // Q8.8 format
    input signed [15:0] c_in,       // Q8.8 format
    input signed [15:0] d_in,       // Q8.8 format
    output reg signed [31:0] z_out, // Q24.8 format
    output reg func_done,
    output reg overflow
);
    // func is assumed to be (a-2)^2 + (c+2)^2 + (2d)^2 + (b^2 - 5)
    // Terminology :
    //              term1 = (b^2 - 5)           
    //              term2 = (2d)^2
    //              term3 = (c+2)^2
    //              term4 = (a-2)^2

    // Sub Modules:
    //           fixed_32_mult:
    //               takes in two 32 bit Q24.8 inputs a_in and b_in
    //               produces a 32 bit Q24.8 product p_out.
    //               it has underflow and overflow outputs
    //           fixed_32_add_sub:
    //               takes in two 32 bit Q24.8 inputs a_in and b_in
    //               produces a 32 bit Q24.8 sum or diff sum_diff_out,
    //               depending on control signal sub_n_add, 0 for add, 1 for sub .
    //               it has overflow outputs

    // STAGE 1 - MULT: b^2, 2*d
    // STAGE 1 - SUM : a-2, c+2 

    // STAGE 2 - MULT: (a-2)^2, (c+2)^2, (2d)^2
    // STAGE 2 - SUM : b^2 - 5

    // STAGE 3 - MULT: --NIL--
    // STAGE 3 - SUM : ((a-2)^2 + (c+2)^2) , ((2d)^2 + (b^2 - 5))
    
    // STAGE 4 - MULT: --NIL--
    // STAGE 4 - SUM : ((a-2)^2 + (c+2)^2) + ((2d)^2 + (b^2 - 5))
    
    localparam IDLE         = 3'b000;
    localparam INIT         = 3'b001;
    localparam COMP_1       = 3'b010;
    localparam COMP_2       = 3'b011;
    localparam COMP_3       = 3'b100;
    localparam DONE         = 3'b101;


    localparam MINUS_FIVE   = 32'hFFFFFB00;
    localparam MINUS_TWO    = 32'hFFFFFE00;
    localparam PLUS_FIVE    = 32'h00000500;
    localparam PLUS_TWO     = 32'h00000200;

    reg signed [15:0] a_in_buffer;          // Q8.8 format, input variable
    reg signed [15:0] b_in_buffer;          // Q8.8 format, input variable
    reg signed [15:0] c_in_buffer;          // Q8.8 format, input variable
    reg signed [15:0] d_in_buffer;          // Q8.8 format, input variable

    wire signed [31:0] term1_partial;       // Q24.8 format, wire storing partial calc
    wire signed [31:0] term2_partial;       // Q24.8 format, wire storing partial calc
    wire signed [31:0] term3_partial;       // Q24.8 format, wire storing partial calc
    wire signed [31:0] term4_partial;       // Q24.8 format, wire storing partial calc
    
    reg signed [31:0] term1_partial_reg;    // Q24.8 format, registered partial at the end of calc
    reg signed [31:0] term2_partial_reg;    // Q24.8 format, registered partial at the end of calc
    reg signed [31:0] term3_partial_reg;    // Q24.8 format, registered partial at the end of calc
    reg signed [31:0] term4_partial_reg;    // Q24.8 format, registered partial at the end of calc

    wire signed [31:0] term1;               // Q24.8 format, wire storing calculated term
    wire signed [31:0] term2;               // Q24.8 format, wire storing calculated term
    wire signed [31:0] term3;               // Q24.8 format, wire storing calculated term
    wire signed [31:0] term4;               // Q24.8 format, wire storing calculated term
    
    reg signed [31:0] term1_reg;            // Q24.8 format, registered calculated term
    reg signed [31:0] term2_reg;            // Q24.8 format, registered calculated term
    reg signed [31:0] term3_reg;            // Q24.8 format, registered calculated term
    reg signed [31:0] term4_reg;            // Q24.8 format, registered calculated term

    wire signed [31:0] term1_plus_term2;    // Q24.8 format, wire summations of term1 and term2 
    wire signed [31:0] term3_plus_term4;    // Q24.8 format, wire summations of term3 and term4

    reg signed [31:0] term1_plus_term2_reg; // Q24.8 format, registered summations of term1 and term2
    reg signed [31:0] term3_plus_term4_reg; // Q24.8 format, registered summations of term3 and term4
    
    wire signed [31:0] final_value;         // Q24.8 format, wire summations of all terms


    reg [2:0] curr_state;
    reg [2:0] next_state;



always @(*) begin
    next_state = curr_state;
    case (curr_state)
        IDLE        : begin if (start_func)  next_state = INIT; end
        INIT        : begin next_state = COMP_1; end
        COMP_1      : begin next_state = COMP_2; end
        COMP_2      : begin next_state = COMP_3; end
        COMP_3      : begin next_state = DONE; end
        DONE        : begin if (!start_func) next_state = IDLE; end
        default     : begin next_state = IDLE; end
    endcase
end

    always @(posedge clk, negedge rst_n) begin 
        if (!rst_n) begin
            a_in_buffer         <=  16'd0;
            b_in_buffer         <=  16'd0;
            c_in_buffer         <=  16'd0;
            d_in_buffer         <=  16'd0;
            z_out               <=  32'd0;

            curr_state          <=  IDLE;
            func_done           <=  1'b0;
            overflow            <=  1'b0;

            term1_partial_reg   <=  32'd0;   
            term2_partial_reg   <=  32'd0;
            term3_partial_reg   <=  32'd0;
            term4_partial_reg   <=  32'd0;

            term1_reg           <=  32'd0;
            term2_reg           <=  32'd0;
            term3_reg           <=  32'd0;
            term4_reg           <=  32'd0;

            term1_plus_term2_reg<=  32'd0;
            term3_plus_term4_reg<=  32'd0;
            // final_value         <=  32'd0;
        end else begin
            curr_state <= next_state;
            case (curr_state)
                IDLE: begin 
                    // DO NOTHING
                    func_done <= 1'b0; 
                end
                INIT: begin     
                    a_in_buffer <= a_in;
                    b_in_buffer <= b_in;
                    c_in_buffer <= c_in;
                    d_in_buffer <= d_in;
                    // Computation of Stage 1 Begin
                end
                COMP_1: begin
                    // Computation of Stage 1 registered   
                    term1_partial_reg <= term1_partial;
                    term2_partial_reg <= term2_partial;
                    term3_partial_reg <= term3_partial;
                    term4_partial_reg <= term4_partial;
                    // Computation of Stage 2 Begin 
                end             

                COMP_2: begin
                    // Computation of Stage 2 registered   
                    term1_reg <= term1;
                    term2_reg <= term2;
                    term3_reg <= term3;
                    term4_reg <= term4;
                    // Computation of Stage 3 Begin        
                end     

                COMP_3: begin
                    // Computation of Stage 3 registered   
                    term1_plus_term2_reg <= term1_plus_term2;
                    term3_plus_term4_reg <= term3_plus_term4;
                    // Computation of Stage 4 Begin
                end             
                DONE: begin
                    // Computation of Stage 4 registered   
                    z_out <= final_value;
                    func_done <= 1'b1;
                end             
            endcase
        end
    end



    //-----------------------STAGE 1 ----------------------------
    fixed_32_mult t1_par(       // Calculate b^2
        .a_in({{16{b_in_buffer[15]}},b_in_buffer}),  // 16 bit input sign extended to 32
        .b_in({{16{b_in_buffer[15]}},b_in_buffer}),  // 16 bit input sign extended to 32
        .p_out(term1_partial),
        .overflow(),
        .underflow_q() 
    );


    fixed_32_mult t2_par(       // Calculate 2*d
        .a_in({{16{d_in_buffer[15]}},d_in_buffer}) , // 16 bit input sign extended to 32
        .b_in(PLUS_FIVE),                            // Constant
        .p_out(term2_partial),
        .overflow(),
        .underflow_q()
    );

    fixed_32_add_sub t3_par(    // Calculate c + 2
        .a_in({{16{c_in_buffer[15]}},c_in_buffer}), // Input buffered into register
        .b_in(PLUS_TWO),                            // Constant
        .sub_n_add(1'b0),
        .sum_diff_out(term3_partial),   // Wire Output registed at next clock edge for the next stage
        .overflow()
    );
    
    fixed_32_add_sub t4_par(    // Calculate a - 2
        .a_in({{16{a_in_buffer[15]}},a_in_buffer}),// Input buffered into register
        .b_in(PLUS_TWO),                           // Constant
        .sub_n_add(1'b1),
        .sum_diff_out(term4_partial),   // Wire Output registed at next clock edge for the next stage           
        .overflow()
    );

    //-----------------------STAGE 1 ----------------------------

    //-----------------------STAGE 2 ----------------------------


    fixed_32_add_sub t1(    // Calculate b^2 - 5
        .a_in(term1_partial_reg),                   // Registered Input from prior stage
        .b_in(PLUS_FIVE),                          // Constant
        .sub_n_add(1'b1),
        .sum_diff_out(term1),   // Wire Output registed at next clock edge for the next stage
        .overflow()
    );

    fixed_32_mult t2(       // Calculate (2*d)^2
        .a_in(term2_partial_reg),                    // Registered Input from prior stage
        .b_in(term2_partial_reg),                    // Registered Input from prior stage
        .p_out(term2),       // Wire Output registed at next clock edge for the next stage
        .overflow(),
        .underflow_q()
    );

    fixed_32_mult t3(       // Calculate (c + 2)^2
        .a_in(term3_partial_reg),                    // Registered Input from prior stage
        .b_in(term3_partial_reg),                    // Registered Input from prior stage
        .p_out(term3),       // Wire Output registed at next clock edge for the next stage
        .overflow(),
        .underflow_q()
    );

    fixed_32_mult t4(       // Calculate (a - 2)^2
        .a_in(term4_partial_reg),                    // Registered Input from prior stage
        .b_in(term4_partial_reg),                    // Registered Input from prior stage
        .p_out(term4),       // Wire Output registed at next clock edge for the next stage
        .overflow(),
        .underflow_q()
    );

    //-----------------------STAGE 2 ----------------------------
    
    //-----------------------STAGE 3 ----------------------------
    fixed_32_add_sub t1_sum_t2(    //Calculate (b^2 - 5) + (2*d)^2
        .a_in(term1_reg),                           // Registered Input from prior stage
        .b_in(term2_reg),                           // Registered Input from prior stage
        .sub_n_add(1'b0),
        .sum_diff_out(term1_plus_term2),    // Wire Output registed at next clock edge for the next stage
        .overflow()
    );    
    
    fixed_32_add_sub t3_sum_t4(    // Calculate (c+2)^2 + (a-2)^2
        .a_in(term3_reg),                           // Registered Input from prior stage
        .b_in(term4_reg),                           // Registered Input from prior stage
        .sub_n_add(1'b0),
        .sum_diff_out(term3_plus_term4),    // Wire Output registed at next clock edge for the next stage
        .overflow()
    );

    //-----------------------STAGE 3 ----------------------------

    //-----------------------STAGE 4 ----------------------------
    
    fixed_32_add_sub final_val(    // Calculate ((a-2)^2 + (c+2)^2) + ((2d)^2 + (b^2 - 5))
        .a_in(term1_plus_term2_reg),                // Registered Input from prior stage
        .b_in(term3_plus_term4_reg),                // Registered Input from prior stage
        .sub_n_add(1'b0),
        .sum_diff_out(final_value),     // Wire Output registed at next clock edge for the next stage
        .overflow()
    );

    //-----------------------STAGE 4 ----------------------------


endmodule