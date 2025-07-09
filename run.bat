iverilog -g2012 -o Top_tb.out fixed_16_capped_diff.v snap_to_closest_int.v fixed_32_check_conv.v fixed_32_add_sub.v fixed_32_capped_mult.v fixed_32_comp.v fixed_32_mult.v fixed_64_mult.v func.v func_grad_val_diff.v fixed_64_clamp.v GrDes.v Top_tb.v
vvp Top_tb.out
gtkwave Top_tb.vcd -a Top_tb.gtkw