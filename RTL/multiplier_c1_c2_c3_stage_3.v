module HA(
    output [1:0] op,
    input [1:0] inp
);
    wire Sum, Carry;
    wire A, B;
    assign A = inp[0];
    assign B = inp[1];
    assign Sum = A&(~B) | (~A)&B;
    assign Carry = A & B;
    assign op = {Carry,Sum};
endmodule

module FA(
    output [1:0] op,
    input [2:0] inp
);
    wire I;
    wire Sum, Carry;
    wire A, B, C;
    assign A = inp[0];
    assign B = inp[1];
    assign C = inp[2];
    assign I = (~A)&B | A&(~B);
    assign Sum = (~I)&C | I&(~C);
    assign Carry = A&B | C&I;
    assign op = {Carry,Sum};
endmodule

module comp4x2(
    output [1:0] op,
    input [3:0] inp
);
    wire w1, w2;

    assign w1 = inp[0] | inp[1];
    assign w2 = inp[2] | inp[3];

    assign op[1] = w1 & w2;
    assign op[0] = w1 | w2;

endmodule

module comp6x3(
    output [2:0] op,
    input [5:0] inp
);
    wire w1, w2, w3, w4, w5, w6;
    wire a1, a2, a3, a4, a5, a6, a7;

    assign w1 = inp[0] | inp[1] | inp[2];
    assign w2 = inp[3] & inp[4] & inp[5];
    assign w3 = inp[0] & inp[1] & inp[2];
    assign w4 = inp[3] | inp[4] | inp[5];

    assign w5 = w1 & w2;
    assign w6 = w3 & w4;

    assign op[2] = w5 | w6; //msb
    assign op[0] = op[2]; //lsb

    //mid bit
    assign a1 = inp[0] | inp[1];
    assign a2 = inp[2] | inp[3];
    assign a3 = inp[4] | inp[5];

    assign a4 = a1 & a2;
    assign a5 = a2 & a3;
    assign a6 = a3 & a1;

    assign a7 = a4 | a5 | a6;

    assign op[1] = a7 & (~op[2]);//mid bit 

endmodule

module comp8x3(
    output [2:0] op,
    input [7:0] inp
);
    wire w1, w2, w3, w4, w5;

    comp4x2 c1({w2,w1},{inp[0],inp[1],inp[2],inp[3]});
    comp4x2 c2({w4,w3},{inp[4],inp[5],inp[6],inp[7]});
    HA      h1({w5,op[0]},{w3,w1});
    FA      f1({op[2],op[1]},{w1,w2,w5});

endmodule

module multiplier_nov(
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

    wire [2:0] level2 [0:14];// considering 3 bit output for all modules in level 1

    HA          hor01(level2[0][1:0],{a[1][0], a[0][1]});
    FA          hor02(level2[1][1:0],{a[0][2],a[2][0], a[1][1]});
    comp4x2     hor03(level2[2][1:0],{a[3][0], a[1][2], a[2][1], a[0][3]});
    comp6x3     hor04(level2[3][2:0],{a[4][0], a[1][3], a[3][1], a[0][4], a[2][2],1'b0});
    comp6x3     hor05(level2[4][2:0],{a[5][0], a[0][5], a[1][4], a[4][1], a[3][2], a[2][3]});
    comp8x3     hor06(level2[5][2:0],{a[6][0], a[0][6], a[1][5], a[5][1], a[2][4], a[4][2], a[3][3],1'b0});
    comp8x3     hor07(level2[6][2:0],{a[7][0], a[0][7], a[1][6], a[6][1], a[2][5], a[5][2], a[4][3], a[3][4]});
    comp8x3     hor08(level2[7][2:0],{a[7][1], a[1][7], a[2][6], a[6][2], a[5][3], a[3][5], a[4][4],1'b0});
    comp6x3     hor09(level2[8][2:0],{a[7][2], a[2][7], a[3][6], a[6][3], a[5][4], a[4][5]});
    comp6x3     hor10(level2[9][2:0],{a[7][3], a[3][7], a[4][6], a[6][4], a[5][5],1'b0});
    comp4x2     hor11(level2[10][1:0],{a[7][4], a[4][7], a[5][6], a[6][5]});
    FA          hor12(level2[11][1:0],{a[7][5], a[5][7], a[6][6]});
    HA          hor13(level2[12][1:0],{a[7][6], a[6][7]});

    assign level2[13][0] = a[7][7];

    wire level3_carry [0:12];
    wire [13:0] prod;

    HA          hrr01({level3_carry[0], prod[0]}, {level2[0][1], level2[1][0]});
    comp4x2     hrr02({level3_carry[1], prod[1]}, {level3_carry[0], level2[1][1], level2[2][0], 1'b0});
    comp4x2     hrr03({level3_carry[2], prod[2]}, {level3_carry[1], level2[2][1], level2[3][0], 1'b0});
    comp4x2     hrr04({level3_carry[3], prod[3]}, {level3_carry[2], level2[3][1], level2[4][0], 1'b0});
    comp4x2     hrr05({level3_carry[4], prod[4]}, {1'b0, level2[4][1], level2[5][0], 1'b0});
    comp4x2     hrr06({level3_carry[5], prod[5]}, {level3_carry[4], level2[5][1], level2[6][0], 1'b0});
    comp4x2     hrr07({level3_carry[6], prod[6]}, {level3_carry[5], level2[6][1], level2[7][0], 1'b0});
    comp4x2     hrr08({level3_carry[7], prod[7]}, {1'b0, level2[7][1], level2[8][0], 1'b0});
    comp4x2     hrr09({level3_carry[8], prod[8]}, {level3_carry[7], level2[8][1], level2[9][0], 1'b0});
    comp4x2     hrr10({level3_carry[9], prod[9]}, {level3_carry[8], level2[9][1], level2[10][0], 1'b0});
    comp4x2     hrr11({level3_carry[10], prod[10]}, {1'b0, level2[10][1], level2[11][0], 1'b0});
    comp4x2     hrr12({level3_carry[11], prod[11]}, {level3_carry[10], level2[11][1], level2[12][0], 1'b0});
    comp4x2     hrr13({level3_carry[12], prod[12]}, {level3_carry[11], level2[12][1], level2[13][0], 1'b0});

    assign prod[13] = level3_carry[12];
    assign w = {prod,level2[0][0],a[0][0]};
    
endmodule