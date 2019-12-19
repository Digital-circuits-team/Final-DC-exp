module Generator(clk,newCh,speed,y);
    input clk;
    output [23:0] newCh;

    output wire [11:0] speed;
	 wire [11:0] ran_y;
	 wire [11:0] div_y;
    output [11:0] y;

    random random_speed(
        .clk(clk),
        .rst(1'b0),
        .seed(12'd315),
        .randomNum(speed)
    );

    random random_y(
        .clk(clk),
        .rst(1'b0),
        .seed(12'd320),
        .randomNum(ran_y)
    );
	
	
	 assign div_y = {6'b000000,{2'b00,ran_y[11:9]}+ran_y[11:7]};
    assign y = ran_y - div_y<<7 - div_y<<9;  //y % 640
   

    assign newCh = {1'b1,speed[3:0],9'd0,y[9:0]};


endmodule