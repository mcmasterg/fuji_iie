
module AppleIIInputOutputUnit(
    input clk_phi_0,
    input clk_q3,
    output reset_n,

    // CPU interface    
    input rw_n,
    input c0xx_n,
    input a6,
    output md7,
    
    // Video RAM access
    input pras_n,
    output [7:0] ra,

    // Video character generator
    output gr,
    output sega,
    output segb,
    output vc,
    output ra9_n,
    output ra10_n,    

    // Video control signals
    output eighty_vid_n,
    output vidd7,
    output vidd6,
    output clrgat_n,
    output wndw_n,
    output sync_n,
    output h0,
            
    output casso,
    output spkr,
    output [3:0] an,
    output c0xx,
    output akd,
    output kstrb
    );
    
    reg soft_switch_80store;
    reg soft_switch_altchar;
    reg soft_switch_80col;
    reg soft_switch_text;
    reg soft_switch_mixed;
    reg soft_switch_page2;
    reg soft_switch_hires;
    reg [3:0] soft_switch_an;
    reg soft_switch_dhires;
    reg soft_switch_ioudis;
    
    // MMU puts {a[8:7], a[5:0]} on ra[7:0] so it can be sampled on
    // negative edges of pras_n. a6 is helpfully provided as a separate
    // signal from the MMU.  Since a[15:9] are omitted, use c0xx_n provided
    // by MMU to know when accesses are happening within the I/O space.
    wire [8:0] cpu_a = { ra[7:6], a6, ra[5:0]};
    
    // Readback for soft switches present in this IOU all fall in c018-c01f and c07e-c07f. 
    reg md7_out;
    wire data_read_cycle = (rw_n && clk_phi_0 && ~clk_q3);
    assign md7 = (data_read_cycle && ~c0xx_n &&
                  (cpu_a[8:7] == 2'b01 ||
                   {cpu_a[8:1], 1'b0} == 9'h07e)) ? md7_out : 1'bZ;

    always @(negedge pras_n) begin
        if (clk_phi_0 && ~c0xx_n)
        casez ({rw_n, cpu_a})
            {1'b0, 5'h00, 4'b000?}: soft_switch_80store <= cpu_a[0];
            {1'b0, 5'h00, 4'b110?}: soft_switch_80col <= cpu_a[0];
            {1'b0, 5'h00, 4'b111?}: soft_switch_altchar <= cpu_a[0];
            {1'b?, 5'h05, 4'b000?}: soft_switch_text <= cpu_a[0];
            {1'b?, 5'h05, 4'b001?}: soft_switch_mixed <= cpu_a[0];
            {1'b?, 5'h05, 4'b010?}: soft_switch_page2 <= cpu_a[0];
            {1'b?, 5'h05, 4'b011?}: soft_switch_hires <= cpu_a[0];
            {1'b?, 5'h05, 4'b1???}: begin
                if (soft_switch_ioudis && cpu_a[2:1] == 2'b11) soft_switch_dhires <= cpu_a[0];
                else soft_switch_an[cpu_a[2:1]] <= cpu_a[0];
            end
            {1'b0, 5'h07, 4'b111?}: soft_switch_ioudis <= cpu_a[0];
            
            {1'b1, 5'h01, 4'b1000}: md7_out <= soft_switch_80store;
            {1'b1, 5'h01, 4'b1010}: md7_out <= soft_switch_text;
            {1'b1, 5'h01, 4'b1011}: md7_out <= soft_switch_mixed;
            {1'b1, 5'h01, 4'b1100}: md7_out <= soft_switch_page2;
            {1'b1, 5'h01, 4'b1101}: md7_out <= soft_switch_hires;
            {1'b1, 5'h01, 4'b1110}: md7_out <= soft_switch_altchar;
            {1'b1, 5'h01, 4'b1111}: md7_out <= soft_switch_80col;
            {1'b1, 5'h07, 4'b1110}: md7_out <= soft_switch_ioudis;
            default: ;
        endcase
    end
    
    assign an = soft_switch_an;
    
    wire [15:0] vid_a;
    assign ra = (~clk_phi_0 && pras_n) ? {vid_a[8:7], vid_a[5:0]} :
                 (~clk_phi_0 && clk_q3) ? {vid_a[15:10], vid_a[6], vid_a[9]} : 8'bZ;

    AppleIIeInputOutputUnitVideo video(
        .clk_phi_0(clk_phi_0),
        
        .soft_switch_text(soft_switch_text),
        .soft_switch_hires(soft_switch_hires),
        .soft_switch_80store(soft_switch_80store),
        .soft_switch_page2(soft_switch_page2),
        
        .h0(h0),
        .vid_a(vid_a),
        .sega(sega),
        .segb(segb),
        .vc(vc)
    );
endmodule
