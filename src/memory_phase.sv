`include "./defines/pipeline_hdrs.svh"

module memory_phase 
    (
    input logic [WIDTH-1:0] addr,
    input logic [WIDTH-1:0] rdata2,

    //input logic [WIDTH-1:0] rdata1,
    //input logic [11:0]      imm,

    //input logic         csr_wr_req,
    //input logic         csr_reg_rd,

    input logic [2:0]  rd_ctrl,
    input logic [2:0]  wr_ctrl,

    input logic             clk, 

    //output logic [WIDTH-1:0]csr_rdata,
    output logic [WIDTH-1:0]rdata
);

logic [WIDTH-1:0] tdata, csr_tdata;                                    // temporary data
logic [WIDTH-1:0] data_mem [DEPTH]; 

initial begin
    $readmemh("/home/fazail/3_stage_Pipeline_csr/memory/data.mem",data_mem);
end

assign tdata = data_mem[addr];

always_ff @( posedge clk ) begin 
    if      (wr_ctrl == 3'b000) data_mem[addr] <= rdata2;                               // Load word
    else if (wr_ctrl == 3'b001) data_mem[addr] <= {{24{rdata2[7]}},rdata2[7:0]};        // Load byte
    else if (wr_ctrl == 3'b010) data_mem[addr] <= {{26{rdata2[15]}},rdata2[15:0]};      // Load halfword
    else                        data_mem[addr] <= data_mem[addr];                       // data_mem[addr] <= data_mem[addr];
end

always_comb begin
    case(rd_ctrl)
        3'b000: rdata = { {24{tdata[7]}}, tdata[7:0] };     // Load byte signed
        3'b001: rdata = { {16{tdata[15]}}, tdata[15:0]};    // Load halfword signed
        3'b010: rdata = tdata;                              // Load word
        3'b100: rdata = { 24'b0, tdata[7:0] };              // Load byte unsigned
        3'b101: rdata = { 16'b0, tdata[15:0]};              // Load halfword unsigned
        default: rdata = rdata;
    endcase
end

/*always_ff @(posedge clk) begin
    if (csr_wr_req) csr_tdata <= rdata1;
    else            csr_tdata <= '0;
end
always_comb begin
    case(imm)
    12'h305: 
    endcase
end
always_comb begin
    if (csr_reg_rd) begin
        csr_rdata = csr_tdata;
    end
end*/

endmodule