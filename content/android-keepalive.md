+++
title = "Android保活及图标隐藏研究"
description = ""
date = 2022-10-03 11:30:20+08:00
path = "android-keepalive"
[taxonomies]
tags = ["Android"]
categories = ["blog"]
+++

记录一下之前研究的的东西
<!-- more -->
# Android隐藏图标
## 目的
禁止用户打开受控端后台服务app
## 实现
### Android6.0之前
声明主题`android:theme="@android:style/Theme.NoDisplay"`即可
```xml
<activity
    android:name=".InvisibleActivity"
    android:excludeFromRecents="true"
    android:noHistory="true"
    android:launchMode="singleTask"
    android:taskAffinity=""
    android:theme="@android:style/Theme.NoDisplay"/>
```
### Android10之前
1. 使用`Intent过滤器`声明入口相关属性，不添加`launcher`类别让启动器不添加图标
在`AndroidManifest.xml`中修改
```xml
<activity android:name="MainActivity">
	<intent-filter>
		<action android:name="android.intent.action.MAIN" />
		<!-- 删除下面这行即可 --> 
		<category android:name="android.intent.category.LAUNCHER" />
	</intent-filter>  
</activity>
```
参考[官方文档示例](https://developer.android.com/guide/components/intents-filters#ExampleFilters)
2. 添加`<data>`标签将入口activiry声明为接收隐式intent，这样可以通过scheme打开
```xml
<activity android:name="MainActivity">
	<intent-filter>
		<action android:name="android.intent.action.MAIN" />
		<data android:host="MainActivity" android:scheme="blabla" />
		<category android:name="android.intent.category.LAUNCHER" />
	</intent-filter>  
</activity>
```
### Android10之后
Android10之后只允许满足至少下面一种情况的app不显示图标
>1. 它是系统应用，即使是更新后的应用。
>2. 它是托管式配置文件管理应用（工作资料所有者）。
>3. 它未请求任何权限。
>4. 它不包含任何组件（例如，Activity、内容提供程序、广播接收器和服务）。
具有图标且拥有已启用的可启动 Activity 的应用不受影响。除了上面列出的例外情况，所有应用均会显示一个图标。如果应用没有图标，则会显示默认的系统图标。点按没有可启动 Activity 的应用图标时会打开应用信息屏幕。

系统更新说明：https://source.android.google.cn/docs/setup/start/android-10-release?hl=zh-cn#limitations_to_hiding_app_icons
相关条件说明：https://developer.android.google.cn/reference/kotlin/android/content/pm/LauncherApps?hl=zh-cn#getactivitylist
#### 实现方式
利用`activity-alias`实现。思路为提供一个透明的别名图标，使用透明别名图标时隐藏原有图标。缺点是本身只是图标透明，还是会占有一个图标位置。
相关文章：https://blog.csdn.net/qq_30710615/article/details/106298458
示例项目：https://github.com/woshiyanxiong/helperDemo
#### 另一个思路
用pm禁用掉主activity，另外在其他的组件上做事。
```java
public static void hideAppIcon(Context context) {
    ComponentName componentName = new ComponentName(context, "my.package.LaunchActivity");
    PackageManager packageManager = context.getPackageManager();
    int state = packageManager.getComponentEnabledSetting(componentName);
    if (state != PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
        packageManager.setComponentEnabledSetting(componentName, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP);
    }}
```
## 其他
思考隐藏图标是否有必要。用户应当是知晓app的用处，并且打开的activity不给用户操作选项，或者直接就不加activity都行应当也是可以的。

# 保活研究
## 目的
保证app运行过程中不会被系统杀后台，并且死后能够拉起自身继续工作
## Android6.0之前
双进程保活。现成库：https://github.com/Marswin/MarsDaemon
## Android8.0之后
系统加强后台限制，杀后台时会将整个组的进程给杀掉，因此双进程保活失效。
### 实现
1. 暴力保活拉起
相关poc：https://github.com/tiann/Leoric
简单说明一下。系统杀后台时会在5ms内kill整个app的进程组，kill操作循环40次，总共200ms。对抗思路就是在整个过程中不断暴力起进程，只要让系统kill操作来不及杀死所有进程就行。
2. 利用adb
在当前场景下，既然机子一直通过usb连接着，那么可以利用adb来进行保活拉起。只要adb不断查询进程是否存在，不存在直接am开启app即可。
### 其他
比起死后拉起，更应该考虑的是保证长时间运行不被杀。思路应当是提高app优先级，避免被系统杀死。
#### 提高优先级的保活方案
1. 开启前台service 给个前台常驻通知即可
2. 忽略电池优化
3. 无障碍服务
4. 自启动权限
5. 任务列表加锁
主要还是需要用户配合进项相关设置。一些独立app开发者常用做法是，附上https://dontkillmyapp.com/ 让用户自己进行相关设置。
##### 相关实现
1. 前台服务
```kotlin
//前台服务
class ForegroundCoreService: Service() {
    override fun onBind(intent: Intent? ): IBinder? = null 
    private var mForegroundNF: ForegroundNF by lazy {
        ForegroundNF(this)
    }
    override fun onCreate() {
        super.onCreate()
        mForegroundNF.startForegroundNotification()
    }
    override fun onStartCommand(intent: Intent? , flags : Int, startId: Int): Int {
        if (null == intent) {
            //服务被系统kill掉之后重启进来的 
            return START_NOT_STICKY
        }
        mForegroundNF.startForegroundNotification()
        return super.onStartCommand(intent, flags, startId)
    }
    override fun onDestroy() {
        mForegroundNF.stopForegroundNotification() super.onDestroy()
    }
}

```
```kotlin
//初始化前台通知，停止前台通知
class ForegroundNF(private val service: ForegroundCoreService): ContextWrapper(service) {
    companion object {
        private const val START_ID = 101
        private const val CHANNEL_ID = "app_foreground_service"
        private const val CHANNEL_NAME = "前台保活服务"
    }
    private var mNotificationManager: NotificationManager? = null

    private var mCompatBuilder: NotificationCompat.Builder? = null

    private val compatBuilder: NotificationCompat.Builder?
        get() {
            if (mCompatBuilder == null) {
                val notificationIntent = Intent(this, MainActivity::class.java)
                notificationIntent.action = Intent.ACTION_MAIN
                notificationIntent.addCategory(Intent.CATEGORY_LAUNCHER)
                notificationIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                    //动作意图
                val pendingIntent = PendingIntent.getActivity(
                    this, (Math.random() * 10 + 10).toInt(),
                    notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT
                )
                val notificationBuilder: NotificationCompat.Builder = NotificationCompat.Builder(this, CHANNEL_ID)
                    //标题
                notificationBuilder.setContentTitle(getString(R.string.notification_content))
                    //通知内容
                notificationBuilder.setContentText(getString(R.string.notification_sub_content))
                    //状态栏显示的小图标
                notificationBuilder.setSmallIcon(R.mipmap.ic_coolback_launcher)
                    //通知内容打开的意图
                notificationBuilder.setContentIntent(pendingIntent)
                mCompatBuilder = notificationBuilder
            }
            return mCompatBuilder
        }

    init {
        createNotificationChannel()
    }

    //创建通知渠道
    private fun createNotificationChannel() {
        mNotificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            //针对8.0+系统
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            )
            channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            channel.setShowBadge(false)
            mNotificationManager?.createNotificationChannel(channel)
        }
    }

    //开启前台通知
    fun startForegroundNotification() {
        service.startForeground(START_ID, compatBuilder?.build())
    }

    //停止前台服务并清除通知
    fun stopForegroundNotification() {
        mNotificationManager?.cancelAll()
        service.stopForeground(true)
    }
}
```
2. 忽略电池优化
声明相关权限
```xml
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```
请求权限
```kotlin
//在Activity的onCreate中注册ActivityResult，一定要在onCreate中注册 
//监听onActivityForResult回调 
mIgnoreBatteryResultContract = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
    activityResult ->
        //查询是否开启成功 
        if (queryBatteryOptimizeStatus()) {
            //忽略电池优化开启成功
        } else {
            //开启失败 
        }
}

```
弹窗
```kotlin
val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) intent.data = Uri.parse("package:$packageName") 
//启动忽略电池优化，会弹出一个系统的弹框，我们在上面的
launchActivityResult(intent)
```
查询
```kotlin
fun Context.queryBatteryOptimizeStatus(): Boolean {
    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager?
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                powerManager ? .isIgnoringBatteryOptimizations(packageName)? : false
            } else {
                true
            }
}

```

