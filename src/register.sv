`include "./defines/pipeline_hdrs.svh"

module register
    (
    input logic [WIDTH-1:0]in,

    input logic clk, rst_n,

    output logic [WIDTH-1:0]out
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) out <= '0;
    else out <= in; 
end

endmodule