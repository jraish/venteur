#!/bin/bash

echo "**************"
echo "Building Docker image"
echo -e "**************\n"
docker build -t knightpath:latest .
echo -e "\n**************"
echo "Logging into AWS"
echo -e "**************\n"
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <AWS ACCOUNT NUMBER>.dkr.ecr.us-east-2.amazonaws.com
echo -e "\n**************"
echo "Tagging image"
echo -e "**************\n"
docker tag knightpath:latest <AWS ACCOUNT NUMBER>.dkr.ecr.us-east-2.amazonaws.com/knightpath:latest
echo -e "\n**************"
echo "Pushing to ECR"
echo -e "**************\n"
docker push <AWS ACCOUNT NUMBER>.dkr.ecr.us-east-2.amazonaws.com/knightpath:latest
echo -e "\n**************"
echo "Updating function code"
echo -e "**************\n"
aws lambda update-function-code --function-name knightpath_lambda --image-uri $(aws lambda get-function --function-name knightpath_lambda | jq -r '.Code.ImageUri') 1> /dev/null