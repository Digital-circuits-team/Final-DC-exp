module hex_decoder(en, in, out);
	input en;
	input [7:0]in;
	output reg [13:0] out;
	reg [6:0] NUM [15:0];
	initial begin
		NUM[0] = 7'b1000000;
		NUM[1] = 7'b1111001;
		NUM[2] = 7'b0100100;
		NUM[3] = 7'b0110000;
		NUM[4] = 7'b0011001;
		NUM[5] = 7'b0010010;
		NUM[6] = 7'b0000010;
		NUM[7] = 7'b1111000;
		NUM[8] = 7'b0000000;
		NUM[9] = 7'b0010000;
		NUM[10] = 7'b0001000;
		NUM[11] = 7'b0000011;
		NUM[12] = 7'b1000110;
		NUM[13] = 7'b0100001;
		NUM[14] = 7'b0000110;
		NUM[15] = 7'b0001110;
	end
	
	always @ (in) begin
		if(en) out = {NUM[in[7:4]], NUM[in[3:0]]};
		else out = 14'b11111111111111;
	end
endmodule 