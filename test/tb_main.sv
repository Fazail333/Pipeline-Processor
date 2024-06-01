//`include "./defines/header.svh"

module tb_main();

logic clk;
logic rst_n;

logic ext_int;

logic [31:0]inst;

logic [31:0] rando;

main UUT (.clk(clk),
          .rst_n(rst_n),
          .inst(inst),
          .rando(rando),
          .ext_int(ext_int)
          );

initial begin
            //initial value of clock
            clk = 1'b1;
            //generating clock signal
            forever #10 clk = ~clk;
    end

initial begin 
    initial_sequence;
    reset_sequence;
    repeat (8) @(posedge clk);
    ext_int <= 1;
    @(posedge clk);
    ext_int <= 0;
    repeat(90) @(posedge clk);
    @(posedge clk);
    $finish;
    end

task reset_sequence;
        begin 
            rst_n <= 0;
            @(posedge clk) rst_n <= 1; 
            //@(posedge clk) rst_n <= 1;
        end
endtask 

task initial_sequence;
	begin
	    rando <= 0; inst  <= 0; ext_int <= 0;
	end
endtask
    
endmodule
