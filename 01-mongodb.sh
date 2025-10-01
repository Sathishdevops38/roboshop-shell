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

mkdir -p $Logs_Folder
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo -e "$R ERROR:: $N Please run this script with root privelege"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo 
validate $? "copying files"

dnf install mongodb-org -y &>>$Logs_File
validate $? "install mongo server" 

systemctl enable mongod &>>$Logs_File
validate $? "enabling mongo service"

systemctl start mongod 
validate $? "Starting mongo service"

sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf
validate $? "modified the mongo config file"

systemctl restart mongod
validate $? "Restarted MongoDB"
