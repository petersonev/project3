`ifndef _PROCESSOR_
`define _PROCESSOR_

`include "Processor.vh"
`include "StageFetch.v"
`include "StageDecode.v"
`include "StageExecute.v"
`include "StageMem.v"
`include "StageWriteBack.v"
// `include "Alu.v"
// `include "SCProc-Controller.v"
// `include "InstMemory.v"
// `include "Mux4to1.v"
// `include "Register.v"
`include "RegisterFile.v"
// `include "SignExtension.v"
// `include "Memory.v"

module Processor (
input clk,
input reset,
output [INST_BIT_WIDTH - 1: 0] inst_word_out, // For testing

input [3:0] key_in,
input [9:0] sw_in,
output [15:0] hex_out,
output [9:0] ledr_out
);

parameter DBITS                 = 32;
parameter IMEM_INIT_FILE        = "test.mif";
parameter DMEM_INIT_FILE        = "";

parameter DMEM_ADDR_BIT_WIDTH   = 11;
parameter IMEM_ADDR_BIT_WIDTH   = 11;

localparam INST_SIZE            = 32'd4;
localparam INST_BIT_WIDTH       = 32;
localparam START_PC             = 32'h40;
localparam REG_INDEX_BIT_WIDTH  = 4;


wire [DBITS-1:0] regs_out1, regs_out2;
wire [REG_INDEX_BIT_WIDTH-1:0] dec_src_reg1_addr, dec_src_reg2_addr, dec_dest_reg_addr;
wire wb_wr_reg;
wire [REG_INDEX_BIT_WIDTH - 1:0] wb_reg_addr;
wire [DBITS-1:0] wb_reg_din;
RegisterFile #(
    .BIT_WIDTH (DBITS),
    .REG_INDEX_WIDTH (REG_INDEX_BIT_WIDTH),
    .RESET_VALUE (0)
    ) regs (
    .clk (clk),
    .reset (reset),
    .en_write (wb_wr_reg),
    .sr1_ind (dec_src_reg1_addr),
    .sr2_ind (dec_src_reg2_addr),
    .dr_ind (wb_reg_addr),
    .data_in (wb_reg_din),

    .sr1 (regs_out1),
    .sr2 (regs_out2)
);


wire [DBITS-1:0] fetch_pc;
wire [INST_BIT_WIDTH - 1: 0] fetch_inst_word;
wire [DBITS-1:0] ex_next_pc;
assign inst_word_out = fetch_inst_word;
wire ex_pc_sel;
wire dec_stall = (ex_wr_reg && (ex_dest_reg_addr == dec_src_reg1_addr ||
               ex_dest_reg_addr == dec_src_reg2_addr)) ||
(mem_wr_reg && (mem_dest_reg_addr == dec_src_reg1_addr ||
                mem_dest_reg_addr == dec_src_reg2_addr)) ||
(wb_wr_reg && (wb_dest_reg_addr == dec_src_reg1_addr ||
                wb_dest_reg_addr == dec_src_reg2_addr));
//assign hex_out = fetch_pc;
//assign ledr_out = ex_pc_sel;
StageFetch #(
    .DBITS (DBITS),
    .START_PC (START_PC),
    .IMEM_INIT_FILE (IMEM_INIT_FILE),
    .IMEM_ADDR_BIT_WIDTH (IMEM_ADDR_BIT_WIDTH)
    ) stageFetch (
    .clk (clk),
    .reset (reset),
    .sel_pc (ex_pc_sel),
    .next_pc (ex_next_pc),
    .pc_stay (dec_stall),

    .pc_out (fetch_pc),
    .inst_word (fetch_inst_word)
);


