module random8(clk,randomNum);
    input clk;
    output reg [7:0] randomNum;
    reg lin;
	 parameter seed = 8'd0;
	 initial begin
			randomNum=seed;
	 end
    always @ (posedge clk) begin
			if(randomNum==8'd0)
              randomNum=8'hff;
         else begin
              lin = randomNum[4]^randomNum[3]^randomNum[2]^randomNum[0];
              randomNum = {lin,randomNum[7:1]};
				  
              if(randomNum==8'hff)
                  randomNum = 8'd0;
              else
                  randomNum = randomNum;
         end        
    end

endmodule 
	