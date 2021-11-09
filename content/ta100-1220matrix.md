+++
title = "TA百人计划 图形 1.2.2 矩阵运算"
description = ""
date = 2021-11-09 13:08:01+08:00
path = "ta100-1220matrix"
[taxonomies]
tags = ["百人计划", "TA", "图形学"]
categories = ["blog"]
+++

线代的内容还是推荐3b1b的视频。是我看过关于线性代数最直观易懂的视频了  
[【官方双语/合集】线性代数的本质 - 系列合集](https://www.bilibili.com/video/BV1ys411472E)
<!-- more -->
地址：[【技术美术百人计划】图形 1.2.2 矩阵运算](https://www.bilibili.com/video/BV1mi4y1T77i)

# 笔记
## 线性
- 线性方程：一次方程，具有线性关系的方程，具有可加性、比例性
- 线性空间：直线变换后依然直线，保持等比。坐标原点不变
- 非线性空间：空间扭曲，不是等距。坐标原点带偏移
## 解方程组
矩阵用来解线性方程组
对于：
$\begin{cases}
2x+3y=1 \newline
x+y=2 \newline
\end{cases}$ 这么一个方程组。可以构造如下矩阵  
$\left[\begin{matrix}
2&3\newline
1&1\newline
\end{matrix}\right]
\left[\begin{matrix}
x\newline
y\newline
\end{matrix}\right]
=\left[\begin{matrix}
1\newline
2\newline
\end{matrix}\right]
$  
转化为求$
\left[\begin{matrix}
x\newline
y\newline
\end{matrix}\right]$向量的计算  
写为增广矩阵形式
$
\left[\begin{matrix}
2&3&1\newline
1&1&2\newline
\end{matrix}\right]$  
每行间进行线性计算得到
$
\left[\begin{matrix}
1&0&5\newline
0&1&-3\newline
\end{matrix}\right]$  
最后得到
$\begin{cases}
x+0y=5\newline
0x+y=-3\end{cases}$ 即 $\begin{cases}x=5\newline y=-3\end{cases}$  
实际上是将方程组转化为空间下的向量，解方程组就是将空间转换为标准坐标系下，拆解成每个独立的分量，最后得到的就是方程组的解
## 矩阵定义
m行n列元素的排列，形成$m \times n$的矩阵
## 特殊矩阵
- 方阵：行列数量相等的矩阵
- 单位阵：左上到右下对角线元素为1，其他元素为0的矩阵（方阵）
- 零矩阵：所有元素都是0的矩阵
## 矩阵加/减
同行矩阵间的操作（两个矩阵的行跟列个数都一样）。  
计算方式为，两个矩阵对应位置元素相加/减，满足交换律、结合律
## 矩阵数乘/除
矩阵的每个元素乘/除上系数k
## 矩阵相乘
需要满足左边矩阵的列数等于右边矩阵的行数  
计算方式：结果C为$
\begin{align}
C=(c_{ij}):
c_{ij}=a_{i*} \cdot b_{*j} && (i=1...,m;j=1...,n)
\end{align}
$  
A的每个行向量和B的每个列向量做点积  
运算规则：从右往左计算。满足结合律但不满足交换律。满足分配律
## 转置
将矩阵行列元素交换。每个元素$a_{i,j}$变换为$a_{j,i}$  
 .直观表现为矩阵元素沿着45°对角线翻转位置  
特性：  
$(AB)^T=B^TA^T$  
$(A+B)^T=A^T+B^T$  
$(A^T)^T=A$
## 逆矩阵
$A \times A^{-1} = 1$  
矩阵乘上他的逆矩阵得到单位阵  
乘上一个矩阵的逆相当于进行逆向变换
特性：  
$(A^{-1})^{-1}=A$  
$kA可逆,k\neq 0，(kA)^{-1}=\frac{1}{k} A^{-1}$  
$(AB)^{-1}=B^{-1}A^{-1}$  
$(A^T)^{-1}=(A^{-1})^T$
## 几种基本变换矩阵
1. 纵向拉伸：$\left[\begin{matrix}1&0\newline 0&c\end{matrix}\right]$
2. 缩放：$\left[\begin{matrix}x&0\newline 0&y\end{matrix}\right]$
3. 斜切：$\left[\begin{matrix}1&k\newline 0&1\end{matrix}\right]$
4. 旋转：$\left[\begin{matrix}cos\theta & -sin\theta \newline sin\theta &cos\theta \end{matrix}\right]$
5. 镜像：$\left[\begin{matrix}0&1\newline 1&0\end{matrix}\right]$
6. 位移：$\left[\begin{matrix}1&0&x\newline 0&1&y \newline 0&0&1\end{matrix}\right]$
# 作业
## 矩阵运算的几何意义
矩阵运算就是坐标变换。复杂的变换矩阵可以通过简单的变换矩阵相结合产生。
## 矩阵计算公式
1. 数乘
$kA_{i,j}=\left[\begin{matrix}
 k\cdot a_{11}&k\cdot a_{12}&\cdots&k\cdot a_{1j}\newline
 k\cdot a_{21}&k\cdot a_{22}&\cdots&k\cdot a_{2j}\newline 
 \vdots&\vdots&\ddots&\vdots\newline 
 k\cdot a_{i1}&k\cdot a_{i2}&\cdots&k\cdot a_{ij}\newline 
\end{matrix}\right]$
2. 相加
$A_{i,j}+B_{i,j}=\left[\begin{matrix}
 a_{11}+b_{11}&a_{12}+b_{12}&\cdots&a_{1j}+b_{1j}\newline
 a_{21}+b_{21}&a_{22}+b_{22}&\cdots&a_{2j}+b_{2j}\newline 
 \vdots&\vdots&\ddots&\vdots\newline 
 a_{i1}+b_{i1}&a_{i2}+b_{i2}&\cdots&a_{ij}+b_{ij}\newline 
\end{matrix}\right]$
3. 相乘
$A_{m,n}\times B_{n,p}=\left[\begin{matrix}
a_{11}\times b_{11}+a_{12}\times b_{21}+\cdots +a_{1n}\times b_{n1} & \cdots & a_{11}\times b_{n1}+a_{12}\times b_{n2}+\cdots +a_{1n}\times b_{np}\newline
\vdots & \ddots & \vdots \newline
a_{m1}\times b_{11}+a_{12}\times b_{21}+\cdots +a_{mn}\times b_{n1} & \cdots & a_{m1}\times b_{n1}+a_{12}\times b_{n2}+\cdots +a_{mn}\times b_{np}\newline
\end{matrix}\right]$
