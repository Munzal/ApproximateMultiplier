
module HA(
    output Sum,
    output Carry,
    input A,
    input B
);
    assign Sum = A&(~B) | (~A)&B;
    assign Carry = A & B;
endmodule

module FA(
    output Sum,
    output Carry,
    input A,
    input B,
    input C
);
    wire I;
    assign I = (~A)&B | A&(~B);
    assign Sum = (~I)&C | I&(~C);
    assign Carry = A&B | C&I;

endmodule

module comp4x2(
    output sum_out,
    output carry,
    input x1,
    input x2,
    input x3,
    input x4
);
    wire w1, w2;
    wire [1:0] op;

    assign w1 = x1 | x2;
    assign w2 = x3 | x4;

    assign op[1] = w1 & w2;
    assign op[0] = w1 | w2;

    assign carry = op[1];
    assign sum_out = op[0];

endmodule

module multiplier(
    output [15:0] w,
    input [7:0] num1,
    input [7:0] num2
);
    wire a[7:0][7:0];
    genvar i,j;

    //level 1
    generate
        for(i=0; i<8; i=i+1)
        begin
            for(j=0; j<8; j=j+1)
            begin
                assign a[i][j] = num1[i] & num2[j];
            end
        end
    endgenerate
    //level 2
    
    wire p[7:0][7:0];
    wire g[7:0][7:0];
    assign p[2][1] = a[2][1] | a[1][2];
    assign g[2][1] = a[2][1] & a[1][2];
    generate
        for(i=3; i<7; i=i+1)
        begin
            for(j=0; j<i; j=j+1)
            begin
                assign p[i][j] = a[i][j] | a[j][i];
                assign g[i][j] = a[i][j] & a[j][i];
            end
        end
    endgenerate
    generate
        for(j=0;j<5;j=j+1)
        begin
            assign p[7][j] = a[7][j] | a[j][7];
            assign g[7][j] = a[7][j] & a[j][7];
        end
    endgenerate
    
    //level 3
    wire r1[10:0], r2[10:0], r3[10:0];

    assign r1[0] = p[3][0];
    assign r2[0] = p[2][1];

    HA          h1(r1[1], r3[2], p[4][0], p[3][1]);
    FA          f1(r1[2], r3[3], p[5][0], p[4][1], p[3][2]);
    comp4x2  c1(r1[3], r3[4], p[6][0], p[5][1], p[4][2], a[3][3]);
    comp4x2  c2(r1[4], r3[5], p[7][0], p[6][1], p[5][2], p[4][3]);
    comp4x2  c3(r1[5], r3[6], p[7][1], p[6][2], p[5][3], a[4][4]);
    FA          f2(r1[6], r3[7], p[7][2], p[6][3], p[5][4]);
    FA          f3(r1[7], r3[8], p[7][3], p[6][4], a[5][5]);
    HA          h2(r1[8], r2[9], p[7][4], p[6][5]);
    HA          h3(r1[9], r3[10],a[7][5], a[5][7]);

    assign r1[10] = a[7][6];
    assign r2[10] = a[6][7];
    assign r3[9] = a[6][6];
    assign r3[0] = g[3][0] | g[2][1];
    assign r3[1] = g[4][0] | g[3][1];

    assign r2[1] = a[2][2];
    assign r2[2] = g[5][0] | g[4][1] | g[3][2];
    assign r2[3] = g[6][0] | g[5][1] | g[4][2];
    assign r2[4] = g[7][0] | g[6][1] | g[5][2] | g[4][3];
    assign r2[5] = g[7][1] | g[6][2] | g[5][3];
    assign r2[6] = g[7][2] | g[6][3] | g[5][4];
    assign r2[7] = g[7][3] | g[6][4];
    assign r2[8] = g[7][4] | g[6][5];
    assign r2[10] = a[6][7];

    //level 4
    //wire w[14:0];
    wire last_level[0:11];
    assign w[0] = a[0][0];
    assign w[1] = a[1][0] | a[0][1];//instead of Approx half adder we use OR gate
    
    comp4x2       fn1(w[2], last_level[0], a[2][0], a[0][2], a[1][1], 1'b0);
    comp4x2       fn2(w[3], last_level[1], r1[0], r2[0], r3[0], last_level[0]);
    comp4x2       fn3(w[4], last_level[2], r1[1], r2[1], r3[1], last_level[1]);
    comp4x2       fn4(w[5], last_level[3], r1[2], r2[2], r3[2], last_level[2]);
    comp4x2       fn5(w[6], last_level[4], r1[3], r2[3], r3[3], last_level[3]);
    comp4x2       fn6(w[7], last_level[5], r1[4], r2[4], r3[4], last_level[4]);
    comp4x2       fn7(w[8], last_level[6], r1[5], r2[5], r3[5], last_level[5]);
    comp4x2       fn8(w[9], last_level[7], r1[6], r2[6], r3[6], last_level[6]);
    comp4x2       fn9(w[10], last_level[8], r1[7], r2[7], r3[7], last_level[7]);
    comp4x2       fn10(w[11], last_level[9], r1[8], r2[8], r3[8], last_level[8]);
    comp4x2       fn11(w[12], last_level[10], r1[9], r2[9], r3[9], last_level[9]);
    comp4x2       fn12(w[13], last_level[11], r1[10], r2[10], r3[10], last_level[10]);
    
    assign w[14] = a[7][7];
    assign w[15] = 1'b0;

endmodule

module image_blender_multiplier (
    input clk,
    input rst,
    input [7:0] data_in,
    input ratio_in,
    output [15:0] data_out
);

    reg [7:0] pixel;
    reg [7:0] ratio;
    wire [15:0] data_out;

    multiplier m1(data_out, pixel, ratio);

    always@(posedge clk or negedge rst)
    begin
        if(~rst)
        begin
            pixel <= 0;
            ratio <= 0;
        end
        else
        begin
            if (ratio_in == 1'b1)
            begin
                ratio <= data_in;
                pixel <= 0;
            end
            else
            begin
                pixel <= data_in;    
                ratio <= ratio;
            end
        end
    end

endmodule

module image_blender (
    input [17:0] single_input,
    input clk,
    input rst, 
    output [7:0] data_out
);
    reg [2:0] divider_reg;
    reg [7:0] ib1_data_in;
    reg [7:0] ib2_data_in;
    reg ratio_in;
    wire [15:0] ib1_data_out;
    wire [15:0] ib2_data_out;
    reg [15:0] adder_output;
    reg [7:0] data_out;
    wire [7:0] data_in_1;
    wire [7:0] data_in_2;
    wire [1:0] state; // ratio as input, divider num as input, pixel value as input


    assign {state, data_in_1, data_in_2} =  single_input;

    image_blender_multiplier ib1(clk, rst, ib1_data_in, ratio_in, ib1_data_out);
    image_blender_multiplier ib2(clk, rst, ib2_data_in, ratio_in, ib2_data_out);

    always@(posedge clk or negedge rst)
    begin
        if (~rst)
        begin
            divider_reg <= 0;
            ib1_data_in <= 0;
            ib2_data_in <= 0;
            ratio_in <= 0;
        end
        else if (state == 2'b01) //load divisor value
        begin
            divider_reg <= data_in_1[2:0];
            ib1_data_in <= 0;
            ib2_data_in <= 0;
            ratio_in <= 0;
        end
        else if (state == 2'b10) // load ratio value
        begin
            ratio_in <= 1'b1;
            ib1_data_in <= data_in_1;
            ib2_data_in <= data_in_2;
        end
        else if (state == 2'b00) // load pixel values
        begin
            ratio_in <= 1'b0;
            ib1_data_in <= data_in_1;
            ib2_data_in <= data_in_2;
        end
    end

    always@(posedge clk or negedge rst)
    begin
        if(~rst)
            adder_output <= 0;
        else
            adder_output <= ib1_data_out + ib2_data_out;
    end

    always@(*)
    begin
        begin
            case (divider_reg)
                3'b000: begin data_out = adder_output[8:1]; end
                3'b001: begin data_out = adder_output[9:2]; end
                3'b010: begin data_out = adder_output[10:3]; end
                3'b011: begin data_out = adder_output[11:4]; end
                3'b100: begin data_out = adder_output[12:5]; end
                3'b101: begin data_out = adder_output[13:6]; end
                3'b110: begin data_out = adder_output[14:7]; end
                3'b111: begin data_out = adder_output[15:8]; end
            endcase
        end
    end

endmodule