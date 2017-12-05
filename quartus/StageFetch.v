`ifndef _STAGE_FETCH_
`define _STAGE_FETCH_

`include "Processor.vh"
`include "InstMemory.v"

module StageFetch (
input clk,
input reset,
input sel_pc,
input [DBITS-1:0] next_pc,
input pc_stay,

output [DBITS-1:0] pc_out,
output [DBITS - 1: 0] inst_word
);

parameter DBITS = 32;
parameter START_PC = 32'h40;

parameter IMEM_INIT_FILE = "test.mif";
parameter IMEM_ADDR_BIT_WIDTH = 11;
localparam IMEM_WORD_BITS = 2;

// PC Mux
always @(*) begin
    pc_in = pc_out + 4;
    if (pc_stay) begin
        pc_in = pc_out;
    end
    if (inst_word == 32'hdead) begin
        pc_in = pc_out;
    end
    if (sel_pc) begin
        pc_in = next_pc;
    end

end


// PC signals
reg [DBITS - 1: 0] pc_in;
wire pc_en = 1'b1;
Register #(
    .BIT_WIDTH(DBITS), .RESET_VALUE(START_PC)
    ) pc (
    clk, reset, pc_en, pc_in, pc_out
);


// Instruction memory signals
InstMemory #(
    .MEM_INIT_FILE (IMEM_INIT_FILE),
    .ADDR_BIT_WIDTH (IMEM_ADDR_BIT_WIDTH),
    .DATA_BIT_WIDTH (DBITS)
    ) instMem (
	 .clk (clk),
    .addr (pc_out[IMEM_ADDR_BIT_WIDTH + IMEM_WORD_BITS - 1: IMEM_WORD_BITS]),
    .dataOut (inst_word)
);

endmodule

`endif //_STAGE_FETCH_