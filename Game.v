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
	parameter lower_bound = 10'd480;
	parameter another_bound = 10'd500;
	parameter white = 24'hFFFFFF;
	parameter black = 24'h000000;
	parameter skyblue = 24'h00CCFF;
	parameter WEL_STATE = 2'd0;
	parameter PLAY_STATE =2'd1;
	parameter END_STATE = 2'd2;
	
	reg [1:0] state; 
	reg score_flag;	
	//out_clk
	wire generator_clk;
	
	//Generator
	wire [7:0]char;
	wire [2:0]tmp_speed;
	wire [8:0]tmp_x;
	wire [9:0]tmp_y;
	
	//lattice_rom
	wire [11:0] rom_outaddr; //读取点阵ROM中该地址
	wire [11:0] color_bit; //从点阵ROM中读取到的9bit信息

	//vga_ctrl
	reg [23:0] vga_data;
	wire [9:0] h_addr;
	wire [9:0] v_addr;
	
	//asc_ram
	wire [9:0] inaddr;  //写入字符显存中的地址
	wire [9:0] outaddr;  //读取字符显存中该地址
	wire [7:0] get_asc; //从字符显存中读取到的ASCII码（8位）
	wire [11:0] get_asc_12bit;
	
	//special display 帧率和分数
	wire [11:0] scolor_bit;	
	wire [7:0] fps_ten,fps_one;
	wire [7:0] score_ten,score_one;
	reg sflag;				//是否处在特殊显示区域
	reg [9:0] sh_offset;//列偏移量
	reg [11:0] sp_addr;
	wire fpsclk;
	
	//FSM
	wire [7:0] press;  //键盘按键
	
	//other
	reg flag;  //辅组判断当前扫描点所获取到的1bit信息是否有效
	reg [9:0] offset[639:0]; //行偏移量
	wire [2:0] speed;  //速度
	wire [2:0] wirte_speed;
	reg [2:0] reg_speed;
	reg [9:0] h_offset;  //字符内列信息，防止溢出故设为10位
	reg [3:0] v_offset;  //字符内行信息
	reg [639:0] columnTable;  //判断某一列是否有字符
	reg [9:0] charIndex;  //当前字符索引
	reg [18:0] countclk;
	reg [5:0] count;
	reg moveable;  //每隔一定周期让字符下滑
	
	reg gameover; //游戏结束标志
	
	reg remove_flag;
	
	reg [7:0] score;//分数
	reg [7:0] fps,fps_reg;//帧率
	//state contrl
	wire [19:0] addr;
	wire [2:0] wel_data;
	wire [2:0] end_data;
	reg pressing;
	reg clk_en;
	//reg reset;
	initial begin
		/*
		reset=1'b0;
		clk_en=1'b0;
		state=2'd0;
		*/
		clk_en=1'b0;
		state=WEL_STATE;
		fps=8'd0;
		pressing=1'b0;
		gameover=1'b0;
		count=6'd0;
		countclk=19'd0;
		moveable=1'b0;
		h_offset=10'd0;
		v_offset=4'd0;
		columnTable=640'b0;
		flag=1'b0;
		remove_flag=1'b0;
	end

	//生成vga_clk
	clkgen #(25000000) my_vgaclk(
		.clkin(CLOCK_50), 
		.rst(1'b0), 
		.clken(1'b1), 
		.clkout(VGA_CLK) 
	);
	
	//用于随机生成字符的时钟
	clkgen #(1) my_generator_clk(
		.clkin(CLOCK_50), 
		.rst(1'b0), 
		.clken(clk_en), 
		.clkout(generator_clk) 
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
	
	asc_speed sp(  //speed显存，写入wirte_speed/读出speed
		.clock(VGA_CLK),
		.data(wirte_speed),
		.rdaddress(outaddr),
		.wraddress(inaddr),
		.wren(generator_clk),
		.q(speed)
	);
	assign wirte_speed=reg_speed;
	
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

	//键盘模块
	FSM keyboard(.clk(CLOCK_50),.ps2_clk(PS2_CLK),.ps2_data(PS2_DAT),.ascii(press));
	
	
	assign inaddr=tmp_y;
	assign outaddr=charIndex; //依据outaddr查询字符RAM
	
	assign get_asc_12bit = get_asc<<4'd4;
	assign rom_outaddr=get_asc_12bit + v_offset;
	
	//生成moveable
	always @ (posedge VGA_CLK) begin 
		countclk=countclk+1'b1;
		if(countclk==19'd420000)begin
			count=count+6'd1;
			countclk=19'd0;
			fps=fps+8'd1;
		end
		if(count==6'd1)begin
			count=6'd0;
			moveable=1'b1;
		end
		else if(countclk==19'd830)begin
			moveable=1'b0;
		end
		
		if(fpsclk)fps=0;
	end
	
	always @ (posedge VGA_CLK) begin   //获取字符内列信息,no problem
		if(columnTable[h_addr] == 1'b1) begin  //当前扫描处有新的字符
			charIndex=h_addr;
			h_offset=10'd0;
		end
		else begin
			charIndex=charIndex;
			h_offset=h_offset+10'd1;  //可能溢出
		end
	end
	
	always @ (posedge VGA_CLK) begin   //获取字符内行信息,no problem
		if(v_addr>=offset[charIndex]&&offset[charIndex]+4'd15>=v_addr) begin   
			v_offset<=(v_addr-offset[charIndex])&10'b0000001111;
			flag<=1'b1;
		end
		else begin	
			v_offset<=4'b0;
			flag<=1'b0;
		end
	end
	
	
	always @ (posedge VGA_CLK) begin  //字符产生及下滑
		if(generator_clk)begin  //生成字符，设置offset和speed
			offset[tmp_y][8:0]<=tmp_x;
			reg_speed<=tmp_speed;
			columnTable[tmp_y]<=1'b1;
		end
		else begin end

		if(state!=PLAY_STATE) begin //不在游戏状态，将所有变量清空
			reg_speed<=3'd0;
			offset[charIndex]<=10'd0;
			columnTable[charIndex]<=1'b0;	
			gameover<=1'b0;
		end
		else if(remove_flag==1'b1&&get_asc==press)begin  //字符消除
				reg_speed<=3'd0;
				offset[charIndex]<=10'd520;
				columnTable[charIndex]<=1'b0;
				remove_flag<=1'b0;
				//计分(已转移至状态机中)
				//score <= score + 8'd1;
			end
			else if(moveable==1'b1&&h_offset==10'd0&&v_addr==10'd0)begin  //该字符没有被消除，继续字符下滑
				offset[charIndex]<=offset[charIndex]+speed;
				if(press==8'h31)begin remove_flag<=1'b1; end  //松开按键，准备消除下一个字符
				if(offset[charIndex]>=lower_bound&&offset[charIndex]<=another_bound) begin
					gameover <= 1'b1;
					//临时擦除字符试验

					/*
					speed[charIndex]<=3'd0;
					reg_speed<=3'd0;
					offset[charIndex]<=10'd520;
					columnTable[charIndex]<=1'b0;
					*/
				end
				else
					gameover<=1'b0;
			end
			else begin offset[charIndex]<=offset[charIndex]; end
	end
	
	always @ (posedge VGA_CLK) begin   //设置vga_data，显示
			//界面状态机
			case(state)
				WEL_STATE: //vga_data <= 24'hff00ff;
					
					vga_data <= wel_data[2]<<23 | wel_data[1] <<15 | wel_data[0] << 7;
				
				PLAY_STATE:     //游戏状态
				begin
					if(sflag==1'b1&&(scolor_bit>>sh_offset)&12'h001 == 1'b1) //显示帧率和分数
						vga_data <= 24'hff00ff;
					else if(flag==1'b1&&(color_bit>>h_offset)&12'h001 == 1'b1) //取出的一位bit信息为1 
						vga_data <= white;  //white
					else if(h_addr>10'd4&&h_addr<10'd476&&v_addr>10'd4&&v_addr<10'd636)//draw frame
						vga_data <= black;
					else 
						vga_data <= skyblue;  					
				end
				END_STATE: //vga_data <= 24'h00ffff; 
			
					vga_data <= end_data[2]<<23 | end_data[1] <<15 | end_data[0] << 7;
			
			endcase
	end
	
	
	assign LEDR[0]=gameover;
	
	
	
	always @ (posedge CLOCK_50) begin //状态转换
		case(state)
			WEL_STATE:begin
			
				if(press==8'd13) begin
					if(pressing)begin
						pressing<=1'b1;
					end
					else begin
						clk_en<=1'b1;
						pressing<=1'b1;
						score<=8'd0;
						state<=PLAY_STATE;//到下一个状态
					end
				end
				else
					pressing<=1'b0;
			end
			PLAY_STATE:begin
				
				if(remove_flag==1'b0)begin //解决由于时序导致的积分问题
					if(score_flag==1'b1) 
						score_flag<=1'b1;
					else begin	
						score<=score+8'd1;
						score_flag<=1'b1;
					end
				end
				else
					score_flag<=1'b0;
				
				
				if(gameover) begin
					clk_en<=1'b0;
					pressing<=1'b1;
					state <= END_STATE;
				end
				
			
			end
			END_STATE:begin
				if(press==8'd13)begin
					if(pressing)begin
						pressing<=1'b1;
					end
					else begin
						pressing<=1'b1;					
						state <= WEL_STATE;
					end
				end
				else
					pressing<=1'b0;
					
			end

		endcase
	end
	
	hex_decoder mystate(1'b1,state,{HEX1,HEX0});
	//计算图片地址
	assign addr = h_addr+v_addr*640;
	
	//欢迎界面
	welROM welcome(addr,VGA_CLK,wel_data);
	
	//结束界面
	endROM gameend(addr,VGA_CLK,end_data);
	
	
	
	//计算帧率
	clkgen #(1) fps_clk(CLOCK_50,1'b0,1'b1,fpsclk);
	
	always @ (posedge fpsclk) 
		fps_reg=fps<<1;
	
	hex_decoder fpshex(1'b1,fps_reg,{HEX5,HEX4});
	
	assign fps_ten = 8'h30+fps_reg/10;
	assign fps_one = 8'h30+fps_reg%10;
	
	assign score_ten = 8'h30+score/10;
	assign score_one = 8'h30+score%10;
	
	
	always @ (posedge VGA_CLK) begin  //分数和帧率显示的地址处理
		
		if(v_addr>=10'd0&&v_addr<10'd16) begin //output fps
			if(h_addr>=10'd620&&h_addr<10'd629) begin //十位
				sp_addr <= (fps_ten<<4)+v_addr;
				sh_offset <= h_addr - 10'd620;
				sflag <= 1'b1;
			end
			else if(h_addr>=10'd630&&h_addr<10'd639) begin //个位
				sp_addr <= (fps_one<<4)+v_addr;
				sh_offset <= h_addr - 10'd630;
				sflag <= 1'b1;
			end
			else
				sflag <= 1'b0;
		end
		else if(v_addr>=10'd17&&v_addr<10'd33) begin //output score
			if(h_addr>=10'd620&&h_addr<10'd629) begin //十位
				sp_addr <= (score_ten<<4)+v_addr-10'd17;
				sh_offset <= h_addr - 10'd620;
				sflag <= 1'b1;
			end
			else if(h_addr>=10'd630&&h_addr<10'd639) begin //个位
				sp_addr <= (score_one<<4)+v_addr-10'd17;
				sh_offset <= h_addr - 10'd630;
				sflag <= 1'b1;
			end
			else
				sflag <= 1'b0;
		end
		else
			sflag <= 1'b0;
			
	end
	assign LEDR[1]=pressing;
	
	Lattice_ROM num_rom(.clk(CLOCK_50), .outaddr(sp_addr), .dout(scolor_bit)); 
	
endmodule 