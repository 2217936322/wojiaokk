#!/bin/bash
install(){
echo "我叫KK最牛逼 CentOS7.X版本正在内测中!"
read -p "输入系统版本，例如CentOS 5.11，输入5，然后回车：" versionNumber
echo "1 :国内服务器 七牛下载"
echo "2 :国外服务器 GitHub下载"
echo "3 :跟目录已经存在服务端"
read -p "请选择[默认3]" networkState
if(($versionNumber==5)); then
installSupportLibOnCentOS5
elif (($versionNumber==6)); then
installSupportLibOnCentOS6
else
echo "正式版本仅支持CentOS5.X和6.X！CentOS7.X内测请联系我叫KK！"
exit 0
fi
echo "开始执行安装流程......"
addSwap
installDOF
removeTemp
}
getIP() {
echo "获取 IP..."
IP=`curl -s http://v4.ipv6-test.com/api/myip.php`
if [ -z $IP ]; then
IP=`curl -s https://www.boip.net/api/myip`
fi
}
addSwap() {
B=`awk '/MemTotal/{printf("%1.f\n",$2/1024/1024)}' /proc/meminfo`
AA=$((9 - $B))
if (($AA > 1)); then
echo "正在根据当前物理内存 增加虚拟内存中($AA)..."
dd if=/dev/zero of=/var/swap.1 bs=${AA}M count=1000
mkswap /var/swap.1
swapon /var/swap.1
echo "/var/swap.1 swap swap defaults 0 0" >>/etc/fstab
sed -i 's/swapoff -a/#swapoff -a/g' /etc/rc.d/rc.local
echo "添加虚拟内存成功"
elif (($AA <= 1)); then
echo "系统检测运行内≤8G不需要添加虚拟内存"	
fi
}
nstallSupportLibOnCentOS5() {
echo "安装CentOS5运行库..."
if (($networkState==3)); then
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-5.repo
yum clean all
yum makecache
fi
yum -y update
yum -y upgrade
yum install -y mysql mysql-server mysql-devel
yum -y install gcc gcc-c++ make zlib-devel libc.so.6 libstdc++ glibc.i686
chkconfig mysqld on
service mysqld start
service mysqld stop
}
installSupportLibOnCentOS6() {
echo "安装CentOS6运行库..."
if (($networkState==1)); then
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
yum clean all
yum makecache
fi
yum -y update
yum -y upgrade
yum install -y mysql mysql-server mysql-devel
yum -y install gcc gcc-c++ make zlib-devel
yum -y install xulrunner.i686
yum -y install libXtst.i686
service mysqld start
service mysqld stop
}
installDOF() {
getIP
echo -n "${IP} 是否是你的外网IP？(如果不是你的外网IP或者出现两条IP地址，请键入 n 自行输入) y/n [n] ?"
read ans
case $ans in
y|Y|yes|Yes)
;;
n|N|no|No)
read -p "输入你的外网IP地址，回车（确保是英文字符的点号）：" myip
IP=$myip
;;
*)
;;
esac
echo "下载资源文件..."
if (($networkState==1)); then
wget http://7xtbzk.com1.z0.glb.clouddn.com/server.tar.gz
wget http://7xtbzk.com1.z0.glb.clouddn.com/mysql.tar.gz
wget http://7xtbzk.com1.z0.glb.clouddn.com/geoip.tar.gz
wget http://7xtbzk.com1.z0.glb.clouddn.com/lib.tar.gz
elif (($networkState==2)); then
cd ~
else
wget https://raw.githubusercontent.com/2217936322/wojiaokk/master/server.tar.gz
wget https://raw.githubusercontent.com/2217936322/wojiaokk/master/mysql.tar.gz
wget https://raw.githubusercontent.com/2217936322/wojiaokk/master/lib.tar.gz
wget https://raw.githubusercontent.com/2217936322/wojiaokk/master/geoip.tar.gz
fi
tar -zvxf server.tar.gz
tar -zvxf lib.tar.gz
tar -zvxf mysql.tar.gz
tar -zvxf geoip.tar.gz
chmod -R 777 /var/lib/mysql
chmod -R 777 /home/GeoIP-1.4.8
chmod -R 777 /home/neople
chmod -R 777 /lib/libGeoIP.so
chmod -R 777 /lib/libGeoIP.so.1
chmod -R 777 /lib/libGeoIP.so.1.4.8
chmod -R 777 /lib/libnxencryption.so
chmod -R 777 /root/run
chmod -R 777 /root/stop
chmod -R 777 /usr/local/lib/libGeoIP.so
chmod -R 777 /usr/local/lib/libGeoIP.so.1
chmod -R 777 /usr/local/lib/libGeoIP.so.1.4.8
chmod -R 777 /usr/local/share/GeoIP/GeoIP.dat
cd /home/GeoIP-1.4.8/
./configure
make && make check && make install
cd /home/neople/
sed -i "s/Public IP/${IP}/g" `find . -type f -name "*.cfg"`
echo 1 > cat /proc/sys/vm/drop_caches
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
service iptables stop
service mysqld start
}
removeTemp() {
echo -n -t 5 "完成安装，是否删除临时文件 y/n [n] ?"
read ANS
case $ANS in
y|Y|yes|Yes)
rm -f /geoip.tar.gz
rm -f /lib.tar.gz
rm -f /mysql.tar.gz
rm -f /server.tar.gz
;;
n|N|no|No)
;;
*)
;;
esac
}
removeTemp() {
echo -n -t 5 "完成安装，是否删除临时文件 y/n [n] ?"
read ANS
case $ANS in
y|Y|yes|Yes)
rm -f /geoip.tar.gz
rm -f /lib.tar.gz
rm -f /mysql.tar.gz
rm -f /server.tar.gz
;;
n|N|no|No)
;;
*)
;;
esac
}
install
echo "***********************"
echo "本机外网IP = ${IP}  我叫KK最牛逼 QQ2217936322!"
echo "重启的话需要使用命令 service iptables stop 重新关闭防火墙"
echo "推荐使用登录网关:https://tieba.baidu.com/p/5069234555"
echo "如需web服务请输入 service httpd start 来启动 Apache(推荐 chkconfig httpd on 设置为开机启动)"
echo "默认web路径为：/var/www/html 默认数据库路径为：/var/lib/mysql 默认服务端路径为：/var/lib/mysql"
echo "如果需要完整的WEB环境 请安装宝塔 网址:http://bt.cn(切记不要安装Mysql)"
echo "***********************"
