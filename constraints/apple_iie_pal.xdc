create_generated_clock -source [get_ports clk_14M] -divide_by 2 [get_ports clk_7M]
create_generated_clock -source [get_ports clk_14M] -divide_by 14 [get_ports clk_phi_0]
create_generated_clock -source [get_ports clk_14M] -edges {1 9 14} [get_ports clk_q3]
