module(clk,newCh);
    input clk;
    output [23:0] newCh;

    reg [11:0] speed,y;

    random random_speed(
        .clk(clk),
        .rst(1'b0),
        .seed(12'd315),
        .randomNum(speed)
    );

    always @

    assign newCh = {1'b1,speed,9'd0,y};


endmodule