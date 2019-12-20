/* Top-Level Entity
 *	made by lh and lgt 
 *
 *	Good luck !
 *
 *
 */
module Game(
	//////////// CLOCK //////////
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// Seg7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

	//////////// PS2 //////////
	inout 		          		PS2_CLK,
	inout 		          		PS2_DAT,

	/////////// VGA ///////////
    output							VGA_HS,
    output							VGA_VS,
	 output							VGA_CLK,
    output							VGA_SYNC_N,
	 output							VGA_BLANK_N,
    output 			  [7:0]		VGA_R,
    output 			  [7:0]	   VGA_G,
    output 			  [7:0]		VGA_B
	 


);
	parameter white = 24'hFFFFFF;
	parameter black = 24'h000000;

	parameter WEL_STATE = 2'd0;
	parameter PLAY_STATE =2'd1;
	parameter END_STATE = 2'd2;
	
	reg [1:0] state; 
	
	//out_clk
	wire generator_clk;
	
	//Generator
	wire [7:0]char;
	wire [3:0]tmp_speed;
	wire [8:0]tmp_x;
	wire [9:0]tmp_y;
	
	//lattice_rom
	wire [11:0] rom_outaddr; //读取点阵ROM中该地址
	wire [11:0] color_bit; //从点阵ROM中读取到的9bit信息

	//vga_ctrl
	reg [23:0] vga_data;
	wire [9:0] h_addr,v_addr;


	//wire en;  //字符显存写入使能端
	
	//asc_ram
	wire [9:0] inaddr;  //写入字符显存中的地址
	wire [9:0] outaddr;  //读取字符显存中该地址
	wire [7:0] get_asc; //从字符显存中读取到的ASCII码（8位）
	
	
	//other
	reg [8:0] offset[639:0]; //行偏移量
	reg [3:0] speed[639:0];  //速度
	reg [9:0] h_offset;  //字符内列信息，防止溢出故设为10位
	reg [3:0] v_offset;  //字符内行信息
	//reg [639:0] columnTable;  //判断某一列是否有字符
	reg [11:0] charIndex;  //当前字符索引
	wire colInfo;//标志当前列是否存在字符
	
	wire moveable;  //每隔一定周期让字符下滑
	
	
	//初始化
	initial begin
		state = WEL_STATE;
		
	
	end
	
	
	//生成vga_clk
	clkgen #(25000000) my_vgaclk(
		.clkin(CLOCK_50), 
		.rst(SW[0]), 
		.clken(1'b1), 
		.clkout(VGA_CLK) 
	);
	//用于随机生成字符的时钟
	clkgen #(2) my_generator_clk(
		.clkin(CLOCK_50), 
		.rst(SW[0]), 
		.clken(1'b1), 
		.clkout(generator_clk) 
	);
	//生成moveable
	clkgen #(2000000) my_moveable_clk(
		.clkin(CLOCK_50), 
		.rst(SW[0]), 
		.clken(1'b1), 
		.clkout(moveable) 
	);
	
	
	//随机生成字符
	Generator gen(.clk(generator_clk),.ch(char),.speed(tmp_speed),.x(tmp_x),.y(tmp_y));

	//点阵ROM，取出字模信息color_bit
	Lattice_ROM lat_rom(.clk(CLOCK_50), .outaddr(rom_outaddr), .dout(color_bit)); 
	
	ascii_ram ram(  //字符显存，写入char/读出get_asc
		.data(char),
		.rdaddress(outaddr),
		.rdclock(VGA_CLK),
		.wraddress(inaddr),
		.wrclock(generator_clk),
		.wren(1'b1),
		.q(get_asc)
		); 

	columnTable mycols(
		.data(1'b1),
		.rdaddress(h_addr),
		.rdclock(VGA_CLK),
		.wraddress(tmp_y),
		.wrclock(generator_clk), //future bug:这里将可能出现冲突：当键盘消除字符时要对columnTable进行修改。需要对写时钟和写使能进行调整
		.wren(1'b1),
		.q(colInfo)
	);	
	
	vga_ctrl my_vga_ctrl( 
		.pclk(VGA_CLK), //25MHz时钟 
		.reset(SW[1]), //置位 
		.vga_data(vga_data), //上层模块提供的VGA颜色数据 
		.h_addr(h_addr), //提供给上层模块的当前扫描像素点坐标 
		.v_addr(v_addr), 
		.hsync(VGA_HS), //行同步和列同步信号 
		.vsync(VGA_VS), 
		.valid(VGA_BLANK_N), //消隐信号 
		.vga_r(VGA_R), //红绿蓝颜色信号 
		.vga_g(VGA_G), 
		.vga_b(VGA_B) 
	); 
	assign VGA_SYNC_N = 0;

	assign inaddr=tmp_y;
	assign outaddr=charIndex; //依据outaddr查询字符RAM
	
	assign rom_outaddr=get_asc<<4'd4+v_offset;
	
	always @ (posedge VGA_CLK) begin   //获取字符内列信息
		if(colInfo) begin  //当前扫描处有新的字符
			charIndex<=h_addr;
			h_offset<=4'b0;
		end
		else begin
			charIndex<=charIndex;
			h_offset<=h_offset+10'd1;  //可能溢出
		end
	end
	
	always @ (posedge VGA_CLK) begin   //获取字符内行信息
		if(v_addr>=offset[charIndex]&&offset[charIndex]+4'd15>=v_addr) begin   
			v_offset<=v_addr-offset[charIndex];
		end
		else begin	
			v_offset<=4'b0;
		end
	end
	
	
	always @ (posedge moveable or posedge generator_clk) begin  //字符下滑
		if(generator_clk)begin  //生成字符，设置offset和speed；TODO:可能会覆盖，待修改
			offset[tmp_y][8:0]<=tmp_x;
			speed[tmp_y][3:0]<=tmp_speed;
			//columnTable[tmp_y]=1'b1;
			if(h_offset==4'b0&&v_addr==offset[charIndex])begin
				offset[charIndex]<=offset[charIndex]+speed[charIndex];
			end
			else begin
				offset[charIndex]<=offset[charIndex];
			end
		end
		else begin 
			if(h_offset==4'b0&&v_addr==offset[charIndex])begin
				offset[charIndex]<=offset[charIndex]+speed[charIndex];
			end
			else begin
				offset[charIndex]<=offset[charIndex];
			end
		end
	end
	
	
	always @ (posedge VGA_CLK) begin   //设置vga_data，显示
			/*界面状态机
			case(state)
				WEL_STATE: data <= ;
				PLAY_STATE:     //游戏状态
				begin
					if((color_bit>>h_offset)&12'h001 == 1'b1) //取出的一位bit信息为1 
						vga_data = white;  //white
					else 
						vga_data = black;  //black				
				end
				END_STATE: data <= ;
			endcase
			*/
			
			if((color_bit>>h_offset)&12'h001 == 1'b1) //取出的一位bit信息为1 
				vga_data = white;  //white
			else 
				vga_data = black;  //black			

	end
	
	always @ (posedge KEY[0]) begin //状态转换
		if(state==END_STATE)
			state <= WEL_STATE;
		else
			state <= state + 2'd1;		
	end
	
	

endmodule 