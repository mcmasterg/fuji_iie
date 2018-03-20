/*
This module is primarily based off of the MK4116 datasheet,
which has some excellent timing diagrams

Sounds like the IIe might not do any page operations
It also raises RASn before CASn
whereas the MK4116 datasheet raises CASn first, as required for page operations
*/

/*
CDC against asynchronous RAS/CAS signals
Alternatively could implement this module using async logic
*/
module ff2(input wire clk, input wire din, output wire dout);
    reg ff1 = 1'b0;
    reg ff2 = 1'b0;
    assign dout = ff2;

    always @(posedge(clk)) begin
        ff1 <= din;
        ff2 <= ff1;
    end
endmodule
module ff2n (input wire clk, input wire [N-1:0] din, output wire [N-1:0] dout);
    parameter N=1;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin
            ff2 D_cdc(.clk(clk), .din(din[i]), .dout(dout[i]));
        end
    endgenerate
endmodule

module MK4116x8(
        //Pins used for implementation to emulate BRAM as combintorial logic
        //This must be something like at least 4x your desired access time
        //(due to CDC FF's + BRAM access time)
        input wire clk,

        //Actual pins
        input wire [7:0] D, //1 bit for each chip
        input wire Wn,
        input wire RASn,
        input wire CASn,
        input wire [7:0] A,
        output wire [7:0] Q); //1 bit for each chip
    reg [7:0] col_addr;
    reg [7:0] row_addr;

    wire Wn_c, RASn_c;
    wire CASn_c;
    ff2n #(.N(3)) cdc(.clk(clk), .din({Wn, RASn, CASn}), .dout({Wn_c, RASn_c, CASn_c}));

    //Register signals we need to do edge detection on
    reg RASn_cr;
    reg CASn_cr;
    always @(posedge(clk)) begin
        RASn_cr <= RASn_c;
        CASn_cr <= CASn_c;
    end

    //BRAM as the actual storage
    reg bram_wea;
    wire [15:0] bram_addr = {row_addr, col_addr};
    wire [7:0] bram_doutb;
    bram_8x64k bram(
            .clka(clk),
            .ena(1'b1),
            .wea(bram_wea),
            .addra(bram_addr),
            .dina(D),

            .clkb(clk),
            .enb(1'b1),
            .addrb(bram_addr),
            .doutb(bram_doutb));
    reg Q_en;
    assign Q = Q_en ? bram_doutb : 8'bz;

    always @(posedge(clk)) begin
        //RASn falling => save row address
        if (RASn_cr & !RASn_c) begin
            row_addr <= A;
        end
        //CASn falling => save col address
        if ((CASn_cr & !CASn_c)) begin
            col_addr <= A;
        end
    end

    always @(posedge(clk)) begin
        bram_wea <= 1'b0;
        //Active read when row selected, column selected, and is a read
        Q_en <= !RASn_c & !CASn_c & Wn_c;

        //Do write when CASn falls
        //Note col address is latched above at the same time
        //XXX: should mask for RASn here?
        if (CASn_cr & !CASn_c) begin
            bram_wea <= !Wn;
        end
    end
endmodule

