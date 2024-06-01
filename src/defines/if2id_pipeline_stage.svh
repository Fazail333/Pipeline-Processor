`include "./pipeline_hdrs.svh"

`ifndef IF2ID_PIPELINE_STAGE
`define IF2ID_PIPELINE_STAGE

    typedef struct packed {

        logic [WIDTH-1:0] pc_addr;
        logic [WIDTH-1:0] if2id;

    } type_if2id_data_s;

`endif //IF2ID_PIPELINE_STAGE