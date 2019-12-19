module Generator(clk,ch,speed,x,y);
    input clk;
	 
	 output [7:0] ch;
    output [3:0] speed;
	 output [8:0] x;
    output [9:0] y;

	 wire [11:0] ran_y;
	 wire [11:0] div_y;
	 
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
	 
	 random random_ch(
			.clk(clk).
			.rst(1'b0),
			.seed(12'd0),
			.randomNum({4'b0000,ch})
	 );
	
	 
	 assign div_y = {6'b000000,{2'b00,ran_y[11:9]}+ran_y[11:7]};
    assign y = ran_y - div_y<<7 - div_y<<9;  //y % 640
   
	 assign x = 9'd0;



endmodule