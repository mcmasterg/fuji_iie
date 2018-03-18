/* Integer divide-by-N */

module ClockDivideByN #(
    parameter N = 5
)
(
    input clk_in,
    input reset,
    output clk_out
);
    localparam WIDTH = clogb2(N);

    reg [WIDTH-1:0] pos_count, neg_count;
    wire [WIDTH-1:0] r_nxt;

    always @(posedge clk_in)
    if (reset)
        pos_count <= 0;
    else if (pos_count == N-1) pos_count <= 0;
    else pos_count <= pos_count +1;

    always @(negedge clk_in)
    if (reset)
        neg_count <= 0;
    else if (neg_count == N-1) neg_count <= 0;
    else neg_count <= neg_count +1;

    assign clk_out = ((pos_count > (N>>1)) | (neg_count > (N>>1)));

    function integer clogb2;
        input [31:0] value;
        begin
            value = value - 1;
            for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction
endmodule