/* Static ROM implemented using synthesizeable constructs that should infer as block RAMs. */
module Rom #(
  parameter RAM_WIDTH = 18,                       // Specify RAM data width
  parameter RAM_DEPTH = 1024,                     // Specify RAM depth (number of entries)
  parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
  input [clogb2(RAM_DEPTH-1)-1:0] addra,  // Address bus, width determined from RAM_DEPTH
  input clka,                           // Clock
  input ena,                            // RAM Enable, for additional power savings, disable port when not in use
  input oe,                             // Output register enable
  output [RAM_WIDTH-1:0] douta           // ROM output data
);

reg [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];
reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};

// The following code either initializes the memory values to a specified file or to all zeros to match hardware
generate
if (INIT_FILE != "") begin: use_init_file
    initial
        $readmemh(INIT_FILE, BRAM, 0, RAM_DEPTH-1);
end
else begin: init_bram_to_zero
    integer ram_index;

    initial
    for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
        BRAM[ram_index] = {RAM_WIDTH{1'b0}};
end
endgenerate

always @(posedge clka)
if (ena) ram_data <= BRAM[addra];

// The following is a 2 clock cycle read latency with improve clock-to-out timing
reg [RAM_WIDTH-1:0] douta_reg = {RAM_WIDTH{1'b0}};

always @(posedge clka)
douta_reg <= ram_data;

assign douta = oe ? douta_reg : {RAM_WIDTH{1'bZ}};

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
