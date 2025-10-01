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


dnf module disable nodejs -y &>>$Logs_File
validate $? "Disable default nodejs package"

dnf module enable nodejs:20 -y &>>$Logs_File
validate $? "Enable nodejs 20"

dnf install nodejs -y &>>$Logs_File
validate $? "Install nodejs 20"


id roboshop &>>$Logs_File

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir /app &>>$Logs_File
if [ $? -ne 0 ]; then
    echo -e "app folder already exists .. $Y SKIPPING$N"
else
    validate $? "Creating app directory"
fi

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
validate $? "Downloading zip files"

cd /app 
validate $? "Changing to app directory"

unzip /tmp/cart.zip &>>$Logs_File
validate $? "Unzipping files"

cd /app 
validate $? "Changing to app directory"

npm install &>>$Logs_File
validate $? "Installing dependencies"

cp $SCRIPT_DIR/cart.repo /etc/systemd/system/cart.service
validate $? "Copying service files"

systemctl daemon-reload
validate $? "Daemon reloaded"

systemctl enable cart
validate $? "enabling cart service"

systemctl start cart
validate $? "starting cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"