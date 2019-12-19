module sec_clk(
    input clk,
	 output reg out_clk
);

	reg [24:0] count;

	initial
	begin
		count=24'd0;
		out_clk=1'b0;
	end

	always @(posedge clk) begin
		if(count==24'd1250000)  
			begin
				count <= 24'd0;
				out_clk <= ~out_clk;
			end
		else
			count <= count+1'd1;
	end
	
endmodule 