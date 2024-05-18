#!/bin/bash

# Exit in case of error
set -e

# # Ensure script is executed in the root of the Git repository
# if [ ! -d .git ]; then
#     echo "This script should be run from the root of the Git repository."
#     exit 1
# fi

# Commit your code changes
git add ..
git commit -m "project"

# Get the short hash of the latest commit
TAG=$(git rev-parse --short HEAD)

# Define image properties
IMAGE_NAME="project"
ACR_DOMAIN="w255mids.azurecr.io"
IMAGE_PREFIX=$(az account list --all | jq '.[].user.name' | grep -i berkeley.edu | awk -F@ '{print $1}' | tr -d '"' | tr -d "." | tr '[:upper:]' '[:lower:]' | tr '_' '-' | uniq)
IMAGE_FQDN="${ACR_DOMAIN}/${IMAGE_PREFIX}/${IMAGE_NAME}:${TAG}"

# Building Docker Image for AMD64 architecture
docker build --platform linux/amd64 -t ${IMAGE_NAME}:${TAG} ./mlapi

# Log in to Azure Container Registry
az acr login --name w255mids

# Push the image to ACR
docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_FQDN}
docker push ${IMAGE_FQDN}

# Update the Kubernetes deployment file with the new image tag
sed "s/\[TAG\]/${TAG}/g" .k8s/overlays/prod/patch-deployment-project_copy.yaml > .k8s/overlays/prod/patch-deployment-project.yaml

# Apply the updated deployment
kubectl kustomize .k8s/overlays/prod
kubectl apply -k .k8s/overlays/prod

echo "Image ${IMAGE_FQDN} successfully built and pushed to ACR. Deployment updated."


# Access the API endpoint
NAMESPACE=${IMAGE_PREFIX}

kubectl wait --for=condition=ready pod -l app=project --timeout=300s -n ${NAMESPACE}

echo "Testing '/project-predict' endpoint"
curl -X 'POST' "https://${NAMESPACE}.mids255.com/project-predict" -L -H 'Content-Type: application/json' -d '{"text": ["I love you", "I hate you"]}'

# echo "Testing '/bulk_predict' endpoint"
# curl -X 'POST' "https://${NAMESPACE}.mids255.com/bulk_predict" -L -H 'Content-Type: application/json' -d '{"houses": [{ "MedInc": 8.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 }]}'

# cleanup
# kubectl delete -k .k8s/overlays/prod

docker rmi ${IMAGE_FQDN}
docker rmi "${IMAGE_NAME}:${TAG}"