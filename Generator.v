module Generator(clk,ch,speed,x,y);
    input clk;
	 output [7:0] ch;
    output [2:0] speed;
	 output [8:0] x;
    output [9:0] y;

	 wire [11:0] ran_y,y_in_70;
	 
	 wire [7:0] ran_ch,ch_in_26;
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
	
    assign y_in_70 = ran_y&10'h3f+{8'd0,ran_y[7:6]}+{8'd0,ran_y[9:8]};  
	 assign y = y_in_70+y_in_70<<3;
   
	 assign x = 9'd0;

	 //assign ch_in_26 = ran_ch&8'hf+{5'd0,ran_ch[6:4]}+{6'd0,ran_ch[8:7]};
	 assign ch = 8'd65+ran_ch%26;
	 
	 assign speed = ran_speed>>2 + 1;

endmodule 