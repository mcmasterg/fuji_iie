module AppleIIeMemoryManagementUnit(
    input clk_phi_0,
    input clk_q3,

    // Debug stap
    input inh_n,

    // CPU bus
    input [15:0] a,
    output md7,
    input rw_n,

    // RAM address bus
    input pras_n,
    output [7:0] ra,

    // Address muxing control signals
    output ramen_n,
    output romen1_n,
    output romen2_n,
    output en80_n,
    output cxxx,

    output dma_n,
    output kbd_n,

    output rw_245_n
);

reg [15:0] cpu_request_address;

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

// CPU requests put an address on the bus during Phi1. Since only Phi0 is available,
// sample the bus on the negative edge which is almost the same as the positive edge
// of Phi1.
always @(negedge clk_phi_0) begin
    cpu_request_address <= a;

    casez ({rw_n, a})
        {1'b0, 12'hc00, 4'b000?}: soft_switch_80store <= a[0];
        {1'b0, 12'hc00, 4'b001?}: soft_switch_ramrd <= a[0];
        {1'b0, 12'hc00, 4'b010?}: soft_switch_ramwrt <= a[0];
        {1'b0, 12'hc00, 4'b100?}: soft_switch_altzp <= a[0];
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
        {1'b1, 16'hc016}: md7_out <= soft_switch_altzp;
        {1'b1, 16'hc018}: md7_out <= soft_switch_80store;
        {1'b1, 16'hc01c}: md7_out <= soft_switch_page2;
        {1'b1, 16'hc01d}: md7_out <= soft_switch_hires;
    endcase
end

assign ra = (clk_phi_0 && pras_n) ? {cpu_request_address[8:7], cpu_request_address[5:0]} :
             (clk_phi_0 && clk_q3) ? {cpu_request_address[15:13], banked_mem_bank2_selected,
                                      cpu_request_address[11:10], cpu_request_address[6],
                                      cpu_request_address[9]} : 8'bZ;

wire banked_mem_ram_selected = (rw_n && banked_mem_reads_ram) || (~rw_n && banked_mem_writes_enabled);
wire banked_mem_rom_selected = (rw_n && ~banked_mem_reads_ram);

wire zero_page_aux_selected = soft_switch_altzp;
wire main_ram_aux_selected = (rw_n && soft_switch_ramrd) || (~rw_n && soft_switch_ramwrt);
wire text_page1_aux_selected = soft_switch_80store ? soft_switch_page2 : main_ram_aux_selected;
wire hires_aux_selected = soft_switch_hires ? text_page1_aux_selected : main_ram_aux_selected;
wire banked_mem_aux_selected = soft_switch_altzp;


assign ramen_n = (((cpu_request_address >= 16'h0000 && cpu_request_address < 16'h0200 && ~zero_page_aux_selected) ||
                   (cpu_request_address >= 16'h0200 && cpu_request_address < 16'h0400 && ~main_ram_aux_selected) ||
                   (cpu_request_address >= 16'h0400 && cpu_request_address < 16'h0800 && ~text_page1_aux_selected) ||
                   (cpu_request_address >= 16'h0800 && cpu_request_address < 16'h2000 && ~main_ram_aux_selected) ||
                   (cpu_request_address >= 16'h2000 && cpu_request_address < 16'h4000 && ~hires_aux_selected) ||
                   (cpu_request_address >= 16'h4000 && cpu_request_address < 16'hc000 && ~main_ram_aux_selected) ||
                   (cpu_request_address >= 16'hd000 && banked_mem_ram_selected && ~banked_mem_aux_selected))) ? 1'b0 : 1'b1;
assign romen1_n = (cpu_request_address >= 16'hd000 && banked_mem_rom_selected) ? 1'b0 : 1'b1;
assign romen2_n = romen1_n;
assign en80_n = (((cpu_request_address >= 16'h0000 && cpu_request_address < 16'h0200 && zero_page_aux_selected) ||
                   (cpu_request_address >= 16'h0200 && cpu_request_address < 16'h0400 && main_ram_aux_selected) ||
                   (cpu_request_address >= 16'h0400 && cpu_request_address < 16'h0800 && text_page1_aux_selected) ||
                   (cpu_request_address >= 16'h0800 && cpu_request_address < 16'h2000 && main_ram_aux_selected) ||
                   (cpu_request_address >= 16'h2000 && cpu_request_address < 16'h4000 && hires_aux_selected) ||
                   (cpu_request_address >= 16'h4000 && cpu_request_address < 16'hc000 && main_ram_aux_selected) ||
                   (cpu_request_address >= 16'hd000 && banked_mem_ram_selected && banked_mem_aux_selected))) ? 1'b0 : 1'b1;
assign cxxx = (cpu_request_address[15:12] == 4'hc) ? 1'b1 : 1'b0;

assign md7 = (clk_phi_0 && ~clk_q3 && cpu_request_address[15:4] == 16'hc01) ? md7_out : 1'bZ;

endmodule