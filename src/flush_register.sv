`include "./defines/pipeline_hdrs.svh" 

module flush_register(
    input logic [WIDTH-1:0]in,

    input logic flush, // csr_flush,

    input logic clk, rst_n,

    output logic [WIDTH-1:0]out
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) out <= '0;
    else if (flush) out <= 32'h00000033;  //nope (add x0,x0, x0)
    else out <= in; 
end

endmodule