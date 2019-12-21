module Generator(clk,ch,speed,x,y);
    input clk;
	 output [7:0] ch;
    output [2:0] speed;
	 output [8:0] x;
    output [9:0] y;

	 wire [11:0] ran_y;
	 wire [7:0] ran_ch;
	 wire [7:0] ran_speed;
	 
	 reg [9:0] count;
	 reg [7:0] chcount;
	 reg [7:0] scount;
	 always @ (posedge clk) begin
			if(count>=10'd630)
				count<=10'd0;
			else
				count<=count+10'd9;
				
			if(chcount>=8'd26)
				chcount<=8'd0;
			else
				chcount<=chcount+8'd1;
				
			if(scount>=8'd3)
				scount<=8'd1;
			else
				scount<=8'd1+scount;
	 end
	/* 
	 
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
	
	 */
    //assign y = ran_y%70*9 ;  
   
	 assign x = 9'd0;

	 //assign ch = 8'd65+ran_ch%26;
	 
	 //assign speed = ran_speed%3 + 1;

	 assign y = count;
	 assign ch = 8'd65+chcount;
	 assign speed = scount;
	 
endmodule 