module Generator(clk,ch,speed,x,y,out_enable);
    input clk;
	 output out_enable;
	 output [7:0] ch;
    output [3:0] speed;
	 output [8:0] x;
    output [9:0] y;

	 wire [11:0] ran_y;
	 wire [7:0] ran_ch;
	 wire [3:0] ran_speed;
	 
    random8 #(2) random_speed(
        .clk(clk),
        .randomNum(ran_speed)
    );

    random12 #(315) random_y(
        .clk(clk),
        .randomNum(ran_y)
    );
	 
	 random8 #(9) random_ch(
			.clk(clk),
			.randomNum(ran_ch)
	 );
	
	 assign out_enable = clk;
	 
    assign y = ran_y%640;  
   
	 assign x = 9'd0;

	 assign ch = 8'd97+ran_ch%26;
	 
	 assign speed = ran_speed == 0 ? 4'd1:ran_speed;

endmodule 