#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


USER_ID=$(id -u)
Logs_Folder="/var/log/shell-roboshop"
Script_Name=$(echo $0 | cut -d "." -f1 )
Logs_File="$Logs_Folder/$Script_Name.log"
SCRIPT_DIR=$PWD

#check the script is executing by Root user not 
if [ $USER_ID -ne 0 ]; then
    echo -e "$R ERRROR$N:: Run the script with root privillages"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 --- $R Failure $N"
        exit 1
    else
        echo -e "$2--- $G Success $N"
    fi
}

####Redis#####
dnf module disable redis -y
validate $? "Disable default redis package"

dnf module enable redis:7 -y
validate $? "Enable redis 7"

dnf install redis -y &>>$Logs_File
validate $? "Install redis"

sed -i -e 's/127.0.0.0/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf

systemctl enable redis &>>$Logs_File
validate $? "Enabling Redis"
systemctl start redis &>>$Logs_File
validate $? "Starting Redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"