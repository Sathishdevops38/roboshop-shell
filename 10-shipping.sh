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
MYSQL_HOST=mysql.daws38sat.fun

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

dnf install maven -y &>>$Logs_File
validate $? "Install maven"

id roboshop

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "User created"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir /app 

if [ $? -ne 0 ]; then
    echo -e "app folder already exists .. $Y SKIPPING$N"
else
    validate $? "Creating app directory"
fi

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
validate $? "Downloading zip files"

cd /app 
validate $? "Changing to app directory"

unzip /tmp/shipping.zip
validate $? "Unzipping files"

cd /app 
validate $? "Changing to app directory"

mvn clean package 
validate $? "Install and create artifact"

mv target/shipping-1.0.jar shipping.jar 
validate $? "Renaming artifact"

cp $SCRIPT_DIR/shipping.repo /etc/systemd/system/shipping.service
validate $? "Copying files"

systemctl daemon-reload
validate $? "Daemon reloaded"

systemctl enable shipping
validate $? "enabling shipping service"

systemctl start shipping
validate $? "starting shipping service"

dnf install mysql -y  &>>$Logs_File

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$Logs_File
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$Logs_File
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$Logs_File
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$Logs_File
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
