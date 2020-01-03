module Generator(clk,ch,speed,x,y);
    input clk;
	 output [7:0] ch;
    output [2:0] speed;
	 output [8:0] x;
    output [9:0] y;
	
	 wire [11:0] ran_y;
	 wire [7:0] ran_ch;
	 wire [7:0] ran_speed;
	 
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
	
	 
    assign y = 11'hA+(ran_y&11'h3f)*9 ;  
   
	 assign x = 9'd0;
	 
	 assign 8'd65 + ran_ch%26;
	 
	 assign speed = ran_speed%2 + 1;

endmodule 