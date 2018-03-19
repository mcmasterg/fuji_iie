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
    input reset,

    // Diagnostics ROM socket
    output diagnostics_rom_ce_n,
    output diagnostics_rom_oe_n,
    output [12:0] diagnostics_rom_a,
    input [7:0] diagnostics_rom_d,

    // Monitor ROM socket
    output monitor_rom_ce_n,
    output monitor_rom_oe_n,
    output [12:0] monitor_rom_a,
    input [7:0] monitor_rom_d
    );

    wire clk_7M;
    wire clk_q3;
    wire clk_phi_0;
    wire clk_phi_1;
    wire clk_phi_2;

    // Processor memory bus
    wire [15:0] a;
    wire [7:0] md;
    wire rdwr_n;

    wire romen1_n;
    wire romen2_n;

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
        .RDWR_n(rdwr_n),
        .READY(),
        .A(a),
        .D(md),
        .DIR0(),
        .DIR1()
    );

    AppleIIePAL pal(
        .clk_14M(clk_14M),

        .clk_7M(clk_7M),
        .clk_q3(clk_q3),
        .clk_phi_0(clk_phi_0)
    );

    AppleIIeMemoryManagementUnit mmu(
        .clk_phi_0(clk_phi_0),
        .clk_q3(clk_q3),

        .a(a),
        .md7(md[7]),
        .rw_n(rdwr_n),

        .inh_n(1'b1),

        .romen1_n(romen1_n),
        .romen2_n(romen2_n)
    );

    assign diagnostics_rom_ce_n = 1'b0;
    assign diagnostics_rom_oe_n = romen1_n;
    assign diagnostics_rom_a = a[12:0];
    assign diagnostics_rom_d = md;

    assign monitor_rom_ce_n = 1'b0;
    assign monitor_rom_oe_n = romen2_n;
    assign monitor_rom_a = a[12:0];
    assign monitor_rom_d = md;
endmodule
