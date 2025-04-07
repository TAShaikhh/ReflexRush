`timescale 1ns / 1ps

module tb_lfsr_gen;
    reg clk;
    wire [11:0] rnd;

    lfsr_gen uut (
        .clk(clk),
        .rnd(rnd)
    );

    initial begin
        $display("Starting LFSR test...");
        clk = 0;
        #10;
        repeat (50) begin
            #5 clk = ~clk;
            #5 clk = ~clk;
            $display("rnd = %b", rnd);
        end
        $finish;
    end
endmodule
