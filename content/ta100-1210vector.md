+++
title = "TA百人计划 图形 1.2.1 向量基础"
description = ""
date = 2021-11-08 22:26:14+08:00
path = "ta100-1210vector"
[taxonomies]
categories = ["blog"]
tags = ["百人计划", "TA", "图形学", "线性代数"]
+++

这东西实在太熟了。毕竟一直在做的CV、DL都绕不过线性代数。所以文章最后搞了个好玩的。
<!-- more -->
地址：[【技术美术百人计划】图形 1.2.1 向量基础](https://www.bilibili.com/video/BV1n54y1Y7wB)
# 笔记
## 向量的定义
- 向量是有大小和方向的有向线段
- 向量没有位置，只有大小和方向
- 箭头方向就是向量方向，从头指向尾
- 可以用来表示空间上的位移（向量拆分为各个轴上的分量分别位移）
- 向量表示：(a,b,c) 几维就几个 （其实应该用矩阵表示的。。）
## 向量跟标量比较
向量有方向，标量没有。
## 向量和点比较
表示形式一样，几何意义不一样  
点只表示一个位置，没有大小没有方向  
向量不表示位置，有大小跟方向  
表示形式上。点可以看成原点出发到点位置的一个向量
## 零向量
大小为0，没有方向
## 向量计算
### 跟标量计算
- 不能相加减（一直习惯了各种标量+矩阵的自动转换还真忘了这点）
- 可以相乘除，每一个分量分别乘上标量值
### 模
向量长度。计算方式：每个分量平方开根号$\sqrt{x^2+y^2+z^2...}$
### 单位向量
向量/模 $\frac{\vec a}{||\vec a||}$,使向量长度归为1，成为一个长度为1，实际只表示方向的向量
### 向量相加/减
每个分量分别相加/减
### 两点间距离
两点以向量表示，向量相减得到的新向量模为两点距离
### 点积
两个矩阵每列每行相乘后求和,满足交换律，结果是个标量  
兰伯特模型根据点积表示向量相似度的特性计算漫反射光照强度  
另外，各种AI算法里常用`余弦相似度`计算特征之间的相似度
### 投影
一个向量在另一个向量上的长度。在另一个向量方向上的分量。
### ×积
每个分量交叉相乘后相减，不满足交换律,结果是个向量  
结果和两个向量垂直

# 作业
## 各种向量计算的几何意义
### 跟标量计算
- 只有乘除，向量长度缩放为标量倍数，负值就方向相反
### 向量之间的计算
- 相加：两个向量为边的平行四边形对角线/向量沿着另一个向量方向平移后的位置为结束点，原始方向为起始点的一个新的向量
- 相减：减向量结尾指向被减向量结尾的一个向量/模可当成两点间距离
- 点积：两个向量的相似程度，正交情况下点积为0，值越大表示向量夹角越小。
- 投影：一个向量在另一个向量方向上的长度
- 叉积：垂直于两个向量所在的平面
### 其他
- 模：向量的长度
- 标准化（归一化）：向量长度归一，一般只需要方向情况下用到
## 连连看实现兰伯特、半兰伯特
连就不连啦。用glsl实现一个放网页上动态显示
<iframe id="inlineFrameExample"
    title="Inline Frame Example"
    style="width:100%;height:auto;aspect-ratio:16/9;"
    src="exp.html">
</iframe>



``` glsl
// 顶点着色器
#version 300 es
precision highp float;
in vec3 Vertex_Position;
in vec3 Vertex_Normal;
out vec3 fragNormal;
layout(std140) uniform CameraViewProj { // set = 0, binding = 0
    mat4 ViewProj;
};
layout(std140) uniform Transform { // set = 1, binding = 0
    mat4 Model;
};
void main() {
    gl_Position = ViewProj * Model * vec4(Vertex_Position, 1.0);
    // 计算TBN矩阵，转换为世界坐标
    fragNormal = mat3(transpose(inverse(Model))) * Vertex_Normal;
}
```

```glsl
// 兰伯特
#version 300 es
precision highp float;
in vec3 fragNormal;
out vec4 o_Target;
layout(std140) uniform LambertMaterial_lightDir { // set = 2, binding = 0
    vec3 lightDir;
};
void main() {
    // 这里光照方向是自己xjb构造的，先做个归一化
    vec3 light = normalize(lightDir);
    // 基本颜色。简单给个纯白
    vec3 base = vec3(1,1,1);
    // 灵魂部分。法线和光照方向点乘，再给个颜色
    vec3 col = dot(fragNormal, light)* base;
    o_Target = vec4(col,1.0);
}
```
```glsl
// 半兰伯特
#version 300 es
precision highp float;
in vec3 fragNormal;
out vec4 o_Target;
layout(std140) uniform LambertMaterial_lightDir { // set = 2, binding = 0
    vec3 lightDir;
};
void main() {
    vec3 light = normalize(lightDir);
    vec3 base = vec3(1,1,1);
    // 区别在于重新映射范围[-1,1] -> [0,1]
    vec3 col = dot(fragNormal, light)* base*0.5+0.5;
    o_Target = vec4(col,1.0);
}
```
