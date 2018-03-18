/* Target-specific adapter for Digilent Basys3
 *
 * Implementation notes:
 */

module Basys3FujiIIe(
    input clk_100MHz,
    input button_reset
    );

    wire clk_14M;

    FujiIIe motherboard(
        .clk_core(clk_100MHz),
        .clk_14M(clk_14M),
        .reset(button_reset),
    );
    
endmodule
