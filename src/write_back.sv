`include "./defines/pipeline_hdrs.svh"

module write_back //#(
    //parameter WIDTH = 32
    //)
    (
    input logic [WIDTH-1:0] alu,
    input logic [WIDTH-1:0] rdata,
    input logic [WIDTH-1:0] csr_rdata,
    input logic [WIDTH-1:0] pc,

    input logic [1:0]       wb_sel,

    output logic [WIDTH-1:0] data_o
);

always_comb begin
    data_o = '0;
    case(wb_sel)
        2'b00: data_o = alu;
        2'b01: data_o = rdata; 
        2'b10: data_o = pc + 4;
        2'b11: data_o = csr_rdata;
    endcase
end
    
endmodule
