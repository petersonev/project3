`ifndef _STAGE_EXECUTE_
`define _STAGE_EXECUTE_

`include "Processor.vh"
`include "Alu.v"

module StageExecute(
input clk,
input [3:0] op_code,
input [4:0] alu_fn,
input [BIT_WIDTH-1:0] pc,
input [BIT_WIDTH-1:0] src_reg1, src_reg2,
input [BIT_WIDTH-1:0] imm_ext,
input [1:0] sel_alu_src2,  // src2 select (imm, imm*4, reg, 0)
output [BIT_WIDTH-1:0] alu_out,
output reg pc_sel,
output reg [BIT_WIDTH-1:0] next_pc
);

parameter BIT_WIDTH = 32;
parameter REG_INDEX_WIDTH = 4;

reg [BIT_WIDTH-1:0] alu_in2;

always @(*) begin
    case (sel_alu_src2)
        `ALU_SRC2_REG2:     alu_in2 = src_reg2;
        `ALU_SRC2_IMM:      alu_in2 = imm_ext;
        `ALU_SRC2_IMM4:     alu_in2 = (imm_ext << 2);
        `ALU_SRC2_ZERO:     alu_in2 = 0;
        default:            alu_in2 = {BIT_WIDTH{1'bz}};
    endcase

    if (op_code == `OP_BCOND && alu_out) begin
        pc_sel = 1'b1;
        next_pc = (imm_ext << 2) + pc + 4;
    end
    else if (op_code == `OP_JAL) begin
        pc_sel = 1'b1;
        next_pc = alu_out;
    end
    else begin
        pc_sel = 1'b0;
        next_pc = {BIT_WIDTH{1'bz}};
    end
end

// ALU signals
Alu #(
    .BIT_WIDTH (BIT_WIDTH)
    ) alu (
    .alu_fn (alu_fn),
    .in1 (src_reg1),
    .in2 (alu_in2),
    .out (alu_out)
);


endmodule

`endif //_STAGE_EXECUTE_

