`include "./defines/pipeline_hdrs.svh"
`include "./defines/csr_hdrs.svh"

module csr_regfile(

	input logic 			rst_n,
	input logic 			clk,

	input logic [WIDTH-1:0] csr_wdata,		// rdata1
	input logic [11:0]		csr_addr_i,		// csr address >> immediate
	input logic [WIDTH-1:0] csr_pc,

	input logic 			csr_wr_req,		// csr write request
	input logic 			csr_reg_rd,		// csr register read
	
	input logic 			is_mret,
	
	input logic 			ext_int,

	output logic 			interrupt_sel,
	output logic 			epc_taken,
			
	output logic [WIDTH-1:0] csr_epc,
	output logic [WIDTH-1:0] csr_rdata

);
type_csr_e 		csr_addr;

//logic [30:0] exp_code;	// mcause exception code
logic int_exp; 			// interrupt / execption

logic [WIDTH-1:0] csr_mstatus_ff, csr_mie_ff, csr_mtvec_ff; // Machine trap setup
logic [WIDTH-1:0] csr_mcause_ff, csr_mip_ff, csr_mepc_ff;   // Machine trap handling

logic csr_mstatus_wr_flag, csr_mie_wr_flag, csr_mtvec_wr_flag;
//logic csr_mcause_wr_flag, csr_mip_wr_flag, csr_mepc_wr_flag;

assign csr_addr = type_csr_e'(csr_addr_i);

assign interrupt_sel = int_exp | is_mret;

// CSR READ OPERATION
always_comb begin
	csr_rdata = '0;
	if (csr_reg_rd) begin
		case (csr_addr)
			CSR_ADDR_MSTATUS	: csr_rdata = csr_mstatus_ff;
			CSR_ADDR_MIE		: csr_rdata = csr_mie_ff;
			CSR_ADDR_MIP		: csr_rdata = csr_mip_ff;
			CSR_ADDR_MCAUSE		: csr_rdata = csr_mcause_ff;
			CSR_ADDR_MTVEC		: csr_rdata = csr_mtvec_ff;
			CSR_ADDR_MEPC		: csr_rdata = csr_mepc_ff;
		endcase // csr_addr
	end // csr_reg_rd
end

// CSR write operation
always_comb begin
	csr_mstatus_wr_flag = 1'b0;
	csr_mie_wr_flag		= 1'b0;
	csr_mtvec_wr_flag	= 1'b0;
	if (csr_wr_req) begin
		case (csr_addr)
			CSR_ADDR_MSTATUS	: csr_mstatus_wr_flag 	= 1'b1;
			CSR_ADDR_MIE		: csr_mie_wr_flag	    = 1'b1;
			CSR_ADDR_MTVEC		: csr_mtvec_wr_flag		= 1'b1;
		endcase 	// (csr_addr)
	end 		// (csr_wr_req) 
end

// Update the mie (machine interrupt enable), mstatus and mtvec CSRs
// these registers are configured by the software (CSRRW instruction)
always_ff @(negedge rst_n, posedge clk) begin
	if (~rst_n) begin
		csr_mie_ff 		<= '0;
		csr_mstatus_ff 	<= '0;
		csr_mtvec_ff 	<= '0;
	end else if (csr_mie_wr_flag) begin
		csr_mie_ff 		<= csr_wdata;
	end else if (csr_mstatus_wr_flag) begin
		csr_mstatus_ff 	<= csr_wdata;
	end else if (csr_mtvec_wr_flag) begin
		csr_mtvec_ff 	<= csr_wdata;
	end
end

// Interrupt Handling 
assign int_exp = (csr_mstatus_ff [3] & (csr_mip_ff[11] & csr_mie_ff[11])); 

