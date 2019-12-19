module Lattice_ROM(clk, outaddr, dout);  //用寄存器实现的点阵ROM
	input clk; 
	input [11:0] outaddr;
	output reg [11:0] dout;
	
	reg [11:0] rom [4095:0]; 
	
	initial 
	begin
		$readmemh("./mem.txt", rom); 
	end
	
	always @(posedge clk) 
	begin 
		dout<=rom[outaddr];
	end 

endmodule 