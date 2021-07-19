#!/bin/bash

echo "Starting the deployment..."

# initial variables
resourceGroup="DataScienceThesisRG"
location="westeurope"
storageAccount="dsthesissa"

# create the resource group
az group create -n $resourceGroup -l $location

# set up the --defaults in az configure
az configure --defaults group=$resourceGroup
az configure --defaults location=$location

# create a storage account
az storage account create \
	-n $storageAccount \
	--sku Standard_LRS \
	--hns true  # ADLS setting


storageID=$(az storage account show -n $storageAccount --query id -o tsv)

# setting up Azure AD for Blob and Queue storage
az ad signed-in-user show --query objectId -o tsv | az role assignment create --role "Storage Blob Data Contributor" --assignee @- --scope $storageID
az ad signed-in-user show --query objectId -o tsv | az role assignment create --role "Storage Queue Data Contributor" --assignee @- --scope $storageID

sleep 5m

# setting up AZCopy
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
mv ./azcopy_linux_amd64_*/azcopy .
rm -r downloadazcopy-v10-linux ./azcopy_linux_amd64_*

# create a container / file system
az storage fs create \
	-n raw-data \
	--auth-mode login \
	--account-name $storageAccount

az storage fs create \
	-n data-ready \
	--auth-mode login \
	--account-name $storageAccount

# save the previous data in another folder
az storage fs create \
	-n old-ready \
	--auth-mode login \
	--account-name $storageAccount


echo "Uploading files to storage"

# sas code setting up to transfer files
end=$(date -u -d "200 minutes" '+%Y-%m-%dT%H:%MZ')
sas=$(az storage account generate-sas --permissions cdlruwap --account-name $storageAccount --services b --resource-types sco --expiry $end -o tsv)

# copy all files from raw-data/ folder
./azcopy copy "data/raw-data/*" "https://${storageAccount}.dfs.core.windows.net/raw-data/?${sas}" --recursive

echo "Now for the Queues..."

# setting up the queue storage
queueName="uploadedfiles"

# create Queue
az storage queue create \
	--name $queueName \
	--account-name $storageAccount \
	--auth-mode login

cd ConvertData/

# run the Azure FunctionApp deployment script
bash deploy_script.sh

echo "Creating and Populating SQL Database"

# SQL DATABASE
cd ../Deploy-Azure-DB

# run the Azure SQL DB deployment script
bash deploy_script.sh

echo "Completed!"