reg [DBITS-1:0] dec_pc;
reg [INST_BIT_WIDTH - 1: 0] dec_inst_word = `DEAD;
always @(posedge clk) begin
    if (dec_stall) begin

    end else if (ex_pc_sel) begin
        dec_pc <= 32'hzzzzzzz;
        dec_inst_word <= `DEAD;
    end else begin
        if (fetch_inst_word != `DEAD) begin
            dec_pc <= fetch_pc;
            dec_inst_word <= fetch_inst_word;

        end else begin
            dec_pc <= 32'hzzzzzzz;
            dec_inst_word <= 32'hzzzzzzz;
        end
    end
end


wire [3:0] dec_alu_op;
wire [4:0] dec_alu_fn;
wire [DBITS-1:0] dec_imm_ext, dec_imm16;
wire [1:0] dec_sel_alu_sr2, dec_sel_reg_din;
wire dec_wr_reg, dec_wr_mem;
StageDecode #(
    .DBITS (DBITS),
    .REG_INDEX_BIT_WIDTH (REG_INDEX_BIT_WIDTH)
    ) stageDecode (
    .clk (clk),
    .reset (reset),
    .inst_word (dec_inst_word),

    .alu_op (dec_alu_op),
    .alu_fn (dec_alu_fn),
    .src_reg1_addr (dec_src_reg1_addr),
    .src_reg2_addr (dec_src_reg2_addr),
    .dest_reg_addr (dec_dest_reg_addr),
    .imm_ext (dec_imm_ext),
    .imm16 (dec_imm16),
    .sel_alu_sr2 (dec_sel_alu_sr2),
    .sel_reg_din (dec_sel_reg_din),
    .wr_reg (dec_wr_reg),
    .wr_mem (dec_wr_mem)
);


reg [DBITS-1:0] ex_pc;
reg ex_wr_reg = 0;
reg ex_wr_mem = 0;
reg [REG_INDEX_BIT_WIDTH-1:0] ex_dest_reg_addr;
reg [DBITS-1:0] ex_imm_ext, ex_imm16;
reg [1:0] ex_sel_alu, ex_sel_reg_din;
reg [DBITS-1:0] ex_reg1, ex_reg2;
reg [3:0] ex_op_code = 4'b0100;
reg [4:0] ex_alu_fn;
always @(posedge clk) begin
    if (dec_stall || ex_pc_sel) begin
        ex_pc <= 32'hzzzzzzzz;
        ex_wr_reg <= 1'b0;
        ex_wr_mem <= 1'b0;
        ex_dest_reg_addr <= 4'hz;
        ex_imm_ext <= 32'hzzzzzzzz;
        ex_imm16 <= 32'hzzzzzzzz;
        ex_sel_alu <= 2'bzz;
        ex_reg1 <= 32'hzzzzzzzz;
        ex_reg2 <= 32'hzzzzzzzz;
        ex_op_code <= 4'b0100;
        ex_alu_fn <= 5'bzzzzz;
        ex_sel_reg_din <= 2'bzz;
    end else begin
        ex_pc <= dec_pc;
        ex_wr_reg <= dec_wr_reg;
        ex_wr_mem <= dec_wr_mem;
        ex_dest_reg_addr <= dec_dest_reg_addr;
        ex_imm_ext <= dec_imm_ext;
        ex_imm16 <= dec_imm16;
        ex_sel_alu <= dec_sel_alu_sr2;
        ex_reg1 <= regs_out1;
        ex_reg2 <= regs_out2;
        ex_op_code <= dec_alu_op;
        ex_alu_fn <= dec_alu_fn;
        ex_sel_reg_din <= dec_sel_reg_din;
    end
end


wire [DBITS-1:0] ex_alu_out;
StageExecute #(
    .BIT_WIDTH (DBITS),
    .REG_INDEX_WIDTH (REG_INDEX_BIT_WIDTH)
    ) stageExecute (
    .clk (clk),
    .op_code (ex_op_code),
    .alu_fn (ex_alu_fn),
    .pc (ex_pc),
    .src_reg1 (ex_reg1),
    .src_reg2 (ex_reg2),
    .imm_ext (ex_imm_ext),
    .sel_alu_src2 (ex_sel_alu),

    .alu_out (ex_alu_out),
    .pc_sel (ex_pc_sel),
    .next_pc (ex_next_pc)
);


reg [DBITS-1:0] mem_pc;
reg mem_wr_reg = 0;
reg mem_wr_mem = 0;
reg [REG_INDEX_BIT_WIDTH-1:0] mem_dest_reg_addr;
reg [DBITS-1:0] mem_imm16, mem_alu_out, mem_regs_out2;
reg [1:0] mem_sel_reg_din;
always @(posedge clk) begin
    mem_pc <= ex_pc;
    mem_wr_reg <= ex_wr_reg;
    mem_wr_mem <= ex_wr_mem;
    mem_dest_reg_addr <= ex_dest_reg_addr;
    mem_imm16 <= ex_imm16;
    mem_alu_out <= ex_alu_out;
    mem_regs_out2 <= ex_reg2;
    mem_sel_reg_din <= ex_sel_reg_din;
end


wire [DBITS-1:0] mem_data_out;
StageMem #(
    .DBITS (DBITS),
    .DMEM_INIT_FILE (DMEM_INIT_FILE),
    .DMEM_ADDR_BIT_WIDTH (DMEM_ADDR_BIT_WIDTH)
    ) stageMem (
    .clk (clk),
    .reset (reset),

    .alu_out (mem_alu_out),
    .regs_out2 (mem_regs_out2),
    .wr_mem (mem_wr_mem),
    .data_out (mem_data_out),

    .mmio_key_in (key_in),
    .mmio_sw_in (sw_in),
    .mmio_hex_out (hex_out),
    .mmio_ledr_out (ledr_out)
);


reg wb_wr_reg_in = 0;
reg [REG_INDEX_BIT_WIDTH-1:0] wb_dest_reg_addr;
reg [DBITS-1:0] wb_imm16;
reg [DBITS-1:0] wb_alu_out;
reg [DBITS-1:0] wb_pc;
reg [DBITS-1:0] wb_data_out;
reg [1:0] wb_sel_reg_din;
always @(posedge clk) begin
    wb_wr_reg_in <= mem_wr_reg;
    wb_dest_reg_addr <= mem_dest_reg_addr;
    wb_imm16 <= mem_imm16;
    wb_alu_out <= mem_alu_out;
    wb_pc <= mem_pc;
    wb_data_out <= mem_data_out;
    wb_sel_reg_din <= mem_sel_reg_din;
end


StageWriteBack #(
    .DBITS (DBITS),
    .REG_INDEX_BIT_WIDTH (REG_INDEX_BIT_WIDTH)
    ) stageWriteBack (
    .clk (clk),
    .reset (reset),

    .dest_reg_addr (wb_dest_reg_addr),
    .wr_reg_in (wb_wr_reg_in),
    .imm16 (wb_imm16),
    .alu_out (wb_alu_out),
    .data_out (wb_data_out),
    .pc (wb_pc),
    .sel_reg_din (wb_sel_reg_din),

    .wr_reg (wb_wr_reg),
    .reg_addr (wb_reg_addr),
    .reg_din (wb_reg_din)
);

endmodule

`endif //_PROCESSOR_