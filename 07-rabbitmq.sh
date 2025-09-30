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

dnf install rabbitmq-server -y &>>$Logs_File
validate $? "Install rabbitmq"

systemctl enable rabbitmq-server
validate $? "Enableing rabbitmq service"

systemctl start rabbitmq-server
validate $? "Starting rabbitmq-service"


rabbitmqctl add_user roboshop roboshop123 &>>$Logs_File
validate $? "Create user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$Logs_File
validate $? "Set permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"