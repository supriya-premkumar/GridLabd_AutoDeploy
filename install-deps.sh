#!/bin/bash
set -xe

sudo yum update -y
sudo yum install git -y
sudo yum install httpd -y
sudo yum install php -y
sudo yum install cmake -y #this is a requirement for armadillo - linear algebra library
sudo yum groupinstall "Development Tools" -y

cd /home/ec2-user
#install MySql Server
sudo yum install https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm -y
sudo yum install mysql56-server -y # for Amazon linux

#install MySql Connector
wget https://dev.mysql.com/get/Downloads/Connector-C/mysql-connector-c-6.1.9-linux-glibc2.5-x86_64.tar.gz
tar xf mysql-connector-c-6.1.9-linux-glibc2.5-x86_64.tar.gz
cd mysql-connector-c-6.1.9-linux-glibc2.5-x86_64/
sudo cp bin/* /usr/local/bin
sudo cp -R include/* /usr/local/include
sudo cp -R lib/* /usr/local/lib
sudo yum install mysql-libs -y

#test MySQL Service
sudo service mysqld start
sudo service mysqld stop

#copy gridlab source and install lib-xercesc
cd /home/ec2-user
mkdir gridlabd
cd gridlabd
git clone https://github.com/supriya-premkumar/gridlabd source
cd /home/ec2-user/gridlabd/source/third_party/
. install_xercesc 

#install armadillo - C++ linear algebra library
cd /home/ec2-user
wget http://sourceforge.net/projects/arma/files/armadillo-7.800.1.tar.xz
tar xf armadillo-7.800.1.tar.xz
rm -f armadillo-7.800.1.tar.xz
cd armadillo-7.800.1
cmake .
sudo make install
