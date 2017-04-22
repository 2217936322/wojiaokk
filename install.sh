#!/bin/sh

#  installDNF-CentOS6-KK.sh
#  我叫KK  最牛逼
#  QQ 2217936322

function install() {
    echo "我叫KK最牛逼 CentOS7.X版本正在内测中！"
    read -p "输入系统版本，例如CentOS 5.11，输入5，然后回车：" versionNumber
#TODO:直接取系统版本号判断，再检测文件是否存在，不符合都跳出
    read -p "输入服务器环境，1位 国内 (可以自动下载服务端文件) 2为国外(可以自动下载服务端文件)，3为自带Server.tar.gz及证书及pvf文件(此项开始前要确保根目录下存在Server.tar.gz、publickey.pem、Script.pvf)默认选3，然后回车：" networkState
    if (($versionNumber==5)); then
        installSupportLibOnCentOS5
    elif (($versionNumber==6)); then
        installSupportLibOnCentOS6
    else
        echo "正式版本仅支持CentOS5.X和6.X！CentOS7.X内测请联系我叫KK."
        exit 0
    fi
    echo "添加交换空间，耐心等待⌛……"
    addSwap
    installDOF
    deleteRoot6686
    removeTemp
}

function getIP() {
    echo "获取 IP..."
    IP=`curl -s http://v4.ipv6-test.com/api/myip.php`
    if [ -z $IP ]; then
    IP=`curl -s https://www.boip.net/api/myip`
    fi
}

function addSwap() {
    echo "添加 Swap..."
#   if read -n1 -p "请输入虚拟内存大小（正整数、单位为GB、默认6  GB）" answer
#   then
#   /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1000*$answer
    /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=8000
    mkswap /var/swap.1
    swapon /var/swap.1
#   加入开机自动挂载
#   $ 最后一行
#   a 在该指令前面的行数后面插入该指令后面的内容
    sed -i '$a /var/swap.1 swap swap default 0 0' /etc/fstab
    echo "添加 Swap 成功"
}

function installSupportLibOnCentOS5() {
    echo "安装运行库..."
    if (($networkState==3)); then
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-5.repo
        yum clean all
        yum makecache
    fi
    yum -y update
    yum -y upgrade
    yum install -y mysql mysql-server mysql-devel
    yum -y install gcc gcc-c++ make zlib-devel libc.so.6 libstdc++ glibc.i686
#   添加到开机自启动
    chkconfig mysqld on
    service mysqld start
    service mysqld stop
}

function installSupportLibOnCentOS6() {
    echo "安装运行库..."
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

function installDOF() {
    getIP
    echo -n "${IP} 是否是你的外网IP？(如果不是你的外网IP或者出现两条IP地址，请回 n 自行输入) y/n [n] ?"
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
    echo "下载Server..."
    if (($networkState==1)); then
		#七牛
		wget http://7xtbzk.com1.z0.glb.clouddn.com/server.tar.gz
		wget http://7xtbzk.com1.z0.glb.clouddn.com/mysql.tar.gz
		wget http://7xtbzk.com1.z0.glb.clouddn.com/geoip.tar.gz
		wget http://7xtbzk.com1.z0.glb.clouddn.com/lib.tar.gz
    elif (($networkState==2)); then
        cd ~
    else
        wget -O /Server.tar.gz https://www.dropbox.com/s/9fz5grju3xf2q8c/Server.tar.gz?dl=0
        wget -O /Script.pvf https://www.dropbox.com/s/ofu0d6owm6h3igy/Script.pvf?dl=0
        wget -O /publickey.pem https://www.dropbox.com/s/u2q0s5t56wvkk7l/publickey.pem?dl=0
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
	
	
    echo "添加防火墙端口..."
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8000 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 10013 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 30303 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 30403 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 10315 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 30603 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 20203 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 7215 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 20303 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 40401 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 30803 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 20403 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 31100 -j ACCEPT' /etc/sysconfig/iptables
#   端口不全，这里先把防火墙关了
    service iptables stop
#   TODO:关闭防火墙自启动
    service mysqld start
}

function deleteRoot6686() {
    HOSTNAME="127.0.0.1"
    PORT="3306"
    USERNAME="game"
    PASSWORD="uu5!^%jg"
    DBNAME="mysql"
    TABLENAME="user"
    refresh="flush privileges;";
    delete_user_root6686="delete from mysql.user where user='root9326686' and host='%';"
#  delete_user_cash="delete from mysql.user where user='cash' and host='127.0.0.1';"
    mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${delete_user_root6686}"
#  mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${delete_user_cash}"
    mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${refresh}"
}

function removeTemp() {
    echo -n -t 5 "完成安装，是否删除临时文件 y/n [n] ?"
    read ANS
    case $ANS in
    y|Y|yes|Yes)
    rm -f /root/mysql57*
    rm -f /var.tar.gz
    rm -f /etc.tar.gz
    rm -f /Server.tar.gz
    ;;
    n|N|no|No)
    ;;
    *)
    ;;
    esac
}

install
echo "***********************"
echo " IP = ${IP}"
echo "重启的话需要使用命令 service iptables stop 重新关闭防火墙"
echo "***********************"