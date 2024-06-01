`include "./defines/pipeline_hdrs.svh"

module execute_phase (
    input logic  [WIDTH-1:0] rdata1, pc_addr,

    input logic  [WIDTH-1:0] rdata2, imm,

    input aluop_type_e       alu_op,

    input logic  	         sel_b,
    input logic              sel_a, 

    input logic              forward_ae,
    input logic              forward_be,

    input logic [WIDTH-1:0]  alu_e2m,

    input logic [2:0]        br_type,

    output logic             br_taken,

    output logic [WIDTH-1:0] for_b,for_a,

    output logic [WIDTH-1:0] alu_out
);

logic [WIDTH-1:0] src_a ,src_b;
//logic [WIDTH-1:0] for_a;

// forwarding mux
assign for_a = (forward_ae) ? alu_e2m : rdata1 ;
assign for_b = (forward_be) ? alu_e2m : rdata2 ;

// 2 x 1 mux use for the selection of src_b and src_a
assign src_b = (sel_b) ? imm : for_b;
assign src_a = (sel_a) ? pc_addr : for_a;



/* ############################## ALU ############################### */
always_comb begin
    case(alu_op)
        ADD : alu_out = src_a + src_b;             //addition
        SUB : alu_out = src_a + (~src_b + 1'b1);   //subtraction
        SLL : alu_out = src_a << src_b;            //shift logic left
        SLT : alu_out = (src_a < src_b) ? 1 : 0 ;  //set less then
        SLTU: alu_out = ($unsigned(src_a) < $unsigned(src_b)) ? 1 : 0 ; //set less then unsigned
        XOR : alu_out = src_a ^ src_b;             //xor operation
        SRL : alu_out = src_a >> src_b;            // shift right logic
        SRA : alu_out = $signed(src_a) >>> src_b ; // shift rigth arithematic
        OR  : alu_out = src_a | src_b;             // or operation
        AND : alu_out = src_a & src_b;             // and operaion
        // Pass through only use for U-type
        PASS: alu_out = src_b;                     // Load Upper Immediate (U-type)
        
        default : alu_out = alu_out;
    endcase
end

/* ####################### Branch comparator ######################## */
// B-Type
always_comb begin : Branch_comparator
    case (br_type)
        3'b000: br_taken = (for_a == for_b) ? 1'b1 : 1'b0;           
        3'b001: br_taken = (for_a != for_b) ? 1'b1 : 1'b0;
        3'b100: br_taken = (for_a <  for_b) ? 1'b1 : 1'b0;
        3'b101: br_taken = (for_a >= for_b) ? 1'b1 : 1'b0;
        3'b110: br_taken = ($unsigned(for_a) < $unsigned(for_b)) ? 1'b1 : 1'b0;
        3'b111: br_taken = ($unsigned(for_a) >= $unsigned(for_b)) ? 1'b1 : 1'b0;
        default: br_taken = '0;
    endcase
end

/*always_comb begin : Branch_comparator
    case (br_type)
        3'b000: br_taken = (rdata1 == rdata2) ? 1'b1 : 1'b0;           
        3'b001: br_taken = (rdata1 != rdata2) ? 1'b1 : 1'b0;
        3'b100: br_taken = (rdata1 < rdata2 ) ? 1'b1 : 1'b0;
        3'b101: br_taken = (rdata1 >= rdata2) ? 1'b1 : 1'b0;
        3'b110: br_taken = ($unsigned(rdata1) < $unsigned(rdata2)) ? 1'b1 : 1'b0;
        3'b111: br_taken = ($unsigned(rdata1) >= $unsigned(rdata2)) ? 1'b1 : 1'b0;
        default: br_taken = '0;
    endcase
end */
    
endmodule