// Update the mip (machine interrupt pending), mepc, mtvec CSR
always_ff @(negedge rst_n, posedge clk) begin
	if (~rst_n) begin
		csr_mip_ff 		<= '0;
		csr_mepc_ff 	<= '0;
		csr_mcause_ff 	<= '0;
	end else if (ext_int) begin
		csr_mip_ff 		<= 32'h800;				// source of the interrupt is external
		csr_mepc_ff 	<= csr_pc;
		csr_mcause_ff 	<= {int_exp, 31'd11};	// exception code of external interrupt is 11
	end 
end

always_ff @( posedge clk ) begin 
	if (int_exp) begin
		epc_taken 	<= 1'b1;
		csr_mie_ff 	<= '0;
		case (csr_mtvec_ff[1:0])
			2'b00: csr_epc <= csr_mtvec_ff[31:2]; 									// Direct mode
			2'b01: csr_epc <= csr_mtvec_ff[31:2] + (csr_mcause_ff [30:0] * 4);		// Vector mode
		endcase
	end else if (is_mret) begin
		epc_taken 	<= 1'b1;
		csr_epc   	<= csr_mepc_ff;
	end	else begin
		epc_taken 	<= '0;
		csr_epc   	<= '0;
	end
end

endmodule

/*always_ff @(posedge clk) begin 
	if (int_exp) begin
		csr_mie_ff 		<= 32'h0;
	end
end*/

/*always_comb begin 
	if (int_exp) begin
		epc_taken 	= 1'b1;
		csr_mie_ff 	= '0;
		case (csr_mtvec_ff[1:0])
			2'b00: csr_epc = csr_mtvec_ff[31:2]; 									// Direct mode
			2'b01: csr_epc = csr_mtvec_ff[31:2] + (csr_mcause_ff [30:0] * 4);		// Vector mode
		endcase
	end else if (is_mret) begin
		epc_taken 	= 1'b1;
		csr_epc   	= csr_mepc_ff;
	end	else begin
		epc_taken 	= '0;
		csr_epc   	= '0;
	end
end*/

/*always_ff @(posedge clk) begin 

	// if interrupts occurs and not mret instruction is selected handle the interrupt
	if ((csr_mstatus_ff [3]) & ((csr_mip_ff[11] & csr_mie_ff[11]))) begin

		epc_taken  <= 1;
		csr_mie_ff <= '0;

		// update mcause exception code after interrupt occurs
		exp_code <= 31'd11;

		// output of csr_epc/ csrevec select on the offset of mtvec register value
		case (csr_mtvec_ff[1:0])
			2'b00: csr_epc <= csr_mtvec_ff[31:2];
			2'b01: csr_epc <= csr_mtvec_ff[31:2] + (csr_mcause_ff << 2);
		endcase

		csr_flush  <= 1'b1;
	end

	// if int_exp and mret instruction is execute then jump return to address from where interrupts occur
	else if (is_mret) begin
		epc_taken <= 1;
		csr_epc   <= csr_mepc_ff;
		exp_code  <= '0;
		csr_flush <= '0;	
	end

	else begin
		epc_taken <= '0;
		exp_code  <= '0;
		csr_epc   <= '0;
		csr_flush <= '0;
	end
end*/

/* mstatus-Register 

--> mie = 1; globally enabled interrupt
--> mpie  holds the value of the interrupt enable bit active prior to the trap.
--> mpp holds the previous privilege mode. 
--> The xPP fields can only hold privilege modes up to x , so MPP is two bits wide.
--> An MRET  instruction is used to return from a trap in M-mode.
--> MPRV = 0, LOADS AND STORES BHAVES AS NORMAL.
--> MXR = 0
--> SUM = 0
--> UBE = 0
--> MBE = 0
--> TVM = 0 when S-mode is not supported.
--> TW  = 0
--> TSR = 0 when S-mode is not supported.
--> FS = 0
--> VS = 0 , v registrer and s-mode both are not supported.
--> XS = 0
--> SD = 0


mtvec-Register

--> base address and vector mode
--> BASE field always be aligned on a 4-byte boundary
--> MODE (0 == Direct, 1 == Vectored (Asynchronous interrupts set pc to BASE+4*cause))

mcasue --> values after trap. 3 ( machine software interrupt); 7 (machine timer interrupt); 11 (machine external interrupt)

mip --> containig information on pending interrupts
		mip.MEIP (read-only) and mip.MEIE  / mip.STIP,SEIP,SSIP = 0. 
mie --> containing information on enabled interrupts
		mie.MEIP (read-only) and mie.MEIE  / mie.STIP,SEIP,SSIP = 0. 

mepc[0] --> always zero on the zeroth bit.
*/

/*always_comb begin 
	// machine timer interrupt
	if (csr_mstatus_ff[3] | (csr_mip_ff[7] & csr_mie_ff[7]))
	begin
		int_exp  = 1'b1;		// interrupt / exception
		exp_code = 4'd7;		// mcause.exception code
	end

	// machine external interrupt
	else if (csr_mstatus_ff[3] | (csr_mip_ff[7] & csr_mie_ff[7]))
	begin
		int_exp  = 1'b1;		// interrupt / exception
		exp_code = 4'd11;		// mcause.exception code
	end

	else begin
		int_exp  = 1'b0;
		exp_code = 4'd0; 
	end
end*/


/*always_comb begin
	if (csr_mip_ff[7] & csr_mie_ff[7]) begin
		exp_code = 31'd7;			// mcause exception code
	end
	else if (csr_mip_ff[11] & csr_mie_ff[11]) begin
		exp_code = 31'd11;
	end 
	else 
		exp_code = 31'd0;
end*/

//Machine Interrupt Pending register
 /* always_comb begin
    if (csr_mcause_ff[31]) begin
      if (csr_mcause_ff[30:0] == 7) begin //2nd bit 1 
        csr_mip_ff = 32'h80;  //for timer interrupt 7th bit is 1
      end else if (csr_mcause_ff[30:0] == 11) begin
        csr_mip_ff = 32'h800;  //for external interrupt 11th bit is 1
      end
    end 
	
	else begin
      	csr_mip_ff = 32'h00000000;
    end
  end*/

  /*always_comb begin 
	if (int_exp) begin
		epc_taken = 1'b1;
		if (csr_mip_ff[11] & csr_mie_ff[11]) begin
			exp_code = 31'd11;
		end else begin
			exp_code = 31'd0;
		end
	end
end*/


/*always_comb begin 
	if      (ext_int) 				epc_taken = 1;
	else if (~ext_int & is_mret) 	epc_taken = 1;
	else 	    	 				epc_taken = 0;
end*/
// Address Calculation in CSR register file
/*always_comb begin 

	// if interrupts occurs and not mret instruction is selected handle the interrupt
	if (int_exp & ~is_mret) begin

		// update mcause exception code after interrupt occurs
		if (csr_mip_ff[11] & csr_mie_ff[11]) begin
			exp_code = 31'd11;
		end else begin
			exp_code = 31'd0;
		end

		// output of csr_epc/ csrevec select on the offset of mtvec register value
		case (csr_mtvec_ff[1:0])
			2'b00: csr_epc = csr_mtvec_ff[31:2];
			2'b01: csr_epc = csr_mtvec_ff[31:2] + (csr_mcause_ff << 2);
		endcase
	end

	// if int_exp and mret instruction is execute then jump return to address from where interrupts occur
	else if (int_exp & is_mret) begin
		csr_epc = csr_mepc_ff;
		
	end

	else begin
		csr_epc = '0;
		exp_code = '0;
	end
end*/

/*// Update the mepc CSR
always_ff @(negedge rst_n, posedge clk) begin
	if (~rst_n) begin
		csr_mepc_ff <= '0;
	end else if (ext_int) begin
		csr_mepc_ff <= csr_pc;		
	end
end

// Update the mcause CSR
always_ff @(negedge rst_n, posedge clk) begin
	if (~rst_n) begin
		csr_mcause_ff <= '0;
	end else if (int_exp) begin
		csr_mcause_ff <= {int_exp, exp_code};
	end
end*/
