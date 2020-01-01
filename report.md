# 数电实验报告



---

## 实验十二				复刻打字游戏







​												**计算机科学与技术系     **



​												**181860055 		[刘国涛](https://github.com/youngstudent2)**  

​												**181860044		 [李翰](https://github.com/Eternity-AIBN)** 



​									

​				**项目地址：**[Github](https://github.com/Digital-circuits-team/Final-DC-exp)



​									

​		





**2019年12月22日**					









------





## 目录







[TOC]













---











### 1.实验目的

本次实验为自选大实验，主要目的是在一个较大的项目综合运用本学期所学内容，加深对知识的理解，并在一定程度上锻炼对一个大项目的分析、拆解及整合能力。



### 2.知识背景

此次实验（打字游戏）涉及的知识背景主要是VGA字符显示（主要对应于实验9，实验11）以及程序与键盘的交互（主要对应于实验8）。

<span style='color:red;background:white;font-size:16;font-family:字体;'>TODO：随机数生成相关内容</span>



### 3.实验环境/器材等

环境：Quartus 17.1 Lite，Windows 10

器材：DE10 Standard开发平台





### 4.设计思路、流程图

为了实现目标功能，在前期提出以下问题：

>- 如何生成字符
>    - 需要生成那些信息
>    - 生成后的信息如何存储
>    - 如何实现随机生成
>- 如何实现字符的平滑下落
>    - 采用什么样的显存
>    - 如何实现字符的下落
>    - 如何实现字符的平滑下落
>    - 如何针对不同速度的字符实现平滑下落
>- 如何通过键盘删除对应字符
>    - 如何快速地找到显存中对应的字符
>    - 通过什么方式删除
>- FPS和分数如何计算并显示
>
>

##### 1.阶段划分

根据提出的问题，我们将实验划分为以下四个阶段：

 ```mermaid
graph LR
 	p1(随机产生字符)
 	p2(字符平滑下落)
 	p3(键盘消除字符)
 	p4(实现FPS和分数的显示)
 	p5("实现界面状态机(附加功能)")
 	p1-->p2
 	p2-->p3
 	p3-->p4
 	p4-->p5
 ```

##### 2.数据结构

**`Generator`产生的字符信息：**

一个字符表项共30位，各位区段对应含义如下

| [29:22] | [21:19] | [18:10] | [9:0] |
| :-----: | :-----: | :-----: | :---: |
|   ch    |  speed  |    x    |   y   |

**用于存储生成的字符、实现字符下滑、实现键盘消除的结构：**

```c++
typedef struct{
    bool ex;//使用寄存器实现，标志该列是否存在字符
    char ch;//使用RAM实现，记录对应列存在的字符ASCII码
    int offset;//使用寄存器实现，记录当前列的行偏移
    int speed;//使用RAM实现，记录当前列存在的字符的速度
}ColumnInfo;

typedef struct{
	ColumnInfo col[640];    
}ColumnTable;
```



##### 3.各阶段大致思路

###### 随机产生字符

通过`Generator`模块随机生成如下字符信息： <span style='color:purple;background:white;font-size:16;font-family:字体;'>字符对应的ASCII码、速度及横纵坐标</span> 

`Generator`通过调用LSFR实现的随机序列发生器模块`random`，为四个属性生成以下范围的随机数：

|  属性  | 随机数范围 |
| :----: | :--------: |
| ASCII  |  ‘A’-‘Z’   |
| speed  |   (1,3)    |
| 列坐标 |  [0,640)   |
| 行坐标 |   恒为0    |

###### 字符平滑下落

在具体设计中采用一个由 ```640个8bit reg型变量```组成的数组 <span style='color:purple;background:white;font-size:16;font-family:字体;'>offset</span> 来储存某一个字符的坐标（如offset[a]则表示横坐标为a的字符的纵坐标是多少，此处约定不会有两个字符的横坐标相同）。同时相应的用另一个由 ```640个3bit reg型变量```组成的数组 <span style='color:purple;background:white;font-size:16;font-family:字体;'>speed</span> 来储存某一个字符的速度(约定速度范围是 <span style='color:blue;background:white;font-size:16;font-family:字体;'>1~7</span> )，如此即可通过 <span style='color:purple;background:white;font-size:16;font-family:字体;'>offset[a]=offset[a]+speed[a]</span> 更新某一字符的纵坐标以实现字符下滑效果。

###### 键盘消除字符

当键盘按下按键时，在屏幕上找到相应字符，可以通过如下设置：

```verilog
offset[a]=8'd520;
speed[a]=3'd0;
```

即将字符纵坐标设为一个大于显示器高度的值，同时速度设为 0 ，如此字符便不会在屏幕上出现，同时也不会由于一直加上 <span style='color:purple;background:white;font-size:16;font-family:字体;'>speed[a]</span> 而导致 <span style='color:purple;background:white;font-size:16;font-family:字体;'>offset[a]</span> 溢出变为0而重新出现在屏幕中。当该位置产生新的字符时，只需根据`Generator`模块提供的信息设置即可。



##### 4.模块化设计

此次实验主要分为`7`个模块，分别是**通用时钟生成模块clkgen**，**VGA控制器模块**，**键盘控制器模块FSM**，**字符字模点阵Lattice_ROM模块**，**字符速度显存asc_speed模块**，**随机数生成Generator模块**，以及**顶层实体Game模块**。

<span style='color:red;background:white;font-size:16;font-family:字体;'>TODO：模块之间的组织和联系（流程图？）</span>





##### 5.相关变量

此次实验中除了时钟信号、与 VGA 和键盘相关的一些输入输出变量之外，在顶层实体中对于每个模块以及几个always块还需另外定义一些变量，大致如下：

对于```Generator```模块，需要给其提供一个时钟信号，以及几个wire型变量用于接收随机生成的信息，相关变量定义如下：

```verilog
wire generator_clk;  //随机生成字符的时钟信号
wire [7:0]char;  //字符ASCII码
wire [2:0]tmp_speed;  //速度
wire [8:0]tmp_x;  //横坐标 
wire [9:0]tmp_y;  //纵坐标
```

对于```Lattice_ROM```模块，需要定义一个 12bits 的wire型变量用于表示读取地址，以及一个 12bits 的wire型变量用于储存从点阵ROM中读取到的 9bits 信息，相关变量定义如下：

```verilog
wire [11:0] rom_outaddr; //读取点阵ROM中该地址
wire [11:0] color_bit; //从点阵ROM中读取到的9bit信息
```

对于```vga_ctrl```模块，需要定义一个 24bits 的reg型变量用于表示上层提供的vga_data，以及两个 10bits 的wire型变量用于表示当前扫描点的横纵坐标，相关变量定义如下：

```verilog
reg [23:0] vga_data;
wire [9:0] h_addr;
wire [9:0] v_addr;
```

对于```asc_ram```模块，需要定义两个 10bits 的wire型变量分别表示显存的写入和读出地址，以及一个8bits的wire型变量用于表示从字符显存中读取到的ASCII码，此外，由于读取到的ASCII码在后续操作中需要进行左移运算，为防止其发生溢出，需额外定义一个12bits的变量来储存左移结果，相关变量定义如下：

```verilog
wire [9:0] inaddr;  //写入字符显存中的地址
wire [9:0] outaddr;  //读取字符显存中该地址
wire [7:0] get_asc; //从字符显存中读取到的ASCII码（8位）
wire [11:0] get_asc_12bit;
```

<span style='color:red;background:white;font-size:16;font-family:字体;'>TODO：special display模块</span>

```FSM```模块则需要定义一个8bits的变量用于表示键盘按键对应的ASCII码，定义如下：

```verilog
wire [7:0] press;
```

除此之外，还需要一些其他的变量，分别如下：

```verilog
reg flag;  //辅组判断当前扫描点所获取到的1bit信息是否有效
reg [9:0] offset[639:0]; //行偏移量
wire [2:0] speed;  //速度
wire [2:0] wirte_speed;  
reg [2:0] reg_speed; 
reg [9:0] h_offset;  //字符内列信息，防止溢出故设为10位
reg [3:0] v_offset;  //字符内行信息
reg [639:0] columnTable;  //判断某一列是否有字符
reg [9:0] charIndex;  //当前字符索引
reg [18:0] countclk;  //用于计数,辅组产生字符下滑信号
reg [5:0] count;   //用于计数,辅组产生字符下滑信号
reg moveable;  //字符下滑信号,每隔一定周期让字符下滑
	
reg gameover; //游戏结束标志
	
reg remove_flag;  //字符消除标志

reg [7:0] score;//分数
reg [7:0] fps,fps_reg;//帧率

//state contrl
wire [19:0] addr;
wire [2:0] wel_data;
wire [2:0] end_data;
reg clk_en;
reg reset;
reg pressing;
wire flash_flag;
```

<span style='color:red;background:white;font-size:16;font-family:字体;'>TODO：上述state contrl相关变量解释</span>



### 5.实验步骤/过程

##### 1.用IP核生成字符显存RAM

生成mif文件(初始化为全0)：

![1573088020371](reportIMG/1573088020371.png)

![1574493932592](reportIMG/1574493932592.png)

生成双口RAM:

![image-20191231150300360](reportIMG/image-20191231150300360.png)

##### 2.用IP核生成速度显存RAM

生成mif文件(初始化为全0)：

![image-20191231150118757](reportIMG/image-20191231150118757.png)

![1574493932592](reportIMG/1574493932592.png)

生成双口RAM:

![image-20191231150318951](reportIMG/image-20191231150318951.png)

##### 3.设计字模点阵ROM:

![image-20191231145737617](reportIMG/image-20191231145737617.png)

##### 4.导入通用时钟生成模块，VGA控制模块

![image-20191231145842405](reportIMG/image-20191231145842405.png)

![image-20191231145854962](reportIMG/image-20191231145854962.png)

##### 5.设计随机生成模块

`Generator`调用LSFR实现的八位和十二位随机数生成器生成随机数，`Generator`模块实现如下：

```verilog
module Generator(clk,ch,speed,x,y);
     input clk;
	 output [7:0] ch;
     output [2:0] speed;
	 output [8:0] x;
     output [9:0] y;
	
	 wire [11:0] ran_y;
	 wire [7:0] ran_ch;
	 wire [7:0] ran_speed;
	 
	 wire fake;
	 
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
	
	//生成属性值
    assign y = 11'hA+(ran_y&11'h3f)*9;
	assign x = 9'd0;
	assign ch = 8'd65 + ran_ch%26;
	assign speed = ran_speed%2 + 1;
endmodule 
```

随机数生成器（八位）实现如下：

```verilog
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
```

##### 6.初步设计顶层实体Game模块

###### 首先进行一些模块的实例化:

```verilog
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
```

###### 然后设计多个always块实现主体功能:

首先需要一个always块来产生字符下滑信号，即让屏幕上的字符每隔一定周期下滑，本次实验中仿造clkgen模块的设计，通过对一个固定周期变化的变量进行计数来生成所需信号，大致设计如下：

```verilog
always @ (posedge VGA_CLK) begin 
	countclk=countclk+1'b1;
	if(countclk==19'd420000)begin
		count=count+6'd1;
		countclk=19'd0;
	end
	if(count==6'd1)begin
		count=6'd0;
		moveable=1'b1;
	end
	else if(countclk==19'd830)begin
		moveable=1'b0;
	end
end
```

然后需要两个always块分别获取当前扫描处对应字符的字符内列信息和行信息，设计如下:

```verilog
always @ (posedge VGA_CLK) begin   //获取字符内列信息
	if(columnTable[h_addr] == 1'b1) begin  //当前扫描处有新的字符
		charIndex=h_addr;   //将字符索引改为当前扫描处
		h_offset=10'd0;     //初次扫描到该字符,将字符内行信息置为0
	end
	else begin
		charIndex=charIndex;   
		h_offset=h_offset+10'd1;  //将字符内行信息依次增加
	end
end
	
always @ (posedge VGA_CLK) begin   //获取字符内行信息
	if(v_addr>=offset[charIndex]&&offset[charIndex]+4'd15>=v_addr) begin 
        //当前扫描处有字符,则字符内列信息计算如下,并将flag标志置1
		v_offset<=(v_addr-offset[charIndex])&10'b0000001111;
		flag<=1'b1;
	end
	else begin	//当前扫描处没有字符,则将flag标志置0
		v_offset<=4'b0;
		flag<=1'b0;
	end
end
```

接着需要用一个always块来处理字符的产生及下滑:

字符产生：

```verilog
if(generator_clk)begin  //生成字符，设置offset和speed
	offset[tmp_y][8:0]<=tmp_x;
	reg_speed<=tmp_speed;
	columnTable[tmp_y]<=1'b1;
end
else begin end
```

字符下滑及消除(由于尚未加入键盘模块，暂时约定字符下滑到屏幕底部自动消除):

```verilog
if(moveable==1'b1&&h_offset==10'd0&&v_addr==10'd0)begin  
	offset[charIndex]<=offset[charIndex]+speed;
    if(offset[charIndex]>=lower_bound) begin
		//临时擦除字符试验
		speed[charIndex]<=3'd0;
		reg_speed<=3'd0;
		offset[charIndex]<=10'd520;
		columnTable[charIndex]<=1'b0;	
	end
end
else begin offset[charIndex]<=offset[charIndex]; end
```

至此将sof文件烧写到开发板上之后，字符已经可以随机产生并且平滑下落，到达屏幕底部之后自动消失且不再出现．

##### 7.导入已设计好的键盘控制器模块，并稍加修改

![image-20191231152813541](reportIMG/image-20191231152813541.png)

![image-20191231152758392](reportIMG/image-20191231152758392.png)

##### 8.加入键盘消除字符功能

对之前设计的字符产生及下滑模块加以修改，具体修改"临时擦除字符试验"部分，设计如下:

```verilog
if(remove_flag==1'b1&&get_asc==press)begin  //字符消除
		reg_speed<=3'd0;
		offset[charIndex]<=10'd520;
		columnTable[charIndex]<=1'b0;
		remove_flag<=1'b0;
end
else if(moveable==1'b1&&h_offset==10'd0&&v_addr==10'd0)begin  //该字符没有被消除，继续字符下滑
		offset[charIndex]<=offset[charIndex]+speed;
		if(press==8'h31)begin remove_flag<=1'b1; end  //松开按键，准备消除下一个字符
end
else begin offset[charIndex]<=offset[charIndex]; end
```

至此基本功能已经实现完毕.

##### 9.计分

初步实现：字符下滑模块中消除字符分支进行计分

```verilog
if(remove_flag==1'b1&&get_asc==press)begin  //字符消除
			reg_speed<=3'd0;
			offset[charIndex]<=10'd520;
			columnTable[charIndex]<=1'b0;
			remove_flag<=1'b0;
			//计分
			score <= score + 8'd1;
end
```

改进：在后面实现界面切换功能时，需要在重新进入游戏状态时将score清零，所以需要将计分移至状态机的实现当中，根据`remove_flag`判断分数是否增加

```verilog
always @ (posedge CLOCK_50) begin //状态转换
    case(state)
			WEL_STATE:
			PLAY_STATE:begin
				
				if(remove_flag==1'b0)begin //解决由于时序导致的积分问题
					if(score_flag==1'b1) 
						score_flag<=1'b1;
					else begin	
                        //计分
						score<=score+8'd1;
						score_flag<=1'b1;
					end
				end
				else
					score_flag<=1'b0;
				
				
                if(gameover) begin //转移至结束状态
					clk_en<=1'b0;
					pressing<=1'b1;
					state <= END_STATE;
				end			
			end
			END_STATE:


		endcase
	end
```

值得注意的是，这里由于状态切换和`remove_flag`设置采用的时钟不同，为了保证在一个`VGA_CLK`周期内，分数只增加一次，采用了如下结构：

```verilog
if(remove_flag==1'b0)begin 
	if(score_flag==1'b1) 
        score_flag<=1'b1;
    else begin	
        //计分
		score<=score+8'd1;
		score_flag<=1'b1;
	end
end
else
	score_flag<=1'b0;
```

该结构保证了在一次`remove_flag`为1的周期里分数只被计算一次

##### 10.FPS计数

VGA_CLK每525*800=420000个周期扫描过一帧，因此通过时钟`VGA_CLK`进行驱动fps计数，另生成一一秒的时钟`fpsclk`进行显示驱动

```verilog
	clkgen #(1) fps_clk(CLOCK_50,1'b0,1'b1,fpsclk);
	
	always @ (posedge fpsclk) 
		fps_reg=fps<<1;
```

##### FPS和分数显示

计算字模点阵中的地址

```verilog
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
```

显示：

```verilog
if(sflag==1'b1&&(scolor_bit>>sh_offset)&12'h001 == 1'b1) //显示帧率和分数
	vga_data <= 24'hff00ff;
```

##### 界面状态机设计

```mermaid
graph LR
	s1(开始界面)
	s2(游戏界面)
	s3(结束界面)
	s1--回车键-->s2
	s2--gameover-->s3
	s3--回车键-->s1
```

###### 状态转换实现

```verilog
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
```

同样值得注意的是，在`WEL_STATE`和`END_STATE`状态下，对回车键的响应也采用了与计分相同的时序同步结构。是因为这里采用的时钟是50MHz，该结构也可以保证一次回车只切换一个状态

```verilog
				if(press==8'd13)begin
					if(pressing)begin
						pressing<=1'b1;
					end
					else begin
						pressing<=1'b1;					
						state <= next_state;
					end
				end
				else
					pressing<=1'b0;
```



###### 界面设计

在分辨率640*480下，如果采用12bitRGB存储两张图片，则需要占用约7MB的片内内存，显然这是不可行的。因此此处采用了3bitRGB

在Photoshop中进行制作界面图片

![QQ截图20200101160957](reportIMG/QQ截图20200101160957.png)

保存为bmp文件后使用Pic2Mif将图片转换为mif文件

![QQ截图20200101161200](reportIMG/QQ截图20200101161200.png)

然后创建IP核，并以mif文件进行初始化

### 6.测试方法

随机生成模块```Generator```：<span style='color:red;background:white;font-size:16;font-family:字体;'>TODO：补充之</span>

顶层实体：由于此次实验较为复杂，不便于编写测试文件进行功能仿真，故采取直接烧写到开发板上运行的方式。在对代码进行测试时采取由简到繁的方式，即首先实现单个字符的平滑下落，然后在不加入键盘模块的情况下测试能否正常随机生成多个字符并以随机速度平滑下落；最后加入键盘模块后首先增加七段数码管显示及LED灯用于辅助调试，测试能否正确消除字符；上述步骤均无问题后再开始加入计分及其他功能。



### 7.实验结果

**下载运行结果：课上已验收**



### 8.实验中遇到的问题及解决方法

##### 1.设计字符产生及下滑代码的过程中出现如下报错:

> Error (10028): Can't resolve multiple constant drivers for net "offset[1][8]" at Game.v(166)

网上查阅资料后得知，出现这个错误的原因在于，在不同的always逻辑块中对同一个reg变量进行赋值，导致在always块并行工作时出现冲突．于是将字符产生和下滑放到了同一个always块中，问题解决.

##### 2.设计always块的过程中出现如下报错:

> Error (10200): Verilog HDL Conditional Statement error at Game.v(140): cannot match operand(s) in the condition to the corresponding edges in the enclosing event control of the always construct

网上查阅资料后得知，原因在于always块的敏感变量并未在块中作为条件进行判断语句如何执行，删去多余敏感变量、对必须的变量加以判断后，问题解决.

##### 3.在初步设计中，键盘按下一个按键会消除对应的所有字母而非只消除一个

经讨论思考，增加一个变量用于标志是否以及消除过字符，若消除过则置１以使后续扫描过程中不再继续消除，且在每次松开按键后将该标志重新置０. 问题解决.