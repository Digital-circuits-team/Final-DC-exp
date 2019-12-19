module random(clk,rst,seed,randomNum);
    input clk;
    input rst;
    input [11:0] seed;
    output reg [11:0] randomNum;
    reg lin;

    always @ (posedge clk) begin
        if(rst) begin
            randomNum = seed;
        end
        else begin
            if(randomNum==12'd0)
                randomNum=12'hfff;
            else begin
                lin = randomNum[6]^randomNum[4]^randomNum[1]^randomNum[0];
                randomNum = {lin,randomNum[11:1]};
                if(randomNum==12'hfff)
                    randomNum = 12'd0;
                else
                    randomNum = randomNum;
            end
        end
        
    end


endmodule