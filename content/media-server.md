+++
title = "媒体服务器选型研究"
description = ""
date = 2022-10-03 11:33:26+08:00
path = "media-server"
[taxonomies]
tags = ["媒体服务器", "RTMP推流"]
categories = ["blog"]
+++

研究一下媒体服务器选型
<!-- more -->
# nginx-rtmp-module
项目地址：https://github.com/arut/nginx-rtmp-module
## 基本功能
1. RTMP/HLS/MPEG-DASH实时串流
2. 点播
3. 推、拉模式流转发
4. 录制视频流成文件
5. 实时转码
6. 回调支持
## 简单部署
作为nginx的扩展模块，可以自己编译，可以包管理安装`libnginx-mod-rtmp`使用
https://www.digitalocean.com/community/tutorials/how-to-set-up-a-video-streaming-server-using-nginx-rtmp-on-ubuntu-20-04
提供简单的Dockerfile，可以docker部署：
https://github.com/arut/nginx-rtmp-module/wiki/Building-a-docker-image-with-nginx--rtmp-module
## 文档
英文文档，基本为配置说明，其他部分不够完善
https://github.com/arut/nginx-rtmp-module/wiki/Directives
## 鉴权控制
配置支持事件回调，在触发推流、拉流等事件的时候可以执行自定义http回调，可以在回调中进行鉴权控制，只允许匹配的客户端推流、拉流
https://github.com/arut/nginx-rtmp-module/wiki/Directives#notify
通过http状态码进行控制

| 状态码 | 行为 |
| ---- | ---- |
| 200 | 正常状态，继续执行 |
| 300 | 重定向到新地址 |
| 其他 | 断开连接 |

支持通知类型：
-   [on_connect](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_connect)
-   [on_play](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_play)
-   [on_publish](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_publish)
-   [on_done](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_done)
-   [on_play_done](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_play_done)
-   [on_publish_done](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_publish_done)
-   [on_record_done](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_record_done)
-   [on_update](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_update)
-   [notify_update_timeout](https://github.com/arut/nginx-rtmp-module/wiki/Directives#notify_update_timeout)
-   [notify_update_strict](https://github.com/arut/nginx-rtmp-module/wiki/Directives#notify_update_strict)
-   [notify_relay_redirect](https://github.com/arut/nginx-rtmp-module/wiki/Directives#notify_relay_redirect)
-   [notify_method](https://github.com/arut/nginx-rtmp-module/wiki/Directives#notify_method)
简单重定向示例：
```nginx
http {
    ...
    location /local_redirect {
        rewrite ^.*$ newname? permanent;
    }
    location /remote_redirect {
        # no domain name here, only ip
        rewrite ^.*$ rtmp://192.168.1.123/someapp/somename? permanent;
    }
    ...
}

rtmp {
    ...
    application myapp1 {
        live on;
        # stream will be redirected to 'newname'
        on_play http://localhost:8080/local_redirect;
    }
    application myapp2 {
        live on;
        # stream will be pulled from remote location
        # requires nginx >= 1.3.10
        on_play http://localhost:8080/remote_redirect;
    }
    ...
}
```
配置中设置on_play动作的回调url，当有人拉流时会发送POST到on_play后面指定的url，内容为：
-   call=play
-   addr - 客户端 ip
-   clientid - nginx 的 client id
-   app - app名
-   flashVer - 客户端flash版本
-   swfUrl - 客户端swf地址
-   tcUrl - tcUrl
-   pageUrl - 客户端页面url
-   name - 当前流的名字

如果推流地址中附带其他参数，那么也会一起带上。例如
`rtmp://localhost/app/movie?token=1145141919810`
那么回调请求会增加token字段，可以用这个字段来做鉴权
## 后台
提供超简单的统计页面在`/stat`
https://github.com/arut/nginx-rtmp-module/wiki/Getting-number-of-subscribers
## 分布式部署、高可用
可以配合keepalived实现高可用，nginx本身也能实现负载均衡的功能。可以以docker+k8s进行部署

# SRS
项目地址：https://github.com/ossrs/srs
## 基本功能
1. rtmp、hls、http-flv分发
2. DVR录像，将流录制成视频
3. 采集。将视频转为直播流、摄像头等设备转为直播流、rtsp转为直播流等。ffmpeg能拉取就能采集
4. 视频流转推
5. 支持视频截图（nginx通过on_publish回调也能做到）
6. 支持srt、dash

## 部署
官方推荐docker方式部署。可以k8s部署
https://ossrs.net/lts/zh-cn/docs/v4/doc/getting-started-k8s
提供了个视频可以通过github action直接部署到集群中
https://www.bilibili.com/video/BV1g44y1j7Vz/
## 文档
https://ossrs.net/lts/zh-cn/docs/v4/doc/introduction
文档齐全、中文、甚至还有视频
## 鉴权
https://ossrs.net/lts/zh-cn/docs/v4/doc/drm#token-authentication
同nginx一样，通过http回调进行鉴权控制
https://ossrs.net/lts/zh-cn/docs/v4/doc/http-callback
支持类型：
1. on_publish
2. on_unpublish
3. on_play
4. on_stop
5. on_dvr

相关文档：https://ossrs.net/lts/zh-cn/docs/v4/doc/drm
## 后台
支持http api获取流、客户端状态等信息
https://ossrs.net/lts/zh-cn/docs/v4/doc/http-api#streams
web控制台
https://ossrs.net/srs-console/trunk/research/console/ng_index.html#/connect
## 分布式、高可用
SRS本身支持分布式部署。可以配置源站集群、边缘集群方式。这样推流不管推到哪个源站、拉流不管去哪个服务器拉都能正常播放。
https://ossrs.net/lts/zh-cn/docs/v4/doc/sample-origin-cluster
https://ossrs.net/lts/zh-cn/docs/v4/doc/edge
### k8s集群
https://ossrs.net/lts/zh-cn/docs/v4/doc/k8s
## 其他
低延迟配置：https://ossrs.net/lts/zh-cn/docs/v4/doc/low-latency
# 总结
Nginx和SRS两者实现的基本功能都差不多。相比之下SRS文档较为完善，功能多一些，且原生支持多种集群方案。可以优先选择使用SRS方案。

