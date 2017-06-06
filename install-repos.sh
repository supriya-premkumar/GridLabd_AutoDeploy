#!/bin/sh
set -x

# clone IEEE123 model in www folder
sudo mkdir -p /var/www/html
cd /var/www/html
sudo git clone https://github.com/dchassin/ieee123-aws
sudo cp -R ieee123-aws/* .
sudo rm -rf ieee123-aws/
sudo mkdir data output
sudo chmod -R 777 data output config
sudo chown -R apache.apache .

#install gridlabd
cd /home/ec2-user/gridlabd/source
autoreconf -isf
./customize configure
sudo make install
export PATH=/usr/local/bin:$PATH
gridlabd --validate

sudo sh -c "echo '[client]'>>/etc/my.cnf"
sudo sh -c "echo 'port=3306'>>/etc/my.cnf"
sudo sh -c "echo 'socket=/tmp/mysql.sock'>>/etc/my.cnf"
sudo sh -c "echo '[mysqld]'>>/etc/my.cnf"
sudo sh -c "echo 'port=3306'>>/etc/my.cnf"
sudo sh -c "echo 'datadir=/var/lib/mysql'>>/etc/my.cnf"
sudo sh -c "echo 'socket=/tmp/mysql.sock'>>/etc/my.cnf"

cd /etc/
sudo chmod 755 my.cnf #777 is not allowed - world writable. mysqld won't restart
# DONT DO THIS
#chown -R apache.apache .
##########################
cd /home/ec2-user
sudo service mysqld restart
# mysql
PASS=`pwgen -s 40 1`
set -xe
mysql -uroot <<MYSQL_SCRIPT
CREATE USER 'gridlabd'@'localhost' IDENTIFIED BY 'gridlabd';
GRANT ALL PRIVILEGES ON *.* TO 'gridlabd'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
CREATE USER 'gridlabd_ro'@'%' IDENTIFIED BY 'gridlabd';
GRANT SELECT ON *.* TO 'gridlabd_ro'@'%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

#start apache service
sudo service httpd start
# systemctl start httpd # on RHEL 7 only
