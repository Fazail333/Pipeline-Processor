`include "./pipeline_hdrs.svh"

`ifndef IE2IM_PIPELINE_STAGE
`define IE2IM_PIPELINE_STAGE

    typedef struct packed {

        logic [WIDTH-1:0] pc_addr;
        logic [WIDTH-1:0] alu_out;
        logic [WIDTH-1:0] wd;
        logic [WIDTH-1:0] ie2im;

    } type_ie2im_data_s;

`endif //IE2IM_PIPELINE_STAGE