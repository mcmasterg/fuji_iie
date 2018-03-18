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
    input reset
    );
    
endmodule
