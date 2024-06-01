`include "./defines/pipeline_hdrs.svh"

module forward_unit //#(
    //parameter WIDTH = 32
    //)
    (
    input logic [WIDTH-1:0] inst_f2d,
    input logic [WIDTH-1:0] inst_e2m,

    input logic             reg_wr_mw,

    input logic             br_taken,

    input logic             rst_n,
    input logic             interrupt_sel,

    output logic            flush,
    
    output logic            forward_ae,
    output logic            forward_be
);

logic [4:0] rd_e2m, rd_f2d;
logic [4:0] rs1_f2d, rs2_f2d;
logic [6:0] opcode_f2d;

assign rd_e2m = inst_e2m[11:7];
assign rd_f2d = inst_f2d[11:7];
assign opcode_f2d = inst_f2d[6:0];

assign rs1_f2d = inst_f2d[19:15];
assign rs2_f2d = inst_f2d[24:20];

always_comb begin
        if ((inst_f2d[6:0] == 7'h67) | (inst_f2d[6:0] == 7'h6f) | interrupt_sel) begin  /*jalr-jal*/
                flush = 1'b1;
                forward_ae = 1'b0;
                forward_be = 1'b0;
            end
        else if (br_taken) begin   //branch_type with taken (opcode_f2d == 7'h63) &
            flush = 1'b1;
            forward_ae = 1'b0;
            forward_be = 1'b0;
        end
        else if (reg_wr_mw) begin
            if (rd_e2m == rs1_f2d) begin
                forward_ae = 1'b1;
                if ((inst_f2d[6:0] != 7'h67) & (inst_f2d[6:0] != 7'h6f) & (!br_taken)) begin  /*jalr-jal*/
                    flush = 1'b0;
                end
            end
            else if (rd_e2m == rs2_f2d) begin 
                forward_be = 1'b1;
                if ((inst_f2d[6:0] != 7'h67) & (inst_f2d[6:0] != 7'h6f) & (!br_taken)) begin  /*jalr-jal*/
                    flush = 1'b0;
                end       
            end
            else begin 
                forward_ae = 1'b0;
                forward_be = 1'b0;
                flush  = 1'b0;
            end
        end
        else begin
                forward_ae = 1'b0;
                forward_be = 1'b0;
                flush  = 1'b0;
        end
end

/*assign forward_ae = (rst_n != 1'b1) ? 1'b0 :
                    ((reg_wr_mw == 1'b1) & (rd_e2m != 5'h00) & (rd_e2m == rs1_f2d)) ? 1'b1 : 1'b0;

assign forward_be = (rst_n != 1'b1) ? 1'b0 :
                    ((reg_wr_mw == 1'b1) & (rd_e2m != 5'h00) & (rd_e2m == rs2_f2d)) ? 1'b1 : 1'b0; 
*/    

endmodule
