#!/bin/bash

echo "**************"
echo "Building Docker image"
echo -e "**************\n"
docker build -t knightpath_result:latest .
echo -e "\n**************"
echo "Logging into AWS"
echo -e "**************\n"
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 756098610160.dkr.ecr.us-east-2.amazonaws.com
echo -e "\n**************"
echo "Tagging image"
echo -e "**************\n"
docker tag knightpath_result:latest 756098610160.dkr.ecr.us-east-2.amazonaws.com/knightpath_result:latest
echo -e "\n**************"
echo "Pushing to ECR"
echo -e "**************\n"
docker push 756098610160.dkr.ecr.us-east-2.amazonaws.com/knightpath_result:latest
echo -e "\n**************"
echo "Updating function code"
echo -e "**************\n"
aws lambda update-function-code --function-name knightpath_result_lambda --image-uri $(aws lambda get-function --function-name knightpath_result_lambda | jq -r '.Code.ImageUri')