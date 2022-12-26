#!/bin/bash
#sudo apt update -y
#sudo apt install awscli
s3_bucket="upgrad-karunesh"
myname="karunesh"
timestamp=$(date '+%d%m%Y-%H%M%S')

#shell script to install a apache2 package if not alreay installed
for package in apache2; do
    dpkg -s "$package" >/dev/null 2>&1 && {
        echo "$package is installed."
    } || {
        sudo apt-get install $package
    }
done

#Script to check if process is running and restart if not
service=apache
if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 ))
then
echo "$service is running!!!"
else
systemctl start apache2
echo "$service is started"
fi

#Tar the logs and copy to tmp folder
cd /var/log/apache2
tar cvf $myname-httpd-logs-$timestamp.tar *.log
cp *.tar /tmp/

#script should run the AWS CLI command and copy the archive to the s3 bucket
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar