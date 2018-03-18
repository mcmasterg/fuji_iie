/* Target-specific adapter for Digilent Basys3
 *
 * Implementation notes:
 *  - 14.318MHz system clock is derived from 100MHz osciallator using 7-series PLL
 */

module Basys3FujiIIe(
    input clk_100MHz,
    input button_reset
    );

    wire clk_14M;

    Basys3ClockGenerator clock_generator(
        .clk_100MHz(clk_100MHz),
        .clk_14M(clk_14M),
        .reset(button_reset)
    );

    FujiIIe motherboard(
        .clk_core(clk_100MHz),
        .clk_14M(clk_14M),
        .reset(button_reset),
    );
    
endmodule
