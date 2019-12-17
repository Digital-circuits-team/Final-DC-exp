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



### 平滑下落实现

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

由于我们的显存是30×70，而显示器的分辨率为480×640，这意味着在垂直方向上，VGA控制器每扫描过`480/30=16`行，读显存的行地址下降1

于是我们可以设置一个显存的行偏移量`reg [3:0] ram_offset`，在刷新一定帧数后加1，然后将计算显存读地址的公式

```verilog
assign raddr=x_addr+(y_addr<<6)+(y_addr<<2)+(y_addr<<1);
```

改为

```verilog
assign raddr=x_addr+(y_addr-ram_offset)*70 //具体实现时将乘法改为位移
```

这样就能完成整个字符阵的平滑下落了！

## 实现键盘消除

### 字符的存储

