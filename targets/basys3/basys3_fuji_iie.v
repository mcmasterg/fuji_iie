/* Target-specific adapter for Digilent Basys3
 *
 * Implementation notes:
 *  - Clocks derived from 100MHz osciallator using 7-series PLL
 *    - 100MHz Basys3 system components clock
 *    - 14.318MHz Apple IIe system clock
 *  - ROMs are implmented using the Rom module which will infer block RAMs
 */

module Basys3FujiIIe(
    input clk_in_100MHz,
    input button_reset,
    
    // Aux Slot
    output aux_clk_3_58M,
    output aux_clk_7M,
    output aux_romen1_n,
    output aux_romen2_n,
    output [3:0] aux_an,
    output aux_ramen_n,
    output aux_frctxt_n,
    output aux_gr,
    output aux_c0xx_n,
    output [7:0] aux_md,
    output aux_pras_n,
    output aux_clk_phi_0,
    output aux_rw80_n,
    output aux_clk_phi_1,
    output aux_clk_q3,
    output aux_serout_n,
    output aux_clk_14M,
    output aux_sync_n,
    output aux_ldps_n,
    output aux_h0,
    output aux_pcas_n,
    output aux_wndw_n,
    output aux_altvid_n,
    output aux_envid_n,
    output aux_rw_n,
    output [7:0] aux_vid,
    output aux_eighty_vid_n,
    output aux_en80_n,
    output [7:0] aux_ra,
    output aux_sega,
    output aux_segb,
    output aux_vc,
    output aux_ra9_n,
    output aux_ra10_n,
    output aux_clrgat_n,
    output aux_vid7m,
    output aux_entmg_n
    );

    wire clk_100M;
    wire clk_14M;

    Basys3ClockGenerator clock_generator(
        .clk_in_100MHz(clk_in_100MHz),
        .clk_100M(clk_100M),
        .clk_14M(clk_14M),
        .reset(button_reset)
    );

    // Diagnostics ROM socket
    wire diagnostics_rom_ce_n;
    wire diagnostics_rom_oe_n;
    wire [12:0] diagnostics_rom_a;
    wire [7:0] diagnostics_rom_d;

    // Monitor ROM socket
    wire monitor_rom_ce_n;
    wire monitor_rom_oe_n;
    wire [12:0] monitor_rom_a;
    wire [7:0] monitor_rom_d;

    Rom #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(8192),
        .INIT_FILE("apple_iie_diagnostics_rom.mem")
    ) diagnostics_rom (
        .clka(clk_14M),
        .addra(diagnostics_rom_a),
        .ena(~diagnostics_rom_ce_n),
        .oe(~diagnostics_rom_oe_n),
        .douta(diagnostics_rom_d)
    );

    Rom #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(8192),
        .INIT_FILE("apple_iie_monitor_rom.mem")
    ) monitor_rom (
        .clka(clk_14M),
        .addra(monitor_rom_a),
        .ena(~monitor_rom_ce_n),
        .oe(~monitor_rom_oe_n),
        .douta(monitor_rom_d)
    );

    FujiIIe motherboard(
        .clk_core(clk_100M),
        .clk_14M(clk_14M),
        .reset(button_reset),

        .diagnostics_rom_ce_n(diagnostics_rom_ce_n),
        .diagnostics_rom_oe_n(diagnostics_rom_oe_n),
        .diagnostics_rom_a(diagnostics_rom_a),
        .diagnostics_rom_d(diagnostics_rom_d),

        .monitor_rom_ce_n(monitor_rom_ce_n),
        .monitor_rom_oe_n(monitor_rom_oe_n),
        .monitor_rom_a(monitor_rom_a),
        .monitor_rom_d(monitor_rom_d),
       
       	// Aux Slot	
        .aux_clk_3_58M(aux_clk_3_58M),
        .aux_clk_7M(aux_clk_7M),
        .aux_romen1_n(aux_romen1_n),
        .aux_romen2_n(aux_romen2_n),
        .aux_an(aux_an),
        .aux_ramen_n(aux_ramen_n),
        .aux_frctxt_n(aux_frctxt_n),
        .aux_gr(aux_gr),
        .aux_c0xx_n(aux_c0xx_n),
        .aux_md(aux_md),
        .aux_pras_n(aux_pras_n),
        .aux_clk_phi_0(aux_clk_phi_0),
        .aux_rw80_n(aux_rw80_n),
        .aux_clk_phi_1(aux_clk_phi_1),
        .aux_clk_q3(aux_clk_q3),
        .aux_serout_n(aux_serout_n),
        .aux_clk_14M(aux_clk_14M),
        .aux_sync_n(aux_sync_n),
        .aux_ldps_n(aux_ldps_n),
        .aux_h0(aux_h0),
        .aux_pcas_n(aux_pcas_n),
        .aux_wndw_n(aux_wndw_n),
        .aux_altvid_n(aux_altvid_n),
        .aux_envid_n(aux_envid_n),
        .aux_rw_n(aux_rw_n),
        .aux_vid(aux_vid),
        .aux_eighty_vid_n(aux_eighty_vid_n),
        .aux_en80_n(aux_en80_n),
        .aux_ra(aux_ra),
        .aux_sega(aux_sega),
        .aux_segb(aux_segb),
        .aux_vc(aux_vc),
        .aux_ra9_n(aux_ra9_n),
        .aux_ra10_n(aux_ra10_n),
        .aux_clrgat_n(aux_clrgat_n),
        .aux_vid7m(aux_vid7m),
        .aux_entmg_n(aux_entmg_n)
    );
endmodule
