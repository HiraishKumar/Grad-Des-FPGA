module GrDes #(
    // GradDes_test
    parameter NUM_ITERATIONS = 50,
    parameter signed LEARNING_RATE_A = 32'h0000_0030,        // Decimal 0.125 Q24.8 format
    parameter signed LEARNING_RATE_B = 32'h0000_0030,        // Decimal 0.125 Q24.8 format
    parameter signed LEARNING_RATE_C = 32'h0000_0030,        // Decimal 0.125 Q24.8 format
    parameter signed LEARNING_RATE_D = 32'h0000_0030,        // Decimal 0.125 Q24.8 format
    parameter signed LOWER_CONV_BOUND = 32'hFFFF_FFC0,
    parameter signed UPPER_CONV_BOUND = 32'h0000_0040

) (
    input clk,
    input rst_n,
    input start_op,
    input signed [7:0] a_initial,         // 8 bit signed integer
    input signed [7:0] b_initial,         // 8 bit signed integer
    input signed [7:0] c_initial,         // 8 bit signed integer
    input signed [7:0] d_initial,         // 8 bit signed integer
    output reg signed [31:0] z_min,     // Q24.8 format
    output reg signed [7:0] final_a_at_min,     // 8 bit signed integer
    output reg signed [7:0] final_b_at_min,     // 8 bit signed integer
    output reg signed [7:0] final_c_at_min,     // 8 bit signed integer
    output reg signed [7:0] final_d_at_min,     // 8 bit signed integer
    output reg done_op
);
    wire signed [15:0] a_init;
    wire signed [15:0] b_init;
    wire signed [15:0] c_init;
    wire signed [15:0] d_init;

    assign a_init = {a_initial,8'd0};
    assign b_init = {b_initial,8'd0};
    assign c_init = {c_initial,8'd0};
    assign d_init = {d_initial,8'd0};


    // INTERNAL VARIABLE REG
    reg signed [15:0] a_in;     // Q8.8 format
    reg signed [15:0] b_in;     // Q8.8 format
    reg signed [15:0] c_in;     // Q8.8 format
    reg signed [15:0] d_in;     // Q8.8 format

    reg signed [15:0] a_at_min;
    reg signed [15:0] b_at_min;
    reg signed [15:0] c_at_min;
    reg signed [15:0] d_at_min;



    reg [$clog2(NUM_ITERATIONS + 1)-1 : 0] iter_count;

    // CONTROL SIGNALS
    wire has_converged;
    reg func_reset;     
    reg start_func;     
    reg converged; 

    reg signed [31:0] z_min_inter;
    reg signed [31:0] z_prev;

    reg signed [15:0] a_at_min_inter;
    reg signed [15:0] b_at_min_inter;
    reg signed [15:0] c_at_min_inter;
    reg signed [15:0] d_at_min_inter;

    // REGISTERS TO HOLD STATE
    reg [2:0] current_state;
    reg [2:0] next_state;

    // INTERNAL WIREs
    wire func_done;
    wire comp_result;

    wire [15:0] a_next_val;
    wire [15:0] b_next_val;
    wire [15:0] c_next_val;
    wire [15:0] d_next_val;

    wire [31:0] z_out;

    wire [15:0] a_diff_out;
    wire [15:0] b_diff_out;
    wire [15:0] c_diff_out;
    wire [15:0] d_diff_out;

    // STATE DEFINITION
    localparam IDLE     = 3'b000;
    localparam INIT     = 3'b001;
    localparam CALL_FUNC= 3'b010; 
    localparam CMP_STR  = 3'b011; // COMPARE AND STORE
    localparam DONE     = 3'b100;
        
    always @(*) begin 
        next_state = current_state;
        case (current_state)
            IDLE : begin 
                if (start_op) next_state = INIT;
            end
            INIT : begin 
                next_state = CALL_FUNC;
            end
            CALL_FUNC : begin 
                if (func_done) next_state = CMP_STR;
            end
            CMP_STR : begin
                if ((iter_count == NUM_ITERATIONS) | converged) begin
                    next_state = DONE;
                end else begin 
                    next_state = CALL_FUNC;
                end
            end
            DONE : begin 
                if (!start_op) next_state = IDLE;
            end
        endcase
    end

    //           IDLE---------( start_op == 1)--------->INIT
    //               ʌ                                    |    
    //               |       MOVE TO IDLE WHENEVER        |
    //               |         start_op is UNSET          |
    //       (start_op == 0 )                       CALL_FUNC<-----\
    //               ʌ                                    V        |            
    //               |                                    |        |
    //           DONE<---(iter_count == NUM_ITERATIONS)<--CMP_STR  |
    //                                                    |        ʌ
    //                                                    L > (iter_count < NUM_ITERATIONS)



    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin 
            current_state <= IDLE;
            a_in <= 16'd0;
            b_in <= 16'd0;
            c_in <= 16'd0;
            d_in <= 16'd0;

            a_at_min <= 16'd0;
            b_at_min <= 16'd0;
            c_at_min <= 16'd0;
            d_at_min <= 16'd0;

            a_at_min_inter <= 16'd0;    // Add this
            b_at_min_inter <= 16'd0;    // Add this
            c_at_min_inter <= 16'd0;    // Add this
            d_at_min_inter <= 16'd0;    // Add this

            z_min       <= 32'h7FFF_FFFF;
            z_min_inter <= 32'h7FFF_FFFF;       // Add this
            z_prev      <= 32'h8000_0000;       // Add this

            func_reset  <= 1'b0;        // Active Low Reset
            iter_count  <= 0;
            done_op     <= 1'b0;
            converged <= 1'b0;
        end else begin
            current_state <= next_state;
            case (current_state)
                IDLE : begin 
                    // DO NOTHING
                    done_op <= 1'b0;
                    converged <= 1'b0;
                    func_reset <= 1'b1; // Disassert Reset Of func
                end
                INIT : begin 
                    a_in <= a_init;
                    b_in <= b_init;
                    c_in <= c_init;
                    d_in <= d_init;

                    a_at_min <= a_init;
                    b_at_min <= b_init;
                    c_at_min <= c_init;
                    d_at_min <= d_init;

                    a_at_min_inter <= a_init;             // Add this
                    b_at_min_inter <= b_init;             // Add this
                    c_at_min_inter <= c_init;             // Add this
                    d_at_min_inter <= d_init;             // Add this

                    z_min<= 32'h7FFFFFFF;
                    z_min_inter <= 32'h7FFFFFFF;  // Add this
                    z_prev      <= 32'h8000_0000;

                    start_func <= 1'b1;    // assert Start
                    iter_count <= 0;
                    // func_reset <= 1'b0;    // Assert Reset
                end
                CALL_FUNC : begin 
                    if (func_done) begin
                        iter_count <= iter_count +1;

                        z_min_inter <= z_out;

                        a_at_min_inter <= a_in;
                        b_at_min_inter <= b_in;
                        c_at_min_inter <= c_in;
                        d_at_min_inter <= d_in;
                        
                        start_func <= 1'b0;    // Disassert Start
                        // func_reset <= 1'b0;    // Assert Reset
                    end else begin 
                        // Based on the assumption that it takes atleast one clock cycle
                        // for func to raise func_done or complete operation
                        z_prev <= z_min_inter;
                    end
                end
                CMP_STR : begin
                    if (comp_result) begin                        
                        z_min <= z_min_inter;

                        a_at_min <= a_at_min_inter; 
                        b_at_min <= b_at_min_inter; 
                        c_at_min <= c_at_min_inter; 
                        d_at_min <= d_at_min_inter; 
                        
                        if (has_converged) begin
                            converged <= 1'b1;
                        end
                    end 
                    a_in <= a_next_val;
                    b_in <= b_next_val;
                    c_in <= c_next_val;
                    d_in <= d_next_val;

                    start_func <= 1'b1;     // assert Start

                end
                DONE : begin 
                    done_op <= 1'b1;
                    func_reset <= 1'b0;    // Assert Reset
                    // start_func <= 1'b0;    // Disassert Start
                end
            endcase
        end
    end

    // MODULE CALLS

    // Ouputs the Gradient, value & Step size of 'function under test' at x_in 
    func_grad_val_diff #(
        .LEARNING_RATE_A (LEARNING_RATE_A ),
        .LEARNING_RATE_B (LEARNING_RATE_B ),
        .LEARNING_RATE_C (LEARNING_RATE_C ),
        .LEARNING_RATE_D (LEARNING_RATE_D )
    ) grad_val_diff (
        .clk(clk),
        .rst_n(func_reset),
        .start_func(start_func),
        .a_in(a_in),          // 32 bit Q24.8 foramt
        .b_in(b_in),          // 32 bit Q24.8 foramt
        .c_in(c_in),          // 32 bit Q24.8 foramt
        .d_in(d_in),          // 32 bit Q24.8 foramt
        .value(z_out),
        .a_diff_out(a_diff_out),
        .b_diff_out(b_diff_out),
        .c_diff_out(c_diff_out),
        .d_diff_out(d_diff_out),
        .func_done(func_done), 
        .overflow()
    );

    fixed_32_comp compare(
        .a_in(z_min_inter),
        .b_in(z_min),
        .comp_result(comp_result)   // out put 1 if z_min_inter < z_min
    );

    fixed_32_check_conv #(
        .LOWER_CONV_BOUND(LOWER_CONV_BOUND),
        .UPPER_CONV_BOUND(UPPER_CONV_BOUND)
    )check_conv(    // out put 1 if convergence is reached
        .a_in(z_out),
        .b_in(z_prev),
        .converged(has_converged)   // out put 1 if if (z_min_inter - z_min) ∈ (-0.0625, 0.0625)
    );

    fixed_16_capped_diff a_next(
        .a_in(a_in),
        .b_in(a_diff_out),
        .next_val(a_next_val),
        .overflow(),
        .underflow_q()
    );

    fixed_16_capped_diff b_next(
        .a_in(b_in),
        .b_in(b_diff_out),
        .next_val(b_next_val),
        .overflow(),
        .underflow_q()
    );

    fixed_16_capped_diff c_next(
        .a_in(c_in),
        .b_in(c_diff_out),
        .next_val(c_next_val),
        .overflow(),
        .underflow_q()
    );

    fixed_16_capped_diff d_next(
        .a_in(d_in),
        .b_in(d_diff_out),
        .next_val(d_next_val),
        .overflow(),
        .underflow_q()
    );

    snap_to_closest_int snap_a(
        .fixed_point_in(a_at_min),
        .rounded_integer_out(final_a_at_min)
    );
    snap_to_closest_int snap_b(
        .fixed_point_in(b_at_min),
        .rounded_integer_out(final_b_at_min)
    );
    snap_to_closest_int snap_c(
        .fixed_point_in(c_at_min),
        .rounded_integer_out(final_c_at_min)
    );
    snap_to_closest_int snap_d(
        .fixed_point_in(d_at_min),
        .rounded_integer_out(final_d_at_min)
    );
endmodule