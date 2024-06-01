`include "./defines/pipeline_hdrs.svh"

module fetch_phase (
       
    input logic [WIDTH-1:0] alu_out,
    input logic [WIDTH-1:0] csr_epc,

    input logic             epc_taken,
    input logic             sel_pc,

    input logic             clk,
    input logic             rst_n,

    //input logic             csr_flush,

    //input logic             flush,

    output logic [WIDTH-1:0] pc_addr,
    output logic [WIDTH-1:0] inst

);

logic [BYTE-1:0] inst_mem [160];
//logic [WIDTH-1:0] epc;


/*assign epc = (sel_pc) ? alu_out : (pc_addr + 4);

assign pc_addr =  (epc_taken) ? csr_epc : epc;

always_comb begin 
    if (sel_pc) epc = alu_out;
    else epc = pc_addr + 4;
end */

always_ff @(posedge clk) begin : pc_register
    if (!rst_n )
        pc_addr <= '0;
    
    else if (epc_taken) pc_addr <= csr_epc;
    else if (sel_pc)    pc_addr <= alu_out;
    else                pc_addr <= pc_addr + 4;
    
end : pc_register

initial begin
    $readmemh("/home/fazail/3_stage_Pipeline_csr/memory/csr_inst.mem", inst_mem);
end

assign inst = {inst_mem[pc_addr+0],inst_mem[pc_addr+1],inst_mem[pc_addr+2],inst_mem[pc_addr+3]};
    
endmodule
