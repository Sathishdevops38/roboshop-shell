#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USER_ID=$(id -u)
Logs_Folder="/var/log/shell-roboshop"
Script_Name=$(echo $0 | cut -d "." -f1 )
Logs_File="$Logs_Folder/$Script_Name.log"
START_TIME=$(date +%s)
SCRIPT_DIR=$PWD

mkdir -p $Logs_Folder
echo "Script started executed at: $(date)" | tee -a $Logs_File

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

dnf install golang -y &>>$Logs_File
validate $? "Install golang"

id roboshop

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir /app
if [ $? -ne 0 ]; then
    echo -e "app folder already exists .. $Y SKIPPING$N"
else
    validate $? "Creating app directory"
fi

cd /app 
validate $? "Changing to app directory"

go mod init dispatch &>>$Logs_File
validate $? "Intialize go"

go get &>>$Logs_File
validate $? "Get"

go build &>>$Logs_File
validate $? "Build"

cp $SCRIPT_DIR/dispatch.repo /etc/systemd/system/dispatch.service
validate $? "Copying files"

systemctl daemon-reload
validate $? "Daemon reloaded"

systemctl enable dispatch
validate $? "enabling dispatch service"

systemctl start dispatch
validate $? "starting dispatch service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"