`ifndef _STAGE_WRITE_BACK_
`define _WRITE_BACK_

`include "Processor.vh"

module StageWriteBack(
input clk,
input reset,

input [REG_INDEX_BIT_WIDTH - 1:0] dest_reg_addr,
input wr_reg_in,
input [DBITS-1:0] imm16, alu_out, data_out, pc,
input [1:0] sel_reg_din,

output wr_reg,
output [REG_INDEX_BIT_WIDTH - 1:0] reg_addr,
output reg [DBITS-1:0] reg_din
);

parameter DBITS = 32;
parameter REG_INDEX_BIT_WIDTH  = 4;

assign wr_reg = wr_reg_in;
assign reg_addr = dest_reg_addr;

always @(*) begin
    case (sel_reg_din)
        `REG_IN_PC4:    reg_din = pc + 4;
        `REG_IN_DOUT:   reg_din = data_out;
        `REG_IN_ALU:    reg_din = alu_out;
        `REG_IN_IMM16:  reg_din = imm16;
        default:        reg_din = 32'hzzzzzzzz;
    endcase
end

endmodule

`endif //_STAGE_WRITE_BACK_