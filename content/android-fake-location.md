+++
title = "Android伪造定位之研究"
description = ""
date = 2022-10-09 19:13:21+08:00
path = "android-fake-location"
[taxonomies]
tags = ["Android", "GPS", "location", "Xposed"]
categories = ["blog"]
+++

研究几种伪造定位的方案
<!-- more -->
# 修改定位
三种方式：
1. 使用系统模拟定位api
2. xposed
3. 修改系统源码
## 系统api
容易被识别
### 判断是否可模拟（同时也是识别方法）
sdk 22 以下（android6.0）
使用
```java
android.provider.Settings.Secure.getInt(getContentResolver(), android.provider.Settings.Secure.ALLOW_MOCK_LOCATION, 0) != 0
```
判断
sdk22之后：
```java
try {
	LocationManager locationManager = (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);//获得LocationManager引用
	String providerStr = LocationManager.GPS_PROVIDER;
	LocationProvider provider = locationManager.getProvider(providerStr);
	if (provider != null) {
		locationManager.addTestProvider(
				provider.getName()
				, provider.requiresNetwork()
				, provider.requiresSatellite()
				, provider.requiresCell()
				, provider.hasMonetaryCost()
				, provider.supportsAltitude()
				, provider.supportsSpeed()
				, provider.supportsBearing()
				, provider.getPowerRequirement()
				, provider.getAccuracy());
	} else {
		locationManager.addTestProvider(
				providerStr
				, true, true, false, false, true, true, true
				, Criteria.POWER_HIGH, Criteria.ACCURACY_FINE);
	}
	locationManager.setTestProviderEnabled(providerStr, true);
	locationManager.setTestProviderStatus(providerStr, LocationProvider.AVAILABLE, null, System.currentTimeMillis());
	// 模拟位置可用
	canMockPosition = true;
	locationManager.setTestProviderEnabled(providerStr, false);
	locationManager.removeTestProvider(providerStr);
} catch (SecurityException e) {
	canMockPosition = false;
}
```
### 申请权限
```xml
<uses-permission android:name="android.permission.ACCESS_MOCK_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<uses-permission android:name="android.permission.ACCESS_LOCATION_EXTRA_COMMANDS"/>
```
### 使用方式
```java
manager.setTestProviderLocation(PROVIDER_NAME, location);// 开始修改,PROVIDER_NAME为实际使用的provider名字，location为位置信息
manager.removeTestProvider(PROVDER_NAME);//停止修改

// 经纬度转location
public Location generateLocation(LatLng latLng) {
	Location loc = new Location("gps");


	loc.setAccuracy(2.0F);
	loc.setAltitude(55.0D);
	loc.setBearing(1.0F);
	Bundle bundle = new Bundle();
	bundle.putInt("satellites", 7);
	loc.setExtras(bundle);


	loc.setLatitude(latLng.latitude);
	loc.setLongitude(latLng.longitude);

	loc.setTime(System.currentTimeMillis());
	if (Build.VERSION.SDK_INT >= 17) {
		loc.setElapsedRealtimeNanos(SystemClock.elapsedRealtimeNanos());
	}
	return loc;
}
```
### 参考api文档
https://developer.android.com/reference/android/location/LocationManager
### 参考项目
https://github.com/shoyu666/GpsMock/blob/master/app/src/main/java/com/nixiaoning/test/gpsmock/MockService.java#L41
### 参考文章（包含模拟步行部分）
https://www.cnblogs.com/baiqiantao/p/10692941.html
### 其他
一个说法为，伪造定位的频率要高于app获取定位的频率，否则会导致app取到真实的位置。  
需要在开发者设置中设置当前app为模拟定位app，这样就可以使用当前app模拟定位了。
## 修改系统源码
在GPS获取位置信息后会调用native层的`GnssCallback` jni回调到java的framework层`reportLocation`方法。  
修改思路为，添加控制开关，阻断`GnssCallback::gnssLocationCbImpl`里面的jni回调，阻止系统获取真实的GPS位置  
然后添加一个public系统函数另外调用`reportLocation`方法回报虚假的位置信息，在自己的app里调用这个新方法即可
## xposed
使用xposed模块修改目标app的定位获取结果。未root情况下可以考虑太极/[Xpatch](https://github.com/WindySha/Xpatch)/[LSPatch](https://github.com/LSPosed/LSPatch) 方案。
app除了GPS外可能还会用到wifi、基站辅助定位。xposed可以hook相关接口同时修改用于辅助定位的信息。
针对集成地图sdk的app也可以针对sdk做hook：
```kotlin
XposedHelpers.findAndHookMethod("com.amap.api.location.AMapLocation", realClassLoader, "getLongitude", object : XC_MethodHook() {
	@Throws(Throwable::class)
	override fun beforeHookedMethod(param: MethodHookParam) {
		super.beforeHookedMethod(param)
	}
	@Throws(Throwable::class)
	override fun afterHookedMethod(param: MethodHookParam) {
		super.afterHookedMethod(param)
		param.result = (param.result as double) + 偏移量    //偏移量 = 目标经度 - 实际经度， 只需要计算一次就可以
	}
})
```
对于有加固的app会自定义classloader，需要找到真正的classLoader
```kotlin
//拓展方法， 拿到壳的classLoader
fun considerFindRealClassLoader(pkgClassLoader: ClassLoader, callback: (realClsLoader: ClassLoader) -> Unit) {
	XposedHelpers.findAndHookMethod("com.stub.StubApp", pkgClassLoader, "attachBaseContext", Context::class.java, object : XC_MethodHook() {
		@Throws(Throwable::class)
		override fun beforeHookedMethod(param: MethodHookParam) {
			super.beforeHookedMethod(param)
		}
		@Throws(Throwable::class)
		override fun afterHookedMethod(param: MethodHookParam) {
			super.afterHookedMethod(param)
			logD("发现壳啦")
			//获取到的参数args[0]就是360的Context对象，通过这个对象来获取classloader
			val context = it.args[0] as Context
			//获取360的classloader，之后hook加固后的就使用这个classloader
			val classLoader = context.classLoader
			callback.invoke(classLoader)
		}
	})
}
//最终代码如下
considerFindRealClassLoader(lpparam.classLoader) {
	realClassLoader ->
	    XposedHelpers.findAndHookMethod("com.amap.api.location.AMapLocation", realClassLoader, "getLongitude", object : XC_MethodHook() {
		@Throws(Throwable::class)
		override fun beforeHookedMethod(param: MethodHookParam) {
			super.beforeHookedMethod(param)
		}
		@Throws(Throwable::class)
		override fun afterHookedMethod(param: MethodHookParam) {
			super.afterHookedMethod(param)
			param.result = 114.032524
		}
	})
}
```

### 修改思路
将获取wifi、基站等信息的接口hook后直接返回null，这样就会忽略其他信息直接使用GPS的位置信息。  
而hook掉GPS信息获取接口后就能返回自定义的位置信息了。  
参考实现： https://blog.csdn.net/qq_24542767/article/details/103567975 、 https://github.com/Mikotwa/FuckLocation  、 https://github.com/bigsinger/fakegps    

@
