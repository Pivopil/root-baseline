#!/bin/sh

SERVICE_NAME="springbootapp"
SERVICE_TAG="v1"
ECR_REPO_URL="905265942603.dkr.ecr.us-east-1.amazonaws.com/${SERVICE_NAME}"

if [ "$1" = "build" ];then
    echo "Building the application..."
    cd ..
    mvn clean install
elif [ "$1" = "dockerize" ];then
    find ./target/ -type f \( -name "*.jar" -not -name "*sources.jar" \) -exec cp {} ./$SERVICE_NAME.jar \;
    $(aws ecr get-login --no-include-email --region us-east-1)
    aws ecr create-repository --repository-name ${SERVICE_NAME:?} || true
    docker build -t ${SERVICE_NAME}:${SERVICE_TAG} .
    docker tag ${SERVICE_NAME}:${SERVICE_TAG} ${ECR_REPO_URL}:${SERVICE_TAG}
    docker push ${ECR_REPO_URL}:${SERVICE_TAG}
fi
