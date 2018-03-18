/* All Apple ][e variants include a single PAL that derives clock from the
 * main 14.318MHz system clock and generates other timing-critical control
 * signals.
 */

module AppleIIePAL(
    input clk_14M,

    output reg clk_7M,
    output clk_3_58M,
    output reg clk_q3,
    output clk_phi_0,

    // RAM address strobes
    input clk_phi_1,
    input ramen_n,
    output reg pcas_n,
    output reg pras_n,

    input vid7,
    input gr,
    input eighty_vid_n,
    input entmg,

    output h0,
    output segb,
    output ldps_n,
    output vid7m
    );
endmodule
