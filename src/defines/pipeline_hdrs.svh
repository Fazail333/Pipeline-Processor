`ifndef PIPELINE_HDRS
`define PIPELINE_HDRS

parameter WIDTH = 32;
parameter DEPTH = 32;
parameter BYTE  = 08; 

typedef enum logic [6:0] {

    R_TYPE = 7'h33,
    I_TYPE = 7'h13,
    L_TYPE = 7'h03,
    S_TYPE = 7'h23,
    B_TYPE = 7'h63,
    LUI    = 7'h37,
    AUIPC  = 7'h17,
    JAL    = 7'h6f,
    JALR   = 7'h67,
    
    CSR    = 7'h73

}opcode_type_e;

//opcode_type_e       opcode;

typedef enum logic [3:0] {
    
    ADD  = 4'h0,
    SUB  = 4'h1,
    SLL  = 4'h2,
    SLT  = 4'h3,
    SLTU = 4'h4,
    XOR  = 4'h5,
    SRL  = 4'h6,
    SRA  = 4'h7,
    OR   = 4'h8,
    AND  = 4'h9,
    PASS = 4'hf,
    NULL = 4'ha

} aluop_type_e;

//aluop_type_e       alu_op;

`endif //PIPELINE_HDRS