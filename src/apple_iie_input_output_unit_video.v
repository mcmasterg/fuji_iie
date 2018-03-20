
module apple_iie_input_output_unit_video(
    input clk_phi_0,
    
    input soft_switch_text,
    input soft_switch_hires,
    input soft_switch_80store,
    input soft_switch_page2,

    output h0,
    output [15:0] vid_a,
    output sega,
    output segb,
    output vc
    );
    
    // Video counters
    reg [5:0] h; // Horizontal pixel index
    reg hpe_n;
    reg [8:0] v_counter;
    wire va = v_counter[0];
    wire vb = v_counter[1];
    assign vc = v_counter[2];
    wire [5:0] v = v_counter[8:3]; // Verticle line index
    
    assign h0 = h[0];
    
    always @(posedge clk_phi_0) begin
        if (hpe_n) begin
            if (h < 6'h3F) h <= h + 1;
            else begin
                // On count 64, rollover to zero and hold for one count to make 65 counts.
                h <= 6'b0;
                hpe_n <= 1'b0;
            end
        end
        else begin
            if (v_counter < 9'd262) v_counter <= v_counter + 1;
            else v_counter <= 9'b0;
        end
    end
    

    // Display address transformation
    wire [3:0] s = {3'b0, v[3]} + {~h[5], v[3], h[4], h[3]} + {v[4], ~h[5], v[4], 1'b1};
    wire text_or_lowres = (soft_switch_text || ~soft_switch_hires);
    wire a10 = text_or_lowres ? (soft_switch_80store || ~soft_switch_page2) : va;
    wire a11 = text_or_lowres ? (~soft_switch_80store && soft_switch_page2) : vb;
    wire a12 = text_or_lowres ? 0 : vc;
    wire a13 = text_or_lowres ? 0 : (soft_switch_80store || ~soft_switch_page2);
    wire a14 = text_or_lowres ? 0 : (~soft_switch_80store && soft_switch_page2);
    assign vid_a = {1'b0, a14, a13, a12, a11, a10, v[2:0], s[3:0], h[2:0]};
    
    assign sega = (soft_switch_text) ? va : h0;
    assign segb = (soft_switch_text) ? vb : ~soft_switch_hires;
    
endmodule
