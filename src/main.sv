`include "./defines/pipeline_hdrs.svh"
`include "./defines/if2id_pipeline_stage.svh"
`include "./defines/ie2im_pipeline_stage.svh"

module main(
    input logic clk,
    input logic rst_n,

    input logic ext_int,

    output logic [WIDTH-1:0]rando,
    output logic [WIDTH-1:0]inst
);

logic [WIDTH-1:0] wbdata, rdata1, rdata2, rdata, alu_out, imm, pc_addr, for_b,for_a;
logic reg_wr, sel_b,sel_pc,sel_a, br_taken, illegal_instr;
opcode_type_e opcode;
logic [2:0] func3 , rd_ctrl, wr_ctrl, br_type;
logic [6:0] func7;
aluop_type_e alu_op;
logic [1:0] wb_sel;
logic [4:0] rd;

logic [4:0] dest_reg; //, rd_d2e, rd_e2m, rd_m2w;         //Destination registers 

//Controller Signals (e = execute, m = memory, w = writeback)
//logic        reg_wr_mw ;
//logic        sel_pc_mw ;
//logic [2:0]  rd_ctrl_mw;
//logic [1:0]  wb_sel_mw ;
//logic [2:0]  wr_ctrl_mw;  

logic forwarda_e, forwardb_e;
logic flush_r, csr_flush, interrupt_sel;

logic csr_wr_req, csr_reg_rd;
logic csr_wr_req_mw, csr_reg_rd_mw, epc_taken, is_mret;
logic [WIDTH-1:0] imm_mw, rdata1_mw, csr_rdata, csr_epc;

`ifdef IF2ID_PIPELINE_STAGE
    type_if2id_data_s       if2id_data_pipe_ff;
`else
    logic [WIDTH-1:0] pc_addr_f2d, inst_f2d;                              //Registers for Fetch to Decode stage
`endif //IF2ID_PIPELINE_STAGE


`ifdef IE2IM_PIPELINE_STAGE
    type_ie2im_data_s       ie2im_data_pipe_ff;
`else
    logic [WIDTH-1:0] pc_addr_e2m, alu_out_e2m,rs2_e2m, inst_e2m;         //Registers for Execute to Memory Stage
`endif //IE2IM_PIPELINE_STAGE

`ifdef E2M_CONTROLLER
    type_e2m_controller_s   e2m_control;
`else 
    logic        reg_wr_mw ;
    logic        sel_pc_mw;
    logic [2:0]  rd_ctrl_mw;
    logic [1:0]  wb_sel_mw;
    logic [2:0]  wr_ctrl_mw;
`endif //E2M_CONTROLLER   
assign dest_reg = $unsigned(rd);

/* ------------------------------------------ FETCH STAGE ------------------------------------------ */
fetch_phase fetch (
                    .clk            (clk), 
                    .rst_n          (rst_n),
                    
                    .sel_pc         (sel_pc), 
                    .alu_out        (alu_out),

                    .pc_addr        (pc_addr), 
                    .inst           (inst), 

                    //.flush          (flush_r),
                    .epc_taken(epc_taken),
                    .csr_epc(csr_epc)

                    //.csr_flush  (csr_flush)
                );

//Registers between Fetch to Decode stage
register pc_f2d (
                    .clk    (clk), 
                    .rst_n  (rst_n),

                    .in     (pc_addr), 

                `ifdef  IF2ID_PIPELINE_STAGE
                    .out    (if2id_data_pipe_ff.pc_addr)
                `else 
                    .out    (pc_addr_f2d)
                `endif
            );

flush_register ir_flush_f2d (
                    .clk    (clk), 
                    .rst_n  (rst_n),

                    .flush  (flush_r),
                    //.csr_flush (csr_flush),

                    .in     (inst),

                `ifdef  IF2ID_PIPELINE_STAGE
                    .out    (if2id_data_pipe_ff.if2id)
                `else 
                    .out    (inst_f2d)
                `endif //IF2ID_PIPELINE_STAGE
                );   // instruction register

