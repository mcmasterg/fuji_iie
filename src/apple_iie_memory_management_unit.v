module AppleIIeMemoryManagementUnit(
    input clk_phi_0,
    input clk_q3,

    // CPU bus
    input [15:0] a,
    output md7,
    input rw_n,

    // Peripheral bus
    input inh_n,
    input dma_n,
    output rw_245_n,

    // RAM address bus
    input pras_n,
    output [7:0] ra,

    // Address muxing control signals
    output ramen_n,
    output romen1_n,
    output romen2_n,
    output en80_n,
    output cxxx,

    output kbd_n
);

reg banked_mem_reads_ram;       // LCRAM
reg banked_mem_writes_enabled;
reg banked_mem_bank2_selected;  // BANK2

reg md7_out;

reg soft_switch_altzp;
reg soft_switch_ramrd;
reg soft_switch_ramwrt;
reg soft_switch_80store;
reg soft_switch_page2;
reg soft_switch_hires;
reg soft_switch_slotcxrom;
reg soft_switch_slotc3rom;

// CPU requests put an address on the bus during Phi1. Since only Phi0 is available,
// sample the bus on the negative edge which is almost the same as the positive edge
// of Phi1.
always @(negedge clk_phi_0) begin
    casez ({rw_n, a})
        {1'b0, 12'hc00, 4'b000?}: soft_switch_80store <= a[0];
        {1'b0, 12'hc00, 4'b001?}: soft_switch_ramrd <= a[0];
        {1'b0, 12'hc00, 4'b010?}: soft_switch_ramwrt <= a[0];
        {1'b0, 12'hc00, 4'b011?}: soft_switch_slotcxrom <= a[0];
        {1'b0, 12'hc00, 4'b100?}: soft_switch_altzp <= a[0];
        {1'b0, 12'hc00, 4'b101?}: soft_switch_slotc3rom <= a[0];
        {1'b0, 12'hc05, 4'b010?}: soft_switch_page2 <= a[0];
        {1'b0, 12'hc05, 4'b011?}: soft_switch_hires <= a[0];
        {1'b1, 16'hc080}: begin
            banked_mem_reads_ram <= 1'b1;
            banked_mem_writes_enabled <= 1'b0;
            banked_mem_bank2_selected <= 1'b1;
            end
        {1'b1, 16'hc081}: begin
            banked_mem_reads_ram <= 1'b0;
            banked_mem_writes_enabled <= 1'b1;
            banked_mem_bank2_selected <= 1'b1;
            end
        {1'b1, 16'hc082}: begin
            banked_mem_reads_ram <= 1'b0;
            banked_mem_writes_enabled <= 1'b0;
            banked_mem_bank2_selected <= 1'b1;
            end
        {1'b1, 16'hc083}: begin
            banked_mem_reads_ram <= 1'b1;
            banked_mem_writes_enabled <= 1'b1;
            banked_mem_bank2_selected <= 1'b1;
            end
        {1'b1, 16'hc088}: begin
            banked_mem_reads_ram <= 1'b1;
            banked_mem_writes_enabled <= 1'b0;
            banked_mem_bank2_selected <= 1'b0;
            end
        {1'b1, 16'hc089}: begin
            banked_mem_reads_ram <= 1'b0;
            banked_mem_writes_enabled <= 1'b1;
            banked_mem_bank2_selected <= 1'b0;
            end
        {1'b1, 16'hc08a}: begin
            banked_mem_reads_ram <= 1'b0;
            banked_mem_writes_enabled <= 1'b0;
            banked_mem_bank2_selected <= 1'b0;
            end
        {1'b1, 16'hc08b}: begin
            banked_mem_reads_ram <= 1'b1;
            banked_mem_writes_enabled <= 1'b1;
            banked_mem_bank2_selected <= 1'b0;
            end
        {1'b1, 16'hc011}: md7_out <= banked_mem_bank2_selected;
        {1'b1, 16'hc012}: md7_out <= banked_mem_reads_ram;
        {1'b1, 16'hc013}: md7_out <= soft_switch_ramrd;
        {1'b1, 16'hc014}: md7_out <= soft_switch_ramwrt;
        {1'b1, 16'hc015}: md7_out <= soft_switch_slotcxrom;
        {1'b1, 16'hc016}: md7_out <= soft_switch_altzp;
        {1'b1, 16'hc017}: md7_out <= soft_switch_slotc3rom;
        {1'b1, 16'hc018}: md7_out <= soft_switch_80store;
        {1'b1, 16'hc01c}: md7_out <= soft_switch_page2;
        {1'b1, 16'hc01d}: md7_out <= soft_switch_hires;
    endcase
end

assign ra = (clk_phi_0 && pras_n) ? {a[8:7], a[5:0]} :
             (clk_phi_0 && clk_q3) ? {a[15:13], banked_mem_bank2_selected, a[11:10], a[6], a[9]} : 8'bZ;

wire banked_mem_ram_selected = (rw_n && banked_mem_reads_ram) || (~rw_n && banked_mem_writes_enabled);
wire zero_page_aux_selected = soft_switch_altzp;
wire main_ram_aux_selected = (rw_n && soft_switch_ramrd) || (~rw_n && soft_switch_ramwrt);
wire text_page1_aux_selected = soft_switch_80store ? soft_switch_page2 : main_ram_aux_selected;
wire hires_aux_selected = soft_switch_hires ? text_page1_aux_selected : main_ram_aux_selected;
wire banked_mem_aux_selected = soft_switch_altzp;

wire data_read_cycle = (rw_n && clk_phi_0 && ~clk_q3);

assign ramen_n = (((a >= 16'h0000 && a < 16'h0200 && ~zero_page_aux_selected) ||
                   (a >= 16'h0200 && a < 16'h0400 && ~main_ram_aux_selected) ||
                   (a >= 16'h0400 && a < 16'h0800 && ~text_page1_aux_selected) ||
                   (a >= 16'h0800 && a < 16'h2000 && ~main_ram_aux_selected) ||
                   (a >= 16'h2000 && a < 16'h4000 && ~hires_aux_selected) ||
                   (a >= 16'h4000 && a < 16'hc000 && ~main_ram_aux_selected) ||
                   (a >= 16'hd000 && banked_mem_ram_selected && ~banked_mem_aux_selected))) ? 1'b0 : 1'b1;
assign en80_n = (((a >= 16'h0000 && a < 16'h0200 && zero_page_aux_selected) ||
                  (a >= 16'h0200 && a < 16'h0400 && main_ram_aux_selected) ||
                  (a >= 16'h0400 && a < 16'h0800 && text_page1_aux_selected) ||
                  (a >= 16'h0800 && a < 16'h2000 && main_ram_aux_selected) ||
                  (a >= 16'h2000 && a < 16'h4000 && hires_aux_selected) ||
                  (a >= 16'h4000 && a < 16'hc000 && main_ram_aux_selected) ||
                  (a >= 16'hd000 && banked_mem_ram_selected && banked_mem_aux_selected))) ? 1'b0 : 1'b1;

wire banked_mem_rom_selected = (rw_n && ~banked_mem_reads_ram);
wire slotx_internal_rom_selected = ~soft_switch_slotcxrom;
wire slot3_internal_rom_selected = slotx_internal_rom_selected || ~soft_switch_slotc3rom;

assign romen1_n = (data_read_cycle &&
                   ((a >= 16'hc100 && a < 16'hc300 && slotx_internal_rom_selected) ||
                    (a >= 16'hc300 && a < 16'hc400 && slot3_internal_rom_selected) ||
                    (a >= 16'hc400 && a < 16'hc400 && slot3_internal_rom_selected) ||
                    /* TODO: Slot 3 expansion ROM mapped to internal ROM */
                    (a >= 16'hd000 && a < 16'he000 && banked_mem_rom_selected))) ? 1'b0 : 1'b1;
assign romen2_n = (data_read_cycle && a >= 16'he000 && banked_mem_rom_selected) ? 1'b0 : 1'b1;
assign cxxx = (a[15:12] == 4'hc) ? 1'b1 : 1'b0;

assign md7 = (data_read_cycle && a[15:4] == 16'hc01) ? md7_out : 1'bZ;

endmodule