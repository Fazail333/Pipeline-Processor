`include "./defines/pipeline_hdrs.svh"

module decode_phase (
    input logic [WIDTH-1:0] inst,
    
    input logic             clk,
    input logic             rst_n,

    input logic             reg_wr,

    input logic [WIDTH-1:0] wbdata,

	input logic [4:0] 		rd_m2w,  // destination register comes from writeback dest_reg

	output logic [4:0]		rd,
    output logic [2:0]      func3,
    output logic [6:0]      func7,
    //output logic [6:0]      opcode,		
	output opcode_type_e      opcode,

    output logic [WIDTH-1:0] rdata1,
    output logic [WIDTH-1:0] rdata2,
    
    output logic [WIDTH-1:0] imm_gen,

	output logic 			 illegal_instr    
);

logic [4:0] rs1, rs2; // 5-bit register addresses
logic [WIDTH-1:0] rf [DEPTH]; //register file
logic [11:0]imm;
logic [19:0]imm_u_type;

assign opcode = opcode_type_e'(inst[6:0]);
//opcode = opcode_type_e'(inst[6:0]);


always_comb begin : inst_decoder
	illegal_instr = 1'b0;
	case (opcode)
		/*  ###### R-Type instructions 7'h33 ######  */ 
		R_TYPE: begin
				rd     = inst[11:7];
				func3 = inst[14:12];
				rs1    = inst[19:15];
				rs2    = inst[24:20];
				func7 = inst[31:25];

				imm    = 12'h000;
				imm_u_type = 20'h00000;
			end
		
		/*  ###### I-Type instructions 7'h13 ######  */
		I_TYPE: begin
				rd     = inst[11:7];
				func3  = inst[14:12];
				rs1    = inst[19:15];
				
				case ({func3,inst[31:25]})
					10'b0010100000 : begin
							imm   = inst[24:20];
							func7 = inst[31:25];
						end
					10'b1010100000 : begin 
							func7 = inst[31:25];
							imm   = inst[24:20];
						end
					10'b1010000000 : begin 
							func7 = inst[31:25];
							imm   = inst[24:20];
						end
					default: begin 
							func7 = 7'h00;
							imm = inst[31:20];
						end
				endcase
				
				rs2    = 5'h00;
				imm_u_type = 20'h00000;
			end

		/* ###### Load instructions 7'h03 ###### */
		L_TYPE: begin
			rd     = inst[11:7];
			func3  = inst[14:12];
			rs1    = inst[19:15];
			imm    = inst[31:20];

			rs2    = 5'h00;
			func7 = 7'h00;
			imm_u_type = 20'h00000;
			
		end

		/* ###### Store instructions 7'h23 ###### */
		S_TYPE: begin
			  	func3  = inst[14:12];
		  	  	rs1    = inst[19:15];
		    	rs2    = inst[24:20];
		        imm    = {inst[31:25] , inst[11:7]};

		        rd     = 5'h00;
		        imm_u_type = 20'h00000;
		        func7  = 7'h00;	  
		    end

		/* ###### Branch instructions ###### */
		// B-Type 7'h63
		B_TYPE : begin
				func3  = inst[14:12];
		  	  	rs1    = inst[19:15];
		    	rs2    = inst[24:20];
		        imm    = {inst[31] ,inst[7], inst[30:25], inst[11:8]};

		        rd     = 5'h00;
		        imm_u_type = 20'h00000;
		        func7  = 7'h00;	 
			end
		
		/* ###### Upper Immediate instructions ###### */
		// LUI 7'h37
		LUI: begin
		        rd    = inst[11:7];
		        imm_u_type = inst[31:12];

			  	rs1   = '0;
		        rs2   = '0;
		        func3 = '0;
		        func7 = '0;
		        imm    = 12'h000;
		    end
		// AUIPC = 7'h17
		AUIPC: begin
		        rd    = inst[11:7];
		        imm_u_type = inst[31:12];

			  	rs1   = '0;
		        rs2   = '0;
		        func3 = '0;
		        func7 = '0;
		        imm    = 12'h000;
		    end

		/* ###### JAL instruction 7'h6f ###### */
		JAL: begin
				rd    = inst[11:7];
		        imm_u_type = { inst[31] ,inst[19:12] ,inst[20] ,inst[30:21]};

			  	rs1   = '0;
		        rs2   = '0;
		        func3 = '0;
		        func7 = '0;
		        imm    = 12'h000;
			end

		/* ###### JALR instruction 7'h67 ##### */
		JALR: begin
			rd     = inst[11:7];
			func3  = inst[14:12];
			rs1    = inst[19:15];
			imm    = inst[31:20];

			rs2    = 5'h00;
			func7  = 7'h00;
			imm_u_type = 20'h00000;		
		end

		/* ###### JALR instruction 7'h67 ##### */
		CSR: begin 
				rd 	   = inst[11:7];
				func3  = inst[14:12];
				rs1    = inst[19:15];
				imm    = inst[31:20];
				//func7  = inst[31:25];
				//rs2    = inst[24:20];

				rs2    = 5'h00;
				func7  = 7'h00;
				imm_u_type = 20'h00000;	
		end

		default : begin
			rd    = '0;
		    imm_u_type = '0;
		  	rs1   = '0;
	        rs2   = '0;
	        func3 = '0;
	        func7 = '0;
	        imm   = '0;
			illegal_instr = 1'b1;
		end
	endcase
end

initial begin
	$readmemh("/home/fazail/3_stage_Pipeline_csr/memory/reg_file.mem", rf);
end

always_ff @(negedge clk)
begin
    /*if (!rst_n) begin
		rd_m2w <= '0;
	end*/
    if (reg_wr) begin
		rf[rd_m2w] <= ((rd_m2w != 0) ? wbdata : '0);
	end
	else begin
		rf[rd_m2w] <= ((rd_m2w != 0) ? rf[rd_m2w] : '0);
	end
end

assign rdata1 = (rs1 != 0) ? rf[rs1] : 0;
assign rdata2 = (rs2 != 0) ? rf[rs2] : 0;

/* ############# Immediate Generation ############# */

always_comb begin
	case (opcode)
	/* I-type instructions */
	I_TYPE:case (func3)
			3'b001: imm_gen = {20'b0, imm[11:0]};
			3'b101: imm_gen = {20'b0, imm[11:0]};
			default: imm_gen = $signed({imm[11:0]}); // { {20{imm[11]}}, imm[11:0] }
		endcase

	/* Load type */
	L_TYPE: imm_gen = $unsigned({imm[11:0]});

	/* Store type */
	S_TYPE: imm_gen = $signed({imm[11:0]}) ; // { {20{imm[11]}}, imm[11:0] }

	/* Branch type */
	B_TYPE: imm_gen = $signed({imm , 1'b0});  // { {19{imm[11]}}, imm , 1'b0}

	/* Load Upper Immediate */
	LUI: imm_gen = {imm_u_type, 12'b0};

	/* Add Upper Immediate to pc */
	AUIPC: imm_gen = {imm_u_type, 12'b0};

	/* JAL instruction  */
	JAL: imm_gen = $signed({imm_u_type ,1'b0});  // {{11{imm[11]}}, imm , 1'b0} working wrong

	/* JALR instruction */
	JALR: imm_gen = $signed({imm , 1'b0});

	/* CSR instruction */
	CSR: imm_gen = $unsigned({imm[11:0]});

	default: imm_gen = 32'h0000_0000;
	endcase
end

endmodule