/* ------------------------------------------ DECODE STAGE ----------------------------------------- */
decode_phase decode (
                    .clk            (clk), 
                    .rst_n          (rst_n),

                `ifdef  IF2ID_PIPELINE_STAGE
                    .inst    (if2id_data_pipe_ff.if2id),
                `else 
                    .inst    (inst_f2d),
                `endif  // IF2ID_PIPELINE_STAGE
                

                `ifdef E2M_CONTROLLER
                    .reg_wr         (e2m_control.reg_wr_mw), 
                `else 
                    .reg_wr         (reg_wr_mw), 
                `endif //E2M_CONTROLLER    
    
                `ifdef  IE2IM_PIPELINE_STAGE
                    .rd_m2w         (ie2im_data_pipe_ff.ie2im[11:7]),
                `else
                    .rd_m2w         (inst_e2m[11:7]),  
                `endif
                    
                    .wbdata         (wbdata),
                    .func3          (func3), 
                    .func7          (func7), 
                    .opcode         (opcode),
                    .rdata1         (rdata1), 
                    .rdata2         (rdata2), 
                    .imm_gen        (imm),

                    .illegal_instr  (illegal_instr)
                );

controller control (
                    .opcode     (opcode), 
                    .func3      (func3), 
                    .func7      (func7),

                    .alu_op     (alu_op), 
                    .reg_wr     (reg_wr), 
                    .sel_b      (sel_b), 
                    .rd_ctrl    (rd_ctrl), 
                    .wb_sel     (wb_sel),
                    .wr_ctrl    (wr_ctrl), 
                    .br_type    (br_type), 
                    .sel_a      (sel_a), 
                    .sel_pc     (sel_pc),
                    .br_taken   (br_taken),

                    .csr_wr_req (csr_wr_req),
                    .csr_reg_rd (csr_reg_rd),

                    .is_mret(is_mret)

                );

/* ----------------------------------------- EXECUTE STAGE ------------------------------------------ */
execute_phase execute (
                        .rdata1     (rdata1), 
                        .rdata2     (rdata2), 
                        .sel_b      (sel_b), 
                        .sel_a      (sel_a), 
                        .imm        (imm),

                    `ifdef  IF2ID_PIPELINE_STAGE
                        .pc_addr    (if2id_data_pipe_ff.pc_addr),
                    `else 
                        .pc_addr    (pc_addr_f2d),
                    `endif

                        .alu_op     (alu_op), 
                        .br_type    (br_type), 
                        .br_taken   (br_taken), 
                        .alu_out    (alu_out),

                    `ifdef  IE2IM_PIPELINE_STAGE
                        .alu_e2m    (ie2im_data_pipe_ff.alu_out),
                    `else 
                        .alu_e2m    (alu_out_e2m),
                    `endif //IE2IM_PIPELINE_STAGE

                        .for_b      (for_b),
                        .for_a      (for_a),
                        .forward_ae (forwarda_e),
                        .forward_be (forwardb_e)
                    );

//Register between Execute to Memory
register pc_e2m (
                    .clk        (clk), 
                    .rst_n      (rst_n),

                `ifdef  IF2ID_PIPELINE_STAGE
                    .in    (if2id_data_pipe_ff.pc_addr),
                `else 
                    .in    (pc_addr_f2d),
                `endif  //IF2ID_PIPELINE_STAGE

                `ifdef  IE2IM_PIPELINE_STAGE
                    .out        (ie2im_data_pipe_ff.pc_addr)
                `else 
                    .out        (pc_addr_e2m)
                `endif //IE2IM_PIPELINE_STAGE

                );

register alu_e2m (

                    .clk        (clk), 
                    .rst_n      (rst_n),

                    .in         (alu_out),                      
                    
                `ifdef  IE2IM_PIPELINE_STAGE
                    .out    (ie2im_data_pipe_ff.alu_out)
                `else 
                    .out    (alu_out_e2m)
                `endif //IE2IM_PIPELINE_STAGE

                );

register writedata2 ( 
                    .clk        (clk), 
                    .rst_n      (rst_n),

                    .in         (for_b),

                `ifdef  IE2IM_PIPELINE_STAGE
                    .out        (ie2im_data_pipe_ff.wd)
                `else  
                    .out        (rs2_e2m)
                `endif //IE2IM_PIPELINE_STAGE

                );

register writedata1 ( 
                    .clk        (clk), 
                    .rst_n      (rst_n),

                    .in         (for_a),

                    .out        (rdata1_mw)

                );

register csr_addr ( 
                    .clk        (clk), 
                    .rst_n      (rst_n),

                    .in         (imm),
                    
                    .out        (imm_mw)

                );

register ine2m (
                    .clk        (clk), 
                    .rst_n      (rst_n), 

                `ifdef  IF2ID_PIPELINE_STAGE
                    .in         (if2id_data_pipe_ff.if2id),
                `else 
                    .in         (inst_f2d),
                `endif

                `ifdef  IE2IM_PIPELINE_STAGE
                    .out        (ie2im_data_pipe_ff.ie2im)
                `else 
                    .out        (inst_e2m)
                `endif //IE2IM_PIPELINE_STAGE
                ); // instruction register

forward_unit forwarding (
                            .rst_n          (rst_n),

                        `ifdef  IF2ID_PIPELINE_STAGE
                            .inst_f2d    (if2id_data_pipe_ff.if2id),
                        `else 
                            .inst_f2d    (inst_f2d),
                        `endif

                        `ifdef  IE2IM_PIPELINE_STAGE
                            .inst_e2m        (ie2im_data_pipe_ff.ie2im),
                        `else 
                            .inst_e2m        (inst_e2m),
                        `endif //IE2IM_PIPELINE_STAGE

                            .br_taken       (br_taken),

                        `ifdef E2M_CONTROLLER
                            .reg_wr_mw         (e2m_control.reg_wr_mw), 
                        `else 
                            .reg_wr_mw         (reg_wr_mw), 
                        `endif //E2M_CONTROLLER 
                           
                            .interrupt_sel  (interrupt_sel),
                            .flush          (flush_r),
                            .forward_ae     (forwarda_e),
                            .forward_be     (forwardb_e)
                        );

