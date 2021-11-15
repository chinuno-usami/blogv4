+++
title = "TA百人计划 图形 2.4 传统经验光照模型详解"
description = ""
date = 2021-11-15 11:40:05+08:00
path = "ta100-2400lighting"
[taxonomies]
tags = ["百人计划", "TA", "图形学"]
categories = ["blog"]
+++

地址：[【技术美术百人计划】图形 2.4 传统经验光照模型详解](https://www.bilibili.com/video/BV1B54y1j7zE)

<!-- more -->
# 笔记
## 光照模型
光线与空间中物体表面交互的模型。分为2类：
- 基于物理的光照模型：使用物理的度量、统计方法，效果真实，计算复杂，实现困难。
- 经验模型：通过实践总结出简化方法，简化光照计算并能达到不错的效果。
## 为什么需要光照模型
现实世界光照复杂，无法完全模拟。使用简化的光照模型对现实光照进行近似，处理起来更容易并且效果符合需求。
## 局部光照模型
只考虑自然光源的直接光影响，光源发出经过物体表面反射直接到达镜头的光。
全局光照模型： 光源发出的光经过在物体表面多次反射最后到达镜头的光。  
## 漫反射
光照射到物体表面，被均匀分散到各个方向的现象叫做漫反射。  
漫反射过程中光线被吸收、散射，**因此改变颜色和方向**。  
漫反射满足`lambert定律`，反射光强和法线与光源方向夹角的余弦值成正比。
漫反射效果与观察者位置无关，与光源位置有关。  
lambert余弦定律: $color=C_{light} * albedo * dot(normal,L);$  
其中$C_{light}$为入射光颜色，albedo为漫反射材质
## 镜面反射
光线没有被吸收，直接反射出来。**光强不变方向改变。**  
观察视线在反射光线附近时能观察到。  
镜面反射的反射率根据`菲涅尔效应`决定。  
通常使用反射贴图描述物体表面的反射率，使用粗糙度描述高光范围的大小。  
计算公式：$C_{specular}=C_{light} * m_{specular} * dot(v,r)^{m_{gloss}}$  
$r = 1-2 * dot(n,l) * n$  
$m_{gloss}$为材质光泽度  
$m_{specular}$为材质反射率  
r为反射光线，v为视线向量
## 环境光
局部光照模型中不考虑间接光照影响，引入环境光来处理间接光照。
计算方式：$C_{ambient}=albedo * ambient_{light}$  
模型假定场景光经过多次反射、散射，均匀地照在物体上。
## 自发光
物体自身发射的光。常用发光贴图描述。
## 经典光照模型
1. Lambert模型。用来实现漫反射。  
lambert余弦定律: $color=C_{light} * albedo * dot(normal,L);$  
其中$C_{light}$为入射光颜色，albedo为漫反射材质
2. Phong模型。光照=环境光+漫反射+高光。  
$C_{final}=A_{light} * m_{diffuse} + C_{light} * (m_{diffuse} * dot(l,n) + m_{specular} * dot(v,r)^{gloss})$  
$A_{light}$:环境光量  
$C_{light}$:入射光量  
$m_{diffuse}$:漫反射率  
$m_{specular}$:镜反射率  
l:入射光向量  
n:物体表面法向量  
r:反射向量  
gloss：光泽度
3. Blinn-Phong模型。高光部分使用半角向量h计算。  
$C_{final}=A_{light} * m_{diffuse} + C_{light} * (m_{diffuse} * dot(l,n) + m_{specular} * dot(h,n)^{gloss})$   
相比Phong模型，计算更为简洁，视线与光照在法线同一侧时不会丢失高光形成断层。
4. Flat模型。lowpoly风格化效果。每个三角形只有一个法线方向，以相同的光强度显示多边形上所有的点。

# 作业
这作业是要自己写出一个PBR模型？  
能量守恒：出射光线的能量永远不能超过入射光线的能量（发光面除外）
## 说出能量守恒理念在基础光照模型中的作用
基础光照模型没有考虑能量守恒。要说作用那可能就是，传统光照模型依赖于人工经验手动调整，那么调整时人就会根据经验调出一个符合能量守恒的效果出来。  
基于考虑能量守恒的微平面模型，使用BRDF（满足能量守恒的，使用入射光方向、观察方向计算的blinn-phong也算BRDF，但不满足能量守恒）计算材质上每束光的反射、折射贡献。因为满足能量守恒，所以获得的光照效果更真实。
## 基于能量守恒的理念，自己写一套包含环境光照的完整光照模型
在传统光照上进行修改。使用菲涅尔方程计算反射、折射的光线比（Fresnel-Schlick近似）  
以菲涅尔方程算出来的比例对(漫反射+镜面反射)和环境光进行插值  
![light](light.png)  
效果是个类似铜像的效果。使用这个cubemap环境光的效果不是很明显
```glsl
// 菲涅尔。计算反射光线比值
float fresnel(vec3 n, vec3 v, float F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - dot(n,v), 5.0);
}  

void main(void) {
    const vec3 base = vec3(0.8, 0.4, 0.15);
    const float gloss = 50.0;
    // 菲涅尔系数
    const float f0 = 0.95;
    // 根据粗糙度取mipmap等级
    const float numMips = 6.0;
    const float roughness = 0.1;

    vec3 n = normalize(v_normal);
    vec3 l = normalize(u_light);
    vec3 v = normalize(u_camera - v_position.xyz);

    // 漫反射 lambert
    float diffuse = dot(n, l) * 0.5;
    vec4 diff = vec4(base * diffuse,1.0);
    // 高光 blinn-phong
    vec3 h = normalize(n+v); // 半角
    vec4 specular = vec4(vec3(pow(dot(h,n), gloss)),1.0);
    float fres = fresnel(n,v,f0);
    // 环境光
    vec3 ref = reflect(-v,n);
    vec4 amb = mix(textureCube( u_cubeMap, ref, (roughness * numMips) ), 
                   textureCube( u_cubeMap, ref, min((roughness * numMips) + 1.0, numMips)), 
                   fract(roughness * numMips) );
    // 插值，环境光和反射光总量固定为入射光
    vec4 color = mix(amb, specular+diff, fres);
    gl_FragColor = color;
}

```

