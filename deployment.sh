#!/bin/bash
#
# The following script will do the deployment of all the required
# dependencies of the procurement pipeline project ETL.

echo "[PPP] Starting the initial deployment of the Procurement Pipeline Project."

# Variable loading
export $(xargs < ppp.env)

# set up the --defaults in az configure
az configure --defaults group=$RESOURCE_GROUP
az configure --defaults location=$LOCATION

# create the resource group
az group create -n $RESOURCE_GROUP --output none

echo "[PPP] Resource group with the name ${RESOURCE_GROUP} has been created"

# create a storage account
storage_id=$(az storage account create \
  -n $STORAGE_ACCOUNT \
  --sku Standard_LRS \
  --kind StorageV2 \
  --hns true \
  --query id \
  -o tsv)

echo "[PPP] Storage account with the name ${STORAGE_ACCOUNT} has been created."

# Setting up Azure AD for Blob and Queue storage
az ad signed-in-user show --query objectId -o tsv \
  | az role assignment create --role "Storage Blob Data Contributor" --assignee @- --scope $storage_id --output none
az ad signed-in-user show --query objectId -o tsv \
  | az role assignment create --role "Storage Queue Data Contributor" --assignee @- --scope $storage_id --output none

echo "[PPP] Roles have been assigned to user, now we wait 5 minutes..."

sleep 5m

# create a container / file system
for file_system in "deployment" "maintenance" "data-ready"; do
  az storage fs create \
    -n $file_system \
	--auth-mode login \
	--account-name $STORAGE_ACCOUNT \
  --output none

  echo "[PPP] Container ${file_system} has been created inside the storage account."
done

# create Queue
az storage queue create \
	--name $QUEUE_NAME \
	--account-name $STORAGE_ACCOUNT \
	--auth-mode login \
  --output none

echo "[PPP] Queue ${QUEUE_NAME} has been created"

cd ConvertData/

# run the Azure FunctionApp deployment script
bash deployment.sh

echo "[PPP] Files uploaded and converted using Azure FunctionApp"

# SQL DATABASE
cd ../Deploy-Azure-DB
# run the Azure SQL DB deployment script
bash deployment.sh

echo "[PPP] Transformed data has been uploaded into Azure SQL Database."

# Ansible Deployment
cd ../Material-Search/Material-Search-Processing
bash deployment.sh

echo "[PPP] Deployment done for material processing code with Ansible."

# Azure Machine Learning Deployment
cd ../Material-Search-Model-Deployment
bash deployment.sh

echo "[PPP] Completed!"