//Controller Register between Execute to Memory stage
controller_m control_register1 ( 
                                .clk        (clk), 
                                .rst_n      (rst_n),

                                .reg_wr_e   (reg_wr), 
                                .sel_pc_e   (sel_pc),
                                .rd_ctrl_e  (rd_ctrl), 
                                .wb_sel_e   (wb_sel), 
                                .wr_ctrl_e  (wr_ctrl),

                                .csr_wr_req (csr_wr_req),
                                .csr_reg_rd (csr_reg_rd),

                                .csr_reg_rd_m (csr_reg_rd_mw),
                                .csr_wr_req_m (csr_wr_req_mw),
                                 
                                `ifdef E2M_CONTROLLER
                                    .reg_wr_m   (e2m_control.reg_wr_mw),
                                    .sel_pc_m   (e2m_control.sel_pc_mw),  
                                    .rd_ctrl_m  (e2m_control.rd_ctrl_mw), 
                                    .wb_sel_m   (e2m_control.wb_sel_mw), 
                                    .wr_ctrl_m  (e2m_control.wr_ctrl_mw)    
                                `else 
                                    .reg_wr_m   (reg_wr_mw),
                                    .sel_pc_m   (sel_pc_mw),
                                    .rd_ctrl_m  (rd_ctrl_mw), 
                                    .wb_sel_m   (wb_sel_mw), 
                                    .wr_ctrl_m  (wr_ctrl_mw)
                                `endif //E2M_CONTROLLER   

                                
                            );

/* ----------------------------------------- MEMORY STAGE ------------------------------------------- */
memory_phase memory ( 
                        .clk        (clk), 
                        
                    `ifdef  IE2IM_PIPELINE_STAGE
                        .addr    (ie2im_data_pipe_ff.alu_out),
                        .rdata2  (ie2im_data_pipe_ff.wd), 
                    `else 
                        .addr    (alu_out_e2m),
                        .rdata2  (rs2_e2m), 
                    `endif //IE2IM_PIPELINE_STAGE

                        //.csr_reg_rd (csr_reg_rd_mw),
                        //.csr_wr_req (csr_wr_req_mw),

                        //.rdata1     (rdata1_mw),
                        //.imm        (imm_mw[11:0]),
                        
                    `ifdef E2M_CONTROLLER
                        .wr_ctrl  (e2m_control.wr_ctrl_mw),    
                    `else 
                        .wr_ctrl  (wr_ctrl_mw),
                    `endif //E2M_CONTROLLER  

                    `ifdef E2M_CONTROLLER 
                        .rd_ctrl  (e2m_control.rd_ctrl_mw),    
                    `else 
                        .rd_ctrl    (rd_ctrl_mw),
                    `endif //E2M_CONTROLLER        
                        
                        //.csr_rdata  (csr_rdata),
                        .rdata      (rdata)
                    );

csr_regfile csr_unit(

                .rst_n(rst_n),
                .clk(clk),

                .csr_wdata(rdata1_mw),
                .csr_addr_i(imm_mw),

                .is_mret(is_mret),
                .ext_int (ext_int),

                `ifdef  IE2IM_PIPELINE_STAGE
                    .csr_pc       (ie2im_data_pipe_ff.pc_addr),
                `else 
                    .csr_pc        (pc_addr_e2m),
                `endif //IE2IM_PIPELINE_STAGE

                .csr_wr_req(csr_wr_req_mw),
                .csr_reg_rd(csr_reg_rd_mw),

                .epc_taken(epc_taken),
                .csr_epc(csr_epc),
                .interrupt_sel(inter),

                .csr_rdata(csr_rdata)
);

/* ----------------------------------------- WRITEBACK STAGE ------------------------------------------- */
write_back writeback (

                    `ifdef  IE2IM_PIPELINE_STAGE
                        .pc             (ie2im_data_pipe_ff.pc_addr),
                        .alu            (ie2im_data_pipe_ff.alu_out),
                    `else 
                        .pc             (pc_addr_e2m),
                        .alu            (alu_out_e2m),
                    `endif //IE2IM_PIPELINE_STAGE

                        .rdata         (rdata),
                        .csr_rdata     (csr_rdata), 

                
                    `ifdef E2M_CONTROLLER
                        .wb_sel     (e2m_control.wb_sel_mw),    
                    `else 
                        .wb_sel  (wb_sel_mw),                       
                    `endif //E2M_CONTROLLER                          
                        .data_o        (wbdata)
                    );

assign rando = br_type;

endmodule
