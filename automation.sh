#!/bin/bash
sudo apt update -y
sudo apt install awscli
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

#Check if the file inventory.html exists in the /var/www/html folder , if not found, creates it.
cd /var/www/html
File="inventory.html"
if test -f "$File"; then
echo "$File exist"
else
touch "$File"
chmod +x "$File"
fi

#Check if inventory file is empty file, if its >=1 line that means headers are present
cd /var/www/html
File="inventory.html"
if [ -s "$File" ]; then
echo "Headers already present"
else
#Add headers to the html file
echo "headers to be added to the Inventory"
echo "Log Type	Time Created	Type	Size" > "$File"
fi

#Create Entry in the inventory html file
cd /tmp/
#Get the tar files Date created from the tmp folder after every run of the script
field2=`ls -lrth /tmp | tail -1 | awk -F ' ' '{print $9}' | cut -d '-' -f 4,5 | cut -f1 -d '.'`
#Get the size from the tmp folder for the latest tar files, after end of the script
field4=`ls -lrth /tmp | tail -1 | awk -F ' ' '{print $5}'`

#Append line to the File inventory.html
filename="inventory.html"
path="/var/www/html"
echo "httpd-logs	$field2	tar	$field4" >> $path/$filename

#Add crontab to the list for scheduling jobs
if (( $(crontab -l | grep "automation" | wc -l) >0 ))
then
echo "Cron is alredy setup"
else
echo "Setting the cronjob for automation daily schedule"
cat <(crontab -l) <(echo "55 23 * * * /root/Automation_Project/automation.sh") | crontab -
fi

echo "Script Completed"