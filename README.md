# NJU数电实验大作业

>阶段规划：
>
>```mermaid
>graph TD
>	p1(实现字符平滑下落)
>	p2(实现键盘消除)
>	p3(加入FPS和积分功能)
>	p1-->p2
>	p2-->p3
>```
>

 

## 阶段一 实现字符平滑下落

### 随机生成字符

每秒产生一个字符，模块命名为`Generator`

产生的字符信息如下：

```c++
typedef struct{
    unsigned char val;
    struct CharInfo{
        unsigned ex:1;	   //存在位
        unsigned speed:3;  //字符速度
        unsigned x:5;	   //字符行坐标
        unsigned y:7;	   //字符列坐标
    };
}GenChar;
```

使用随机序列发生器产生字符的字符号`val`、下降速度`speed` 、列坐标`y`

### 字符的存储

使用字符表进行存储，共为26个表项，每个表项为十六位大小，采用reg进行存储

字符表项结构如CharInfo所示：

|  15  | [14:12] | [11:7] | [6:0] |
| :--: | :-----: | :----: | :---: |
|  ex  |  speed  |   x    |   y   |



### 平滑下落实现

#### 方案一

> （完成后发现无法实现随机速度这一需求，因此被废弃）

对于显存RAM，另设一寄存器实现的缓冲区`CacheLine`，接收RAM一行的信息，并在RAM读取到下一行时同时写入

`C++`模拟此过程：

```c++
char vram[30][70]; //显存ram
volatile char output_char;
void fall(){
    char CacheLine[70];
    int enable=0;
    for(int i=0;i<30;i++){    //模拟显存读过程
       	enable=(i>0);  			//第一行不写入
        for(int j=0;j<70;j++){
            output_char=vram[i][j];//读出
            if(enable){  //将上一行的字符写入这一行，表示字符下降一行
                vram[i][j]=CacheLine[j];
            }
            CacheLine[j]=output_char;//将这一行的字符存入
        }
    }
}
    
```

可以看到这个过程实现的是字符的逐行下落（并不平滑），为了增加下落过程的粒度，我们考虑使用一种显存偏移的方式：

由于我们的显存是70×30，而显示器的分辨率为640×480，这意味着在垂直方向上，VGA控制器每扫描过`480/30=16`行，读显存的行地址下降1

于是我们可以设置一个显存的行偏移量`reg [3:0] ram_offset`，在刷新一定帧数后加1，然后将计算显存读地址的公式

```verilog
assign raddr=x_addr+(y_addr<<6)+(y_addr<<2)+(y_addr<<1);
```

改为

```verilog
assign raddr=x_addr+(y_addr-ram_offset)*70 //具体实现时将乘法改为位移
```

这样就能完成整个字符阵的平滑下落了！

#### 方案二

使用一种更契合硬件描述语言的编码方式，在刷新一定帧数后对所有字符表项更新坐标

```verilog
always @ (posedge render_clk) begin
    if(CharTable[0][15])begin  //字符A存在
        //我不确定Verilog是否可以这么写，后面实验试一下
        //更新字符A的行坐标
        CharTable[0][11:7]=CharTable[0][11:7]+CharTable[0][14:12]; 
    end
    if(CharTable[1][15])begin  //字符B存在
        CharTable[1][11:7]=CharTable[1][11:7]+CharTable[1][14:12]; 
    end
    if(...)
    if(...)
    //一共26个if
end
```

然后在设置`VGA_DATA`模块中，使用26个if计算当前扫描点对应的字符号，并从字模ROM中取出点阵信息，然后根据点阵信息修改`VGA_DATA`



## 实现键盘消除

将键盘输入的ASCII码转换为字符号`asc-'a'`，然后在字符表中将`ex`位置为1即可

