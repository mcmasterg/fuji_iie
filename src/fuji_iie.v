/*
 * Fuji IIe is intended to be portable across FPGA dev boards and FPGA
 * families.  As such, FujiIIe module implements a virtual Apple ][e
 * motherboard as close to the original hardware as makes sense.
 * Target-specific details such as how to obtain a 14.318MHz clock and
 * how external I/O ports are mapped to target hardware are explicitly ignored
 * here and expected to be handled in a per-target top module that instances
 * FujiIIe.
 *
 * Once minor quirk is that ROMs and RAMs are modeled as sockets exposing the
 * signals to the per-target layer. This is an intentional choice as the best
 * implementation for these devices will depend on the target.  For example,
 * most Xilinx 7-series parts should have sufficient Block RAMs to implement
 * all ROMs and RAMs entirely within the part. A Spartan-3, on the other hand,
 * does not and will require an external RAM.
 */

module FujiIIe(
    input clk_core,
    input clk_14M,
    input reset
    );

    wire clk_7M;
    wire clk_q3;
    wire clk_phi_0;
    wire clk_phi_1;
    wire clk_phi_2;

    MCL65 cpu(
        .CORE_CLK(clk_core),
        .CLK0(clk_phi_0),
        .CLK1(clk_phi_1),
        .CLK2(clk_phi_2),
        .RESET_n(~reset),
        .NMI_n(),
        .IRQ_n(),
        .SO(),
        .SYNC(),
        .RDWR_n(),
        .READY(),
        .A(),
        .D(),
        .DIR0(),
        .DIR1()
    );

    AppleIIePAL pal(
        .clk_14M(clk_14M),

        .clk_7M(clk_7M),
        .clk_q3(clk_q3),
        .clk_phi_0(clk_phi_0)
    );
    
endmodule
