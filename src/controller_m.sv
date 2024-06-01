module controller_m (
    input logic       reg_wr_e, 
    input logic       sel_pc_e,
    input logic [2:0] rd_ctrl_e, 
    input logic [1:0] wb_sel_e,
    input logic [2:0] wr_ctrl_e,

    input logic       csr_wr_req,
    input logic         csr_reg_rd,

    input logic clk, rst_n,

    output logic       reg_wr_m, 
    output logic       sel_pc_m,
    output logic [2:0] rd_ctrl_m, 
    output logic [1:0] wb_sel_m,
    output logic [2:0] wr_ctrl_m,

    output logic        csr_wr_req_m,
    output logic        csr_reg_rd_m
);

always_ff @( posedge clk ) begin : Controller_signals_execute_to_memory
    if(!rst_n)begin
                sel_pc_m <= 1'b0;
                wb_sel_m <= 2'b00;
                reg_wr_m <= 1'b0;

                rd_ctrl_m <= 3'h3;
                wr_ctrl_m <= 3'b111;

                csr_wr_req_m <= 1'b0;
                csr_reg_rd_m <= 1'b0;
            end
    else
            begin
                sel_pc_m <= sel_pc_e;
                wb_sel_m <= wb_sel_e; 
                reg_wr_m <= reg_wr_e;

                rd_ctrl_m <= rd_ctrl_e;
                wr_ctrl_m <= wr_ctrl_e;

                csr_wr_req_m <= csr_wr_req;
                csr_reg_rd_m <= csr_reg_rd;
            end
end
    
endmodule