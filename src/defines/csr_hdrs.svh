`include "./pipeline_hdrs.svh"

`ifndef CSR_HDRS
`define CSR_HDRS

typedef enum logic [11:0] {

    CSR_ADDR_MSTATUS = 12'h300,
    CSR_ADDR_MIE     = 12'h304,
    CSR_ADDR_MTVEC   = 12'h305,
    CSR_ADDR_MEPC    = 12'h341,
    CSR_ADDR_MCAUSE  = 12'h342,
    CSR_ADDR_MIP     = 12'h344

} type_csr_e;

typedef struct packed {
    
    logic [11:0] csr_addr;
    logic [WIDTH-1:0] csr_data;
    logic [WIDTH-1:0] csr_pc;


} type_exe2csr_data_s;

type_exe2csr_data_s     exe2csr_data;

typedef struct packed {
    
    logic csr_reg_rd;
    logic csr_wr_req;


} type_exe2csr_ctrl_s;

type_exe2csr_ctrl_s     exe2csr_ctrl;

`endif 