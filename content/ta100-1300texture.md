+++
title = "TA百人计划 图形 1.3 纹理的秘密"
description = ""
date = 2021-11-10 12:20:28+08:00
path = "ta100-1300texture"
[taxonomies]
tags = ["百人计划", "TA", "图形学"]
categories = ["blog"]
+++

内容突然多了起来
<!-- more -->
地址：[【技术美术百人计划】图形 1.3 纹理的秘密](https://www.bilibili.com/video/BV1sA411N7z3)
# 笔记
## 纹理3大问
### 纹理是什么
- 一张图片
- 可供着色器读写的存储结构  
不局限于存储图片，可以存储高度、法线等信息
### 为什么要纹理
空间换时间。提前计算好结果节省运行时的计算量。  
### 怎么用的
看下面~
## 纹理管线
$模型空间位置\overset{投影函数}{\rightarrow}参数空间坐标\overset{映射函数}{\rightarrow}纹理空间坐标(uv)\overset{取值采样}{\rightarrow}纹理值\overset{值变换}{\rightarrow}变换后需要的纹理数值$  
依赖纹理读取：着色器计算过程中临时计算出来的uv位置取获取纹理值，会降低效率。新显卡好像没有这个问题？
程序纹理：不通过查找得到纹理值，而是通过函数计算产生。有些通过屏幕坐标产生的纹理应该属于这一种？

## 纹理的Wrapping mode/Texture addressing mode
决定在采样位置超过纹理范围时该取什么值。
![](wrapping-mode.png)
## filter mode
纹理缩放旋转等变换时如何采样
unity里面有三种

|类型|描述|
|-----|-----|
|Point|最邻近过滤，直接取最近的点。速度快，视觉效果差，像素游戏可以用|
|Bilinear|双线性过滤，跟附近的四个点取平均值|
|Trilinear|三线性过滤，跟附近的点取平均值，同时还根据梯度获得2层mipmap的纹理进行加权混合。|  

![各向异性过滤](https://pic3.zhimg.com/80/v2-15acc5a127110daeb710eea4f0ad4036_720w.jpg)  
DirectX还提供了Anisotropic filtering。各向异性过滤。三线性过滤的梯度取的是uv方向梯度的最大值，而各向异性过滤把u,v方向的梯度单独计算。按照u,v方向的梯度比获取多层mipmap进行加权混合。效果最好，但是消耗算力。  
最邻近和双线性过滤存在多对一映射导致的颜色丢失和像素闪烁问题  

### 其他filter mode
- 立方卷积
- Quilez光滑曲线

## mipmap
将纹理按照不同等级进行缩放,查找纹理像素时根据缩放等级到对应的mipmap里进行采样。
### level选择
```c
float dx = ddx(i.uv);
float dy = ddy(i.uv);
float lod = 0.5*log2(max(dot(dx,dx), dot(dy,dy)));
float albedo = tex2Dlod(_MainTex, float4(i.uv,0,lod)).rgb;
```
### 各向异性过滤优化
![各向异性](aniso.png)  
视频里就是翻译了`Real-Time Rendering`里的内容。没看懂自己找了原版来看。  
原文：
> For current graphics hardware, the most common method to further improve texture filtering is to reuse existing mipmap hardware. The basic idea
is that the pixel cell is back-projected, this quadrilateral (quad) on the texture is then sampled a number of times, and the samples are combined.
As outlined above, each mipmap sample has a location and a squarish area
associated with it. Instead of using a single mipmap sample to approximate
this quad’s coverage, the algorithm uses a number of squares to cover the
quad. The shorter side of the quad can be used to determine d (unlike in
mipmapping, where the longer side is often used); this makes the averaged
area smaller (and so less blurred) for each mipmap sample. The quad’s longer side is used to create a line of anisotropy parallel to the longer side
and through the middle of the quad. When the amount of anisotropy is
between 1:1 and 2:1, two samples are taken along this line (see Figure 6.17).
At higher ratios of anisotropy, more samples are taken along the axis.

我的理解是。图左边是屏幕上看到的内容。蓝色框就是纹理的平面，因为斜着看所以是个奇怪的四边形。红色框就是屏幕上一个像素。  
这里反向投影，把屏幕变换到纹理的坐标上。那么就是右边这种样子，原来的四边形纹理原来是斜的，现在铺满整个空间是个矩形。一个像素看成原来是个矩形，现在映射过来成了个斜的四边形。  
红框短边上每个点属于同一个缩放级别的点，而长边属于会随着距离变化产生缩放需要多次采样的点。  
那么以两条短边中点画条中线就是lod梯度变化的方向。按照采样等级分段，每个红点代表采样点，在各自的mipmap上采样。最后把所有的采样结果做一个加权混合值作为当前这个像素(左图红框这块)的值。  

### CPU渲染优化 纹理图集/数组
减少Draw Call次数。一次提交多个纹理，减少为了切换纹理带来的额外Draw Call。
### GPU渲染优化 纹理压缩
减少传输带宽。

### CubeMap
立方体6个面的贴图。常用在环境光照
### 凹凸贴图
记录法线信息，在计算光照的时候根据法线贴图的信息进行扰动，达到看起来凹凸的效果  
### 位移贴图
记录了顶点的位移信息。真正的修改了顶点位置。需要顶点数量够多才有效果。

# 作业
## Filter mode有哪几种
1. 最邻近采样
2. 双线性插值
3. 三线性插值
4. 各向异性过滤
5. 立方卷积
6. 光滑曲线
## 纹理贴图的优化方式及原理
1. 把多张贴图放到一个纹理图集、纹理数组中。减少切换纹理调用的Draw Call次数。  
2. 对贴图进行压缩，减少贴图体积。降低传输贴图需要的带宽，减少传输数据耗时。
