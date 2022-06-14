自动生成tinc配置文件，免去繁琐的配置过程

使用教程：[linux安装tinc并配置](https://www.lvaohui.top/article/202101251558/)

mac 配置参考：[开发机 / MacOS Mojave](https://chanix.github.io/TincCookbook/examples/4-HowToInstallTincOnMacOSMojave.html)

windows 配置参考：[醉卧草庐听风雨 - Tinc VPN 折腾日记](https://wuzk.ink/2018/09/13/2018/20180913/#Windows%E5%AE%A2%E6%88%B7%E7%AB%AFpc)

openwrt 配置参考：[hiplon - OpenWRT结合tinc组自己的SDLAN](https://cloud.tencent.com/developer/article/1666197)

***openwrt 除了配置，还需要修改 `/etc/config/tinc` 文件***

---

openwrt 如果要实现跨网段访问，需要在 `/etc/tinc/tincnet` 文件夹下的 `tinc-up` 和 `tinc-doown` 中分别设置添加路由和删除路由的命令：

~~~bash
# tinc-up
ip route add <目标网段> via <目标网段的网关> dev $INTERFACE src <本机IP>
ip route add 192.168.12.0/24 via 10.0.0.6 dev $INTERFACE src 10.0.0.7

# tinc-doown
ip route del 192.168.12.0/24
~~~
