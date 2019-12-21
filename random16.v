module random16(clk,randomNum);
    input clk;
    output reg [15:0] randomNum;
    reg lin;
	 parameter seed = 16'd0;
	 initial begin
			randomNum=seed;
	 end
    always @ (posedge clk) begin
			if(randomNum==16'd0)
              randomNum=16'hffff;
         else begin
              lin = randomNum[5]^randomNum[4]^randomNum[3]^randomNum[0];
              randomNum = {lin,randomNum[15:1]};
				  
              if(randomNum==16'hfff)
                  randomNum = 16'd0;
              else
                  randomNum = randomNum;
         end        
    end

endmodule 