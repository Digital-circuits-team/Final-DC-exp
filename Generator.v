module Generator(clk,ch,speed,x,y);
    input clk;

	 output [7:0] ch;
    output [3:0] speed;
	 output [8:0] x;
    output [9:0] y;

	 wire [11:0] ran_y;
	 wire [7:0] ran_ch;
	 
    random8 random_speed(
        .clk(clk),
        .randomNum(speed)
    );

    random12 random_y(
        .clk(clk),
        .randomNum(ran_y)
    );
	 
	 random8 random_ch(
			.clk(clk),
			.randomNum(ran_ch)
	 );
	
	 
    assign y = ran_y%640;  
   
	 assign x = 9'd0;

	 assign ch = 8'd97+ran_ch%26;

endmodule 