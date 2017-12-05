`ifndef _STAGE_DECODE_
`define _STAGE_DECODE_

`include "Processor.vh"
`include "Decoder.v"
`include "SignExtension.v"

module StageDecode (
input clk,
input reset,

input [DBITS - 1: 0] inst_word,
output [3:0] alu_op,
output [4:0] alu_fn,
output [REG_INDEX_BIT_WIDTH-1:0] src_reg1_addr, src_reg2_addr, dest_reg_addr,
output [DBITS-1:0] imm_ext, imm16,
output [1:0] sel_alu_sr2, sel_reg_din,
output wr_reg, wr_mem
);

parameter DBITS = 32;
parameter REG_INDEX_BIT_WIDTH  = 4;


// Control/data signals from decoder
wire [15:0] imm;
Decoder decoder (
    .data (inst_word),
    .alu_fn (alu_fn),
    .opcode (alu_op),
    .src_reg1 (src_reg1_addr),
    .src_reg2 (src_reg2_addr),
    .dest_reg (dest_reg_addr),
    .imm (imm),
    .sel_alu_sr2 (sel_alu_sr2),
    .sel_reg_din (sel_reg_din),
    .wr_reg (wr_reg),
    .wr_mem (wr_mem)
);

assign imm16 = {imm, 16'b0};
SignExtension #(
    .IN_BIT_WIDTH (16),
    .OUT_BIT_WIDTH (DBITS)
    ) sign_extend (
    .dIn (imm),
    .dOut (imm_ext)
);

endmodule

`endif //_STAGE_DECODE_