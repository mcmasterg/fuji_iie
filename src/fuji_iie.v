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
    input [7:0] monitor_rom_d,

/*
    // Character generator ROM socket
    input chargen_rom_oe_n,
    input chargen_rom_ce_n,
    output [11:0] chargen_rom_a,
    input [7:0] chargen_rom_d,
*/

    // Main RAM
    output [7:0] main_ram_ra,
    output main_ram_ras_n,
    output main_ram_cas_n,
    output main_ram_rw_n,
    inout [7:0] main_ram_d,

    // Aux Slot
    output aux_clk_14M,
    output aux_clk_7M,
    output aux_clk_3_58M,
    output aux_clk_phi_0,
    output aux_clk_phi_1,
    output aux_clk_q3,
    output aux_romen1_n,
    output aux_romen2_n,
    output aux_ramen_n,
    output [7:0] aux_ra,
    output aux_rw_n,
    output aux_pras_n,
    output aux_pcas_n,
    output [7:0] aux_md,
    output [3:0] aux_an,
    output aux_frctxt_n,
    output aux_gr,
    output aux_c0xx_n,
    output aux_rw80_n,
    output aux_serout_n,
    output aux_sync_n,
    output aux_ldps_n,
    output aux_h0,
    output aux_wndw_n,
    output aux_altvid_n,
    output aux_envid_n,
    output [7:0] aux_vid,
    output aux_eighty_vid_n,
    output aux_en80_n,
    output aux_sega,
    output aux_segb,
    output aux_vc,
    output aux_ra9_n,
    output aux_ra10_n,
    output aux_clrgat_n,
    output aux_vid7m,
    output aux_entmg_n
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

/*
    wire nmi_n;
    wire irq_n;
 */

    // RAM Bus
    wire ramen_n;
    wire pras_n;
    wire pcas_n;
    wire [7:0] ra;
/*
    // Video control signals
    wire ra9_n;
    wire ra10_n;
    wire wndw_n;
    wire envid_n;
    wire gr;
    wire sega;
    wire segb;
    wire vc;
*/

    MCL65 cpu(
        .CORE_CLK(clk_core),
        .CLK0(clk_phi_0),
        .CLK1(clk_phi_1),
        .CLK2(clk_phi_2),
        .RESET_n(~reset),
        .NMI_n(1'b1),
        .IRQ_n(1'b1),
        .SO(1'b0),
        .SYNC(),
        .RDWR_n(rdwr_n),
        .READY(1'b1),
        .A(a),
        .D(md),
        .DIR0(),
        .DIR1()
    );

    AppleIIePAL pal(
        .clk_14M(clk_14M),

        .clk_7M(clk_7M),
        .clk_3_58M(aux_clk_3_58M),
        .clk_q3(clk_q3),
        .clk_phi_0(clk_phi_0),

        .clk_phi_1(clk_phi_1),
        .ramen_n(ramen_n),
        .pras_n(pras_n),
        .pcas_n(pcas_n)
    );

    AppleIIeMemoryManagementUnit mmu(
        .clk_phi_0(clk_phi_0),
        .clk_q3(clk_q3),

        .a(a),
        .md7(md[7]),
        .rw_n(rdwr_n),

        .inh_n(1'b1),

        .ramen_n(ramen_n),
        .pras_n(pras_n),
        .ra(ra),

        .romen1_n(romen1_n),
        .romen2_n(romen2_n)
    );

/*
    AppleIIeInputOutputUnit iou(
        .clk_phi_0(clk_phi_0),
        .clk_q3(clk_q3),
        .reset_n(~reset),

        .a6(a[6]),
        .rw_n(rdwr_n),
        .md7(md[7]),

        .pras_n(pras_n),
        .ra(ra),

        .ra9_n(ra9_n),
        .ra10_n(ra10_n),
        .gr(gr),
        .vc(vc),
        .sega(sega),
        .segb(segb)
    );
    */

    assign diagnostics_rom_ce_n = 1'b0;
    assign diagnostics_rom_oe_n = romen1_n;
    assign diagnostics_rom_a = a[12:0];
    assign diagnostics_rom_d = md;

    assign monitor_rom_ce_n = 1'b0;
    assign monitor_rom_oe_n = romen2_n;
    assign monitor_rom_a = a[12:0];
    assign monitor_rom_d = md;

/*
    assign chargen_rom_ce_n = envid_n;
    //assign chargen_rom_a = {gr, ~ra10, ~ra9, vid[5:0], vc, segb, sega};
    //assign chargen_rom_d = data_bus;
    assign chargen_rom_oe_n = wndw_n;
    */

    assign main_ram_ra = ra;
    assign main_ram_ras_n = pras_n;
    assign main_ram_cas_n = pcas_n;
    assign main_ram_d = md;
    
    assign aux_clk_14M = clk_14M;
    assign aux_clk_7M = clk_7M;
    assign aux_clk_q3 = clk_q3;
    assign aux_clk_phi_0 = clk_phi_0;
    assign aux_clk_phi_1 = clk_phi_1;
    assign aux_romen1_n = romen1_n;
    assign aux_romen2_n = romen2_n;
    assign aux_ramen_n = ramen_n;
    assign aux_rw_n = rdwr_n;
    assign aux_ra = ra;
    assign aux_pras_n = pras_n;
    assign aux_pcas_n = pcas_n;
    assign aux_md = md;
endmodule
