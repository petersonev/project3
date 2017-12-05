`ifndef _STAGE_MEM_
`define _STAGE_MEM_

`include "Processor.vh"
`include "Memory.v"

module StageMem(
input clk,
input reset,

input [DBITS-1:0] alu_out, regs_out2,
input wr_mem,
output [DBITS-1:0] data_out,

input [3:0] mmio_key_in,
input [9:0] mmio_sw_in,
output [15:0] mmio_hex_out,
output [9:0] mmio_ledr_out
);

parameter DBITS = 32;

parameter DMEM_INIT_FILE        = "";
parameter DMEM_ADDR_BIT_WIDTH   = 11;
localparam DMEM_WORD_BITS       = 2;

wire [DBITS-1:0] data_out;
Memory #(
    .MEM_INIT_FILE (DMEM_INIT_FILE),
    .ADDR_BIT_WIDTH (DMEM_ADDR_BIT_WIDTH),
    .DATA_BIT_WIDTH (DBITS)
    ) data_memory (
    .clk (clk),
    .reset (reset),
    .en_write (wr_mem),
    .addr (alu_out[DBITS - 1: DMEM_WORD_BITS]),
    .data_in (regs_out2),
    .data_out (data_out),

    .mmio_key_in (mmio_key_in),
    .mmio_sw_in (mmio_sw_in),
    .mmio_hex_out (mmio_hex_out),
    .mmio_ledr_out (mmio_ledr_out)
);

endmodule

`endif //_STAGE_MEM_