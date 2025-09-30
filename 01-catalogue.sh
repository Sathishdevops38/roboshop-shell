#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


USER_ID= $(id -u)
Logs_Folder="/var/log/shell-roboshop"
Script_Name=$(echo $0 | cut -d "." -f1 )
Logs_File="$Logs_Folder/$Script_Name.log"

#check the script is executing by Root user not 
if [ $USER_ID -ne 0]; then
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

###NODE JS####
dnf module disable nodejs -y &>>$Logs_File
validate $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$Logs_File
validate $? "enableing NodeJS 20"

dnf install nodejs -y &>>$Logs_File
validate $? "Installing NodeJS"

id roboshop &>>$Logs_File

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating system user"
else
    echo --e "User already exist ... $Y SKIPPING $N"
fi

mkdir /app
validate $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
validate $? "Downloading catalogue application"

cd /app 
validate $? " changing to app directory"

rm -rf /app/*
validate $? "Remove existing code"

unzip /tmp/catalogue.zip
validate $? "Unzip catalogue"

npm install 
validate $? "Install dependincies"

cp catalogue-service /etc/systemd/system/catalogue.service
validate $? "Copying catalogue service files"

systemctl daemon-reload
validate $? "Reload demon"

systemctl enable catalogue 
validate $? "Enabling catalogue service"

systemctl start catalogue
validate $? "Starting catalogue service"

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copying mongo files"

dnf install mongodb-mongosh -y &>>$Logs_File
validate $? " Install mongsh client"


INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"

