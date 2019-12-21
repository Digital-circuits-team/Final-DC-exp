module FSM(
		input clk,ps2_clk,ps2_data,
		output reg [7:0] ascii
);
		reg shift,ctrl;
		wire [7:0] asc;  //接收rom输出的ASCII码
		
		reg [7:0] cin;		//记录当前按键
		reg [7:0] first;  //表示先按下的第一个键
		
		reg clrn,nextdata_n;
		wire ready,overflow;
		wire [7:0] data; 
		
		reg [5:0] state;  //状态机的状态
		parameter S0=6'b000001, S1=6'b000010, S2=5'b000100,
					 S3=6'b001000, S4=6'b010000, S5=6'b100000;
		
		ps2_keyboard ps2_keyboard(
				.clk(clk),
				.clrn(clrn),
				.ps2_clk(ps2_clk),
				.ps2_data(ps2_data),
				.data(data),
				.ready(ready),
				.nextdata_n(nextdata_n),
				.overflow(overflow)
		);

		keyboard_rom rom(.address(cin),.clock(clk),.q(asc));
		
		initial begin
			state=S0;
			cin=8'h16;
		end
		//下一个状态
		always @ (posedge clk)begin
			if(overflow)
				clrn=0;
			else clrn=1;
			
			if(ready)begin
				case(state)
					S0:begin  //初始状态，等待按键按下
					if(data!=8'hf0&&data!=8'he0)begin //不为断码以及扩展键盘扫描码
							cin=data;
							if(data==8'h12) shift=1;
							else shift=0;
							if(data==8'h14) ctrl=1;
							else ctrl=0;
							if(shift||ctrl)begin
								first=data;
								state=S3; 
							end
							else state=S1;
						end	
					end
					S1:begin //已经按下按键，等待松开，也可能同时按下了shift和其他键
						if(data==8'hf0) begin //松开按键
							cin=8'h16;
							state=S2;
						end
						else if(data==8'h12||data==8'h14)begin
							state=S4;
						end
					end
					S2:begin
						shift=0;
						ctrl=0;
						state=S0;
					end
					S3:begin
						if(data!=8'he0)begin
							if(data==8'hf0) begin
							state=S2; //松开shift或ctrl键
							first=0;	
							end
							else if(data!=8'h12)begin //按下其他键
								cin=data;
								state=S4;
							end
						end		
					end
					S4:begin
						if(data==8'hf0) begin //松开按键
							state=S5;
						end
					end
					S5:begin
						cin=first;
						if(data==8'h12)begin  //松开了shift
							state=S1;
							shift=0;
						end
						else if(data==8'h12)begin  //松开了ctrl键
							state=S1;
							ctrl=0;
						end
						else begin //松开了其他键
							state=S3;
						end
					end
					
					default: state=S0;
				endcase
				nextdata_n=1;
			end
			else nextdata_n=0;
		end
		
		//输出
		always @ (posedge clk)begin
			if(asc>=8'd97 && asc<=8'd122)
				ascii<=asc-8'h20;  //大写字母
			else ascii<=asc;
		end
		
		
endmodule 