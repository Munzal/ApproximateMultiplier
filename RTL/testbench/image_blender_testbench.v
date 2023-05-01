`timescale 1 ns / 1 ns
`include "image_blender.v"
module image_blender_testbench();
    
    reg clk, rst;
    reg [1:0] state;
    reg [7:0] data_in_1;
    reg [7:0] data_in_2;
    wire [7:0] data_out;
    integer i;
    reg [17:0] packer;
    integer MCD1;

    image_blender APRIL(packer, clk, rst, data_out);

    always begin
        #1;
        clk = ~clk;
        packer = {state, data_in_1, data_in_2};
    end

    

    initial begin
        MCD1 = $fopen("mem_18_bit.txt");
        clk = 0;
        rst = 0;
        data_in_1 = 0;
        data_in_2 = 0;
        state = 0;
    end

    initial begin
        $dumpfile("image_blender_testbench.vcd");
        $dumpvars(0, image_blender_testbench);
        //MCD1 = $fopen("result_pro.txt");
        #1;
        rst = 1;
        #2;
        rst = 0;
        #2;
        rst = 1;
        state = 1;
        data_in_1 = 8'b11;//3 2^(3+1) = 16, 1 is due to case statement logic
        #2;
        state = 2;
        data_in_1 = 8'd9;
        data_in_2 = 8'd7;
        #2;
        state = 0;
        for(i=100; i<256; i=i+1)
        begin
            data_in_1 = i+50;
            data_in_2 = i-50;
            #2;
            $fdisplay(MCD1, "%d", packer);
            $display("%d", data_out);
        end
        $fclose(MCD1);

    end

    initial begin
        #400;
        $finish;
    end
endmodule

/*
iverilog -o image_blender_testbench.vvp image_blender_testbench.v
vvp image_blender_testbench.vvp
gtkwave
*/