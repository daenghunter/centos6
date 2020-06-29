#!/bin/bash
# https://metanux.id/mengatasi-error-cannot-retrieve-metalink-for-repository-epel-please-verify-its-path-and-try-again/
# nano /etc/yum.repos.d/epel.repo

# initialisasi var
export CENTOS_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

#detail nama perusahaan
country=ID
state=Indonesia
locality=Indonesia
organization=www.vpnstores.my.id
organizationalunit=www.vpnstores.my.id
commonname=www.vpnstores.my.id
email=admin@vpnstores.my.id

# simple password minimal
wget --no-check-certificate -O /etc/pam.d/system-auth "https://raw.githubusercontent.com/marloxxx/centos6/master/pwd-vultr"

# go to root
cd
setenforce 0

cat > /etc/sysconfig/selinux <<-END
SELINUX=disabled
END
sestatus

# setting DNS resoled
cat > /etc/resolv.conf <<-END
nameserver 1.1.1.1
nameserver 1.0.0.1
END

# disable se linux
echo 0 > /selinux/enforce
sed -i 's/SELINUX=enforcing/SELINUX=disable/g'  /etc/sysconfig/selinux

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service sshd restart

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.d/rc.local

# install wget and curl
yum -y install wget curl

# setting repo centos 64bit
wget https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh epel-release-6-8.noarch.rpm

# setting rpmforge
wget http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

sed -i 's/enabled = 1/enabled = 0/g' /etc/yum.repos.d/rpmforge.repo
sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
rm -f *.rpm

# remove unused
yum -y remove sendmail;
yum -y remove httpd;
yum -y remove cyrus-sasl

# update
yum -y update

# install webserver
yum -y install nginx php-fpm php-cli
service nginx restart
service php-fpm restart
chkconfig nginx on
chkconfig php-fpm on

# install essential package
yum -y install rrdtool screen iftop htop nmap bc nethogs openvpn vnstat ngrep mtr git zsh mrtg unrar rsyslog rkhunter mrtg net-snmp net-snmp-utils expect nano bind-utils
yum -y groupinstall 'Development Tools'
yum -y install cmake
yum -y --enablerepo=rpmforge install axel sslh ptunnel unrar

# matiin exim
service exim stop
chkconfig exim off

# install webserver
cd
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/marloxxx/centos6/master/nginx.conf"
sed -i 's/www-data/nginx/g' /etc/nginx/nginx.conf
mkdir -p /home/vps/public_html
echo "<pre>Setup By Horasss</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
rm /etc/nginx/conf.d/*
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/marloxxx/centos6/master/vps.conf"
sed -i 's/apache/nginx/g' /etc/php-fpm.d/www.conf
chmod -R +rx /home/vps
service php-fpm restart
service nginx restart

# setting port ssh
cd
wget -O /etc/bannerssh.txt "https://raw.githubusercontent.com/marloxxx/centos6/master/banner.conf"
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port  22/g' /etc/ssh/sshd_config

# set sshd banner
wget -O /etc/ssh/sshd_config "https://raw.githubusercontent.com/marloxxx/centos6/master/sshd.conf"
service sshd restart
chkconfig sshd on

# install dropbear
yum -y install dropbear
echo "OPTIONS=\"-b /etc/bannerssh.txt -p 109 -p 456\"" > /etc/sysconfig/dropbear
echo "/bin/false" >> /etc/shells

# limite login dropbear 
service dropbear restart
chkconfig dropbear on
service iptables save
service iptables restart
chkconfig iptables on

# install vnstat gui
vnstat -u -i eth0
echo "MAILTO=root" > /etc/cron.d/vnstat
echo "*/5 * * * * root /usr/sbin/vnstat.cron" >> /etc/cron.d/vnstat
service vnstat restart
chkconfig vnstat on

# install fail2ban
cd
yum -y install fail2ban
service fail2ban restart
chkconfig fail2ban on

# install squid
yum -y install squid
wget --no-check-certificate -O /etc/squid/squid.conf "https://raw.githubusercontent.com/marloxxx/centos6/master/squid.conf"
sed -i $MYIP2 /etc/squid/squid.conf;
service squid restart
chkconfig squid on

# install neofetch centos 6 64bit
git clone https://github.com/dylanaraps/neofetch
cd neofetch
make install
make PREFIX=/usr/local install
make PREFIX=/boot/home/config/non-packaged install
make -i install
cd
echo "clear" >> .bash_profile
echo "neofetch" >> .bash_profile
echo "echo by Horasss" >> .bash_profile

# install webmin
#cd
#wget --no-check-certificate http://prdownloads.sourceforge.net/webadmin/webmin-1.831-1.noarch.rpm
#yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty
#rpm -U webmin*
#rm -f webmin*
#sed -i -e 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
#service webmin restart
#chkconfig webmin on

# install stunnel
yum -y install stunnel

cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 443
connect = 127.0.0.1:109

[dropbear]
accept = 777
connect = 127.0.0.1:109

[dropbear]
accept = 222
connect = 127.0.0.1:109

[dropbear]
accept = 990
connect = 127.0.0.1:109

END

# make a certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# Pasang Config Stunnel centos
cd /usr/bin
wget -O /etc/rc.d/init.d/stunnel "https://raw.githubusercontent.com/marloxxx/centos6/master/ssl.conf"
chmod +x /etc/rc.d/init.d/stunnel
service stunnel start
chkconfig stunnel on
cd

# install badvpn centos
yum -y install update
yum -y install wget
yum -y install unzip
yum -y install git
yum -y install make
yum -y install cmake
yum -y install gcc
yum -y install screen

