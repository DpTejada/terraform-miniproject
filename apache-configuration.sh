#!/bin/bash
sudo yum install -y httpd
sudo yum install -y wget
cd /var/www/html
sudo wget https://devops14-mini-project.s3.amazonaws.com/default/index-default.html
sudo wget https://devops14-mini-project.s3.amazonaws.com/default/mycar.jpeg
sudo mv index-default.html index.html
sudo systemctl enable httpd --now 
