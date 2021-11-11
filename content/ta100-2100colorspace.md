+++
title = "TA百人计划 图形 2.1 色彩空间介绍"
description = ""
date = 2021-11-11 09:13:37+08:00
path = "ta100-2100colorspace"
[taxonomies]
tags = ["百人计划", "TA", "图形学"]
categories = ["blog"]
+++

地址：[【技术美术百人计划】图形 2.1 色彩空间介绍](https://www.bilibili.com/video/BV1Qb4y1S7CC)
<!-- more -->
# 笔记
## 色彩发射器
### 色彩认知
光从光源发射，通过直射、折射、反射等路径进入人眼。人眼接收到光线产生化学反应对颜色产生认知感知。
### 光源
产生光的物体
### 波长
光具有波粒二象性，波长是光波动性的表现。理论上光的波长无限多种，但人能够看见的波长局限在一个范围内。
### 能量分布
光具有能量。能量的单位焦耳（J）。一种颜色波长可以看成多个不同颜色的波长叠加而成。
### 分光光度计
用于描述光的具体能量强度。输入混合波长光，可以拆分成组成混合光的各个单一波长光，并且可以测量单一波长光的能量。
### 光的传播
1. 直射光：光直射进入眼睛
2. 反射光：光经过物体表面反射进入眼睛
3. 折射光：光穿过物体进入眼睛
4. 光线追踪：光线弹来弹去，我们根据权重确定光线最后进入眼睛的颜色（应该描述为来自不同光源的光经过不同路径到达人眼后进行叠加产生的光更为准确）

光打到物体上时，一部分波长的光会被物体吸收，最后导致反射出去的光那部分波长的能量会降低。
## 接收者
人眼
### 相对亮度感知
昏暗环境下和明亮环境下对亮度感知不一样。新增同样强度的光源，昏暗环境下感知的亮度比明亮环境下感知的亮度更亮。
### 人眼HDR
具有自动调节曝光的能力（自动调节瞳孔大小）。能够看清亮部和暗部的细节。
### 人眼感光细胞分布
- 杆状细胞：感知亮度,对亮度特别敏感。所以YUV对亮度通道分配了更高的精度？
- 锥状细胞：感知颜色
### 锥状细胞
- L细胞：感知红色波长
- M细胞：感知绿色波长
- S细胞：感知蓝色波长

大概就是为什么描述颜色使用RGB模型的原因
### 人眼的本质
光源接收者。接收光信号转换为神经电信号传输给大脑
### 人眼接收光源的微积分公式
$C=\int_{min}^{max}S(\lambda)\cdot I(\lambda)\cdot R(\lambda)d\lambda$  
C：输出的电信号  
S：L、M、S细胞感知分布  
I：光谱强度分布  
R：反射物体吸收强度分布  
## 色彩空间的历史
### 19世纪 色彩的猜想
1. 人有100+种感受颜色的细胞
2. 人有三种分别感受R、G、B的感色细胞
3. 人有三种分别感受黑白、红绿、黄蓝的感色细胞

2、3两种成为现在的`色彩模型`
### 1905 Munsell 色彩系统
![munsell](munsell.png)  
美国艺术家 Albert Henry Munsell 提出。1930年被优化改良。   
基于主观认知的HSL（色相、饱和度、亮度）模型，通过色卡描述颜色
### 1931 RGB色彩规范系统
CIE建立的基于物理的量化色彩系统。  
测量方法：给定一块白板，左边一半用RGB3基色照射，右边用待测光照射，不断调整RGB比例达到人眼观察白板两边颜色一致。
![RGB](ciergb.png)  
测量出来的结果在435.8~546.1nm波长段的r值为负数。通过$r'=\frac{r}{r+g+b},g'=\frac{g}{r+g+b},b'=\frac{b}{r+g+b}$归一到[-1,1]范围，并且r+g+b=1，只需要两个量就能确定特定颜色。  
![RGB](rgb.png) 
以r为x轴，g为y轴绘制图表。
### 1931 XYZ颜色规范系统
为了简化计算对CIERGB进行修改。  
转换矩阵:$\left[\begin{matrix}X\newline Y\newline Z\newline\end{matrix}\right]
= \left[\begin{matrix}
2.7689&1.7517&1.1302\newline
1.0&4.5907&0.0601\newline
0.0&0.0565&5.5943\newline
\end{matrix}\right]
\left[\begin{matrix}r\newline g\newline b\newline\end{matrix}\right]
$  
#### Yxy色彩空间
为了计算方便。又对X,Y,Z结果进行归一化操作  
$\begin{cases}x=\frac{X}{X+Y+Z}\newline
y=\frac{Y}{X+Y+Z}\newline
z=\frac{Z}{X+Y+Z}=1-x-y\newline
\end{cases}$  
以Y表示亮度，xy表示色度构成Yxy色彩空间
## 色彩空间的定义
![色彩空间](colorspace.png)  
### 色域
三基色坐标，构成一个三角形
### Gamma
如何对三角形切分.  
以白点为中心，向外采样。Gamma为1的时候均匀切分（线性空间）。sRGB空间下Gamma值约为2.2。线性空间下计算方便，2.2情况下符合人对亮度的感观变化。
### 白点
色域三角形中心(最亮最白的地方)
## 常用色彩模型、色彩空间
- 色彩模型：使用一定规则描述颜色的方法。  
例如RGB、CMYK、LAB
- 色彩空间：至少满足色域、白点、Gamma三个指标  
例如`CIE XYZ`、`Adobe RGB`、`sRGB`、sRGB、`Japan Color 2001 Uncoated`、`US web Coated`
## 色彩空间转换
### RGB转HSV
V = max(R,G,B)  
$S = \begin{cases}\frac{V-min(R,G,B)}{V}& (V不为0)\newline 0& (V为0) \end{cases}$  

$H=\begin{cases}60\frac{G-B}{V-min(R,G,B)}&(V为G)\newline
120+60\frac{B-R}{V-min(R,G,B)}&(V为R)\newline
240+60\frac{R-G}{V-min(R,G,B)}&(V为B)\newline
\end{cases}$  
如果H小于0，H=H+360

### HSV转RGB
令：  
$H_{i}\equiv\lceil\frac{H}{60}\rceil$（分为6份）  
$f=\frac{H}{60}-H_{i}$（取小数部分）  
$p=V\times(1-S)$  
$q=V\times(1-f\times S)$  
$t=V\times(1-(1-f)\times S)$  
则：  
$(R,G,B)=\begin{cases}
(V,t,p)&(h_{i}为0) \newline
(q,V,p)&(h_{i}为1) \newline
(p,V,t)&(h_{i}为2) \newline
(p,q,V)&(h_{i}为3) \newline
(t,p,V)&(h_{i}为4) \newline
(V,p,q)&(h_{i}为5)
\end{cases}$


# 作业
## 色彩空间的定义
至少满足色域、白点、Gamma三个指标
## 人眼可见光范围
![波长](http://www.srrc.org.cn/kindeditor/attached/image/20190917/20190917160556_2769.png)  
一般人的眼睛可以感知的电磁波的波长在400～760nm之间，但还有一些人能够感知到波长大约在380～780nm之间的电磁波。人眼对555nm波长的光(绿色)最敏感。