# buat directory badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/marloxxx/centos6/master/badvpn-udpgw64"
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 10' /etc/rc.local
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 10' /etc/rc.d/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 10 

cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/marloxxx/centos6/master/badvpn-udpgw64"
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10' /etc/rc.local
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10' /etc/rc.d/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10 

# Sett iptables badvpn
iptables -A INPUT -i eth0 -m state --state NEW -p tcp --dport 7200 -j ACCEPT
iptables -A INPUT -i eth0 -m state --state NEW -p tcp --dport 7300 -j ACCEPT
service iptables save

# Save & restore IPTABLES Centos 6 64bit
wget -O /etc/iptables.up.rules "https://raw.githubusercontent.com/marloxxx/centos6/master/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.d/rc.local
MYIP=`curl icanhazip.com`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
sed -i $MYIP2 /etc/iptables.up.rules;
sed -i 's/venet0/eth0/g' /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
sysctl -w net.ipv4.ip_forward=1
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
cp /etc/sysconfig/iptables /etc/iptables.up.rules
chmod +x /etc/iptables.up.rules
service iptables restart
cd

# permition rc local
chmod +x /etc/rc.local
chmod +x /etc/rc.d/rc.local

# download script
cd /usr/bin
wget -O menu "https://raw.githubusercontent.com/marloxxx/centos6/master/menu.sh"
wget -O usernew "https://raw.githubusercontent.com/marloxxx/centos6/master/usernew.sh"
wget -O trial "https://raw.githubusercontent.com/marloxxx/centos6/master/trial.sh"
wget -O hapus "https://raw.githubusercontent.com/marloxxx/centos6/master/hapus.sh"
wget -O member "https://raw.githubusercontent.com/marloxxx/centos6/master/member.sh"
wget -O delete "https://raw.githubusercontent.com/marloxxx/centos6/master/delete.sh"
wget -O cek "https://raw.githubusercontent.com/marloxxx/centos6/master/cek.sh"
wget -O resvis "https://raw.githubusercontent.com/marloxxx/centos6/master/restart.sh"
wget -O speedtest "https://raw.githubusercontent.com/marloxxx/centos6/master/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/marloxxx/centos6/master/info.sh"
wget -O about "https://raw.githubusercontent.com/marloxxx/centos6/master/about.sh"

echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

chmod +x menu
chmod +x usernew
chmod +x trial
chmod +x hapus
chmod +x member
chmod +x delete
chmod +x cek
chmod +x resvis
chmod +x speedtest
chmod +x info
chmod +x about

# cron
cd
service crond start
chkconfig crond on
service crond stop

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# finalisasi
chown -R nginx:nginx /home/vps/public_html
/etc/init.d/nginx restart
/etc/init.d/php-fpm restart
/etc/init.d/vnstat restart
/etc/init.d/snmpd restart
/etc/init.d/sshd restart
/etc/init.d/dropbear restart
/etc/init.d/stunnel restart
/etc/init.d/squid restart
/etc/init.d/webmin restart
/etc/init.d/fail2ban restart
/etc/init.d/crond restart
service iptables restart
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 10 
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10 
chkconfig crond on

# info
echo "Informasi Penggunaan SSH" | tee log-install.txt
echo "===============================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Layanan yang diaktifkan"  | tee -a log-install.txt
echo "--------------------------------------"  | tee -a log-install.txt
echo "Client Config  : http://$MYIP:81/1194-client.ovpn)"  | tee -a log-install.txt
echo "Port OpenSSH   : 22, 143"  | tee -a log-install.txt
echo "Port Dropbear  : 109, 456"  | tee -a log-install.txt
echo "Squid          : 80, 3128, 8080 (limit to IP SSH)"  | tee -a log-install.txt
echo "badvpn         : 7200/7300"  | tee -a log-install.txt
echo "Webmin         : http://$MYIP:10000/"  | tee -a log-install.txt
echo "Timezone       : Asia/Jakarta"  | tee -a log-install.txt
echo "Fail2Ban       : [on]"  | tee -a log-install.txt
echo "IPv6           : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt

echo "Tools"  | tee -a log-install.txt
echo "-----"  | tee -a log-install.txt
echo "axel"  | tee -a log-install.txt
echo "bmon"  | tee -a log-install.txt
echo "htop"  | tee -a log-install.txt
echo "iftop"  | tee -a log-install.txt
echo "mtr"  | tee -a log-install.txt
echo "nethogs"  | tee -a log-install.txt
echo "" | tee -a log-install.txt

echo "menu (Displays a list of available commands)"  | tee -a log-install.txt
echo "usernew (Creating an SSH Account)"  | tee -a log-install.txt
echo "trial (Create a Trial Account)"  | tee -a log-install.txt
echo "hapus (Clearing SSH Account)"  | tee -a log-install.txt
echo "cek (Check User Login)"  | tee -a log-install.txt
echo "member (Check Member SSH)"  | tee -a log-install.txt
echo "resvis (Restart Service dropbear, webmin, squid3, openvpn and ssh)"  | tee -a log-install.txt
echo "reboot (Reboot VPS)"  | tee -a log-install.txt
echo "speedtest (Speedtest VPS)"  | tee -a log-install.txt
echo "info (System Information)"  | tee -a log-install.txt
echo "about (Information about auto install script)"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Mod By Horasss"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "==============================================="  | tee -a log-install.txt

rm -f /root/cen.sh

# finihsing
clear
neofetch
netstat -ntlp
