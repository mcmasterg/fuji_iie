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
    input button_reset
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
        .monitor_rom_d(monitor_rom_d)
    );
    
endmodule
