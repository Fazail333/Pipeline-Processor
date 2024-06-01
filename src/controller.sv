`include "./defines/pipeline_hdrs.svh"
module controller (
    input opcode_type_e opcode,
    
    input logic [2:0]   func3,
    input logic [6:0]   func7,

    input logic         br_taken,

    output aluop_type_e alu_op,
    output logic        reg_wr,
    
    output logic        sel_b,
    output logic        sel_a,
    output logic        sel_pc,

    output logic [2:0]  rd_ctrl,  // Read control for data memory. 
    output logic [1:0]  wb_sel,  // Write Back Selection.

    output logic [2:0]  wr_ctrl,

    output logic [2:0]  br_type,

    output logic        is_mret,

    output logic        csr_wr_req,
    output logic        csr_reg_rd
);

always_comb begin
    case (opcode)
        R_TYPE : begin // R - Type 
            sel_pc = (br_taken) ? 1'b1 : 1'b0;      // sel_pc for (pc + imm) or (pc + 4)
            sel_a  = 1'b0;                          // sel_a for selecting imm or 4 for pc register
            br_type = 3'b011;                       // branching type for conditional jumps
            rd_ctrl  = 3'h3;
            wb_sel = 2'b00;
        	sel_b  = 1'b0;
            reg_wr = 1'b1;
            wr_ctrl = 3'b111;
            case (func3)
                3'b000 : begin
                            case (func7)
                                7'h00 : alu_op = ADD;
                                7'h20 : alu_op = SUB;
                                default: alu_op = NULL;
                            endcase
                        end

                3'b001 : alu_op = SLL;
                3'b010 : alu_op = SLT;
                3'b011 : alu_op = SLTU;
                3'b100 : alu_op = XOR;

                3'b101 : begin
                            case (func7)
                                7'h00 : alu_op = SRL;
                                7'h20 : alu_op = SRA;
                                default: alu_op = NULL;
                            endcase
                        end

                3'b110 : alu_op = OR;
                3'b111 : alu_op = AND;
                default : alu_op = NULL;        
            endcase 
            end
                
        I_TYPE : begin // I - Type
            sel_pc = (br_taken) ? 1'b1 : 1'b0;      // sel_pc for (pc + imm) or (pc + 4)
            sel_a  = 1'b0;                          // sel_a for selecting imm or 4 for pc register
            br_type = 3'b011;                       // branching type for conditional jumps
            rd_ctrl  = 3'h3;
            wb_sel = 2'b00;
        	sel_b  = 1'b1;
        	reg_wr = 1'b1;
            wr_ctrl = 3'b111;
        	case (func3) 
                3'b000 : alu_op = ADD;
                
                3'b001 : begin
                        if (func7 == 7'h00) begin
                        alu_op = SLL; end
                        else alu_op = NULL;
                        end
                        
                3'b010 : alu_op = SLT;        	   
                3'b011 : alu_op = SLTU;           // set less then immediate unsigned      	   
                3'b100 : alu_op = XOR;
                
                3'b101 : begin 
                        case (func7)
                            7'h00 : alu_op = SRL;
                            7'h20 : alu_op = SRA;
                            default: alu_op = NULL;
                        endcase
                        end
                    
                3'b110 : alu_op = OR;
                3'b111 : alu_op = AND;
                default: alu_op = NULL;
		    endcase
	    	end

        L_TYPE : begin // Load Type
            sel_pc = (br_taken) ? 1'b1 : 1'b0;      // sel_pc for (pc + imm) or (pc + 4)
            sel_a  = 1'b0;                          // sel_a for selecting imm or 4 for pc register
            br_type = 3'b011;                       // branching type for conditional jumps
            wb_sel = 2'b01;                  // It selects whether the signal comes from alu_out or from data memory.
        	sel_b  = 1'b1;
        	reg_wr = 1'b1;
            alu_op = ADD; 
            wr_ctrl = 3'b111;
            case (func3)
                /**read control signal use to decide for loading word/byte/halfword/byte_unsigned/halfword_unsigned**/
                3'b000: rd_ctrl  = 3'h0;    // Load byte signed
                3'b001: rd_ctrl  = 3'h1;    // Load halfword signed
                3'b010: rd_ctrl  = 3'h2;    // Load word
                3'b100: rd_ctrl  = 3'h4;    // Load byte unsigned
                3'b101: rd_ctrl  = 3'h5;    // Load halfword unsigned
                default: rd_ctrl = 3'h3;    // this would be do nothing 
            endcase
            end

        S_TYPE: begin // Store Type
            sel_pc = (br_taken) ? 1'b1 : 1'b0;      // sel_pc for (pc + imm) or (pc + 4)
            sel_a  = 1'b0;                          // sel_a for selecting imm or 4 for pc register
            br_type = 3'b011;                       // branching type for conditional jumps
            rd_ctrl  = 3'h3;                        // reading zeros
            wb_sel = 2'b11;                          // write back from data memory
        	sel_b  = 1'b1;                          // select 12-bit immediate
            alu_op = ADD;                       // addition
        	reg_wr = 1'b0;                          // not write in the register
            case (func3)
                3'b000: wr_ctrl = 3'b000;           // Load word
                3'b001: wr_ctrl = 3'b001;           // Load byte
                3'b010: wr_ctrl = 3'b010;           // Load halfword
                default: wr_ctrl = 3'b111;
            endcase
            end

        B_TYPE: begin  // Branch Type (b-type)
            rd_ctrl  = 3'h3;
            wb_sel = 2'b01;
            reg_wr = 1'b0;
            wr_ctrl = 3'b111;
            sel_pc = (br_taken) ? 1'b1 : 1'b0;      // sel_pc for (pc + imm) or (pc + 4)
            sel_a  = 1'b1;                          // sel_a for selecting imm or 4 for pc register
            sel_b  = 1'b1;
            alu_op = ADD;                          // addition
            case(func3)
                3'b000: br_type = 3'b000;
                3'b001: br_type = 3'b001;
                3'b100: br_type = 3'b100;
                3'b101: br_type = 3'b101;
                3'b110: br_type = 3'b110;
                3'b111: br_type = 3'b111;
                default: br_type = 3'b011;
            endcase 
            end

        LUI: begin  // Load Upper immediate (U-type) (LUI)
                sel_pc = 1'b0;
                reg_wr = 1'b1;
                sel_b  = 1'b1;
                wb_sel = 2'b00;
                alu_op = PASS;                      // pass through 20 bit immediate to alu_out

                rd_ctrl  = 3'h3;
                wr_ctrl = 3'b111;
                sel_a  = 1'b0;
                br_type = 3'b011;
            end

        AUIPC: begin  // Add Upper immediate to pc (U-type) (AUIPC)
                sel_pc = 1'b0;
                reg_wr = 1'b1;
                sel_b  = 1'b1;
                wb_sel = 2'b00;
                alu_op = ADD;                      // addition of PC and 20 bit immediate 

                rd_ctrl  = 3'h3;
                wr_ctrl = 3'b111;
                sel_a  = 1'b1;                      // sel_a use for pc selection
                br_type = 3'b011;
                
            end

        JAL: begin  // Jump and Link
                sel_pc = 1'b1;                      // PC + imm
                wb_sel = 2'b10;                     // PC + imm
                reg_wr = 1'b1;                      // rd on
                sel_b  = 1'b1;                      // imm
                alu_op = ADD;                      // addition

                rd_ctrl  = 3'h3;                    // read control is zero
                wr_ctrl = 3'b111;                   // write control is zero
                sel_a  = 1'b1;                      // sel_a use for pc selection
                br_type = 3'b011;
            end

        JALR: begin  // Jump and Link Register
                sel_pc = 1'b1;
                wb_sel = 2'b10;
                reg_wr = 1'b1;
                sel_b  = 1'b1;
                alu_op = ADD;

                rd_ctrl  = 3'h3;
                wr_ctrl = 3'b111;
                sel_a  = 1'b0;
                br_type = 3'b011;   
        end

        CSR: begin
                case (func3)
                // CSRRW
                    3'b001: begin 
                                sel_a = 1'h0;
                                sel_b = 1'h1;
                                reg_wr = 1'h1;
                                wb_sel = 2'b11;
                                alu_op = ADD;

                                rd_ctrl  = 3'h3;
                                wr_ctrl = 3'h3;
                                br_type = 3'h3;

                                csr_wr_req = 1'b1;
                                csr_reg_rd = 1'b1;
                                
                                is_mret = 1'b0;
                            end
                // MRET
                    3'b000: begin 
                                sel_a = 1'h0;
                                sel_b = 1'h0;
                                reg_wr = 1'h0;
                                wb_sel = 2'b00;
                                alu_op = ADD;

                                rd_ctrl  = 3'h3;
                                wr_ctrl = 3'h3;
                                br_type = 3'h3;

                                csr_wr_req = 1'b0;
                                csr_reg_rd = 1'b0;

                                is_mret = 1'h1; 
                            end
                endcase
        end
        default: begin
                sel_pc = 1'b0;
                wb_sel = 2'b00;
                reg_wr = 1'b0;
                sel_b  = 1'b0;
                alu_op = NULL;

                rd_ctrl  = 3'h3;
                wr_ctrl = 3'b111;
                sel_a  = 1'b0;                      // sel_a use for pc selection
                br_type = 3'b011;

                csr_wr_req = 1'b0;
                csr_reg_rd = 1'b0;

                is_mret    = 1'b0;
            end
    endcase
end
    
endmodule
