#!/bin/bash
echo "installing requirements"
yum -y install epel-release 2> /dev/null
yum -y install python-pip 2> /dev/null
pip install Flask  2> /dev/null
yum -y install python-memcached 2> /dev/null
yum -y install python-flask 2> /dev/null
###########################################
echo "Instsalling apache"
yum -y install httpd
###########################################
echo "installing mod_ssl"
yum -y install mod_ssl
 ###########################################     
echo "HTTP to HTTPS redirection"
if grep "redirection-from-http-to-https" /etc/httpd/conf/httpd.conf &> /dev/null
then
echo "redirection already set"
else
echo '''
#redirection-from-http-to-https
RewriteEngine On 
RewriteCond %{HTTPS}  !=on 
RewriteRule ^/?(.*) https://%{SERVER_NAME}:8443/$1 [R,L]
''' >> /etc/httpd/conf/httpd.conf
fi
###########################################
echo "Configure apache to run app"
yum -y install mod_wsgi 2> /dev/null
###########################################

sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/sysconfig/selinux
setenforce 0
###########################################

if grep "app-settings" /etc/httpd/conf/httpd.conf &> /dev/null 
then
echo "app is already configured"
else
echo '''
#app-settings
WSGIDaemonProcess app threads=5
WSGIScriptAlias /app /var/www/html/app/app.wsgi

<Directory /var/www/html/app>
    WSGIProcessGroup app
    WSGIApplicationGroup %{GLOBAL}
    WSGIScriptReloading On
    Order deny,allow
    Allow from all
</Directory>
WSGISocketPrefix /tmp/akshay
''' >> /etc/httpd/conf/httpd.conf
fi
###########################################

echo "start apache"
chkconfig httpd on
service httpd start 2> /dev/null
###########################################

echo "Ensuring apache is running"
service httpd status
###########################################

echo "Installing app"
unzip /vagrant/app.zip -d /var/www/html/
###########################################

echo "Installing Memcached"
yum -y install memcached
###########################################

echo "Starting Memcached service"
chkconfig memcached on
service memcached start
###########################################

echo "Ensuring Memcached is running"
service memcached status
###########################################

echo "Write / Read some data to memcache"
yum -y install nc
bash /vagrant/read_write.sh &> /dev/null
###########################################

echo "Adding cron /home/vagrant/exercise-memcached.sh"
cp -f /vagrant/exercise-memcached.sh /home/vagrant/exercise-memcached.sh
chmod a+x /home/vagrant/exercise-memcached.sh
( crontab -l 2> /dev/null ; echo "* * * * * /home/vagrant/exercise-memcached.sh") | crontab -
###########################################

echo "Done!!!"
###########################################