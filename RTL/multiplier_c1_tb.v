`timescale 1 ns / 1 ns
`include "multiplier_pro.v"
module multiplier_pro_tb();
    wire [15:0] prod;
    reg [7:0] num1;
    reg [7:0] num2;
    reg [15:0] actual;
    reg [15:0] xor_output;
    integer freq [0:15];
    integer i;
    integer count;
    multiplier_nov NOV(prod, num1, num2);
    integer MCD1;

    initial begin
        $dumpfile("multiplier_pro_tb.vcd");
        $dumpvars(0, multiplier_pro_tb);
        MCD1 = $fopen("result_pro.txt");
        count=0;
        for(i=0; i<16; i=i+1)
        begin
            freq[i] = 0;
        end
        for(num1=8'd1; num1!=0 && num1<=8'hFF; num1 = num1 + 1)
        begin
            for(num2 = 8'd1; num2!=0 && num2<=num1; num2=num2+1)
            begin
                #1;
                actual = num1 * num2;
                $fdisplay(MCD1, "%d, %d, %d, %d", num1, num2, prod, actual);
                count= count+1;
                for(i=0; i<16; i=i+1)
                begin 
                    if(prod[i] == 1'b1 && actual[i] == 1'b0)
                        freq[i] = freq[i] + 1;
                    else if(prod[i] == 1'b0 && actual[i] == 1'b1)
                        freq[i] = freq[i] + 1;
                end
            end
        end
        $fclose(MCD1);
        for(i=0; i<16; i=i+1)
        begin
            $display("%d", freq[i]);
            #1;
        end
        $display("%d", count);
    end

    initial begin
        #33000;
        $finish;
    end
endmodule

/*
iverilog -o multiplier_pro_tb.vvp multiplier_pro_tb.v
vvp multiplier_pro_tb.vvp
gtkwave
*/
