#!/bin/bash
#
# The following script will do the deployment all the required
# dependencies of the procurement pipeline project. This includes
# * ETL initial deployment
# * Material Search App deployment including both processing machines
# * Azure Databricks deployment for price forecasting

echo "Starting the initial deployment of the Procurement Pipeline Project"

# Variable loading
export $(xargs < ppp.env)

# set up the --defaults in az configure
az configure --defaults group=$RESOURCE_GROUP
az configure --defaults location=$LOCATION

# create the resource group
az group create -n $RESOURCE_GROUP

# create a storage account
az storage account create \
  -n $STORAGE_ACCOUNT \
  --sku Standard_LRS \
  --kind StorageV2 \
  --hns true  # ADLS setting

# Get the storage id for role assignment
storage_id=$(az storage account show -n $STORAGE_ACCOUNT --query id -o tsv)

# Setting up Azure AD for Blob and Queue storage
az ad signed-in-user show --query objectId -o tsv \
  | az role assignment create --role "Storage Blob Data Contributor" --assignee @- --scope $storage_id
az ad signed-in-user show --query objectId -o tsv \
  | az role assignment create --role "Storage Queue Data Contributor" --assignee @- --scope $storage_id

sleep 5m

# create a container / file system
for file_system in "deployment" "maintenance" "data-ready"; do
  az storage fs create \
    -n $file_system \
	--auth-mode login \
	--account-name $STORAGE_ACCOUNT
done

echo "Uploading existing files into the storage account"

# sas code setting up to transfer files
end=$(date -u -d "60 minutes" '+%Y-%m-%dT%H:%MZ')
sas_code=$(az storage account generate-sas --permissions cdlruwap --account-name $STORAGE_ACCOUNT --services b --resource-types sco --expiry $end -o tsv)

# setting up AZCopy
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
mv ./azcopy_linux_amd64_*/azcopy .
rm -r downloadazcopy-v10-linux ./azcopy_linux_amd64_*

# copy all files from raw-data/ folder
./azcopy copy "data/deployment/*/*" "https://${STORAGE_ACCOUNT}.dfs.core.windows.net/deployment/?${sas_code}" --recursive

echo "Now for the queues setup for function communication..."

# create Queue
az storage queue create \
	--name $QUEUE_NAME \
	--account-name $STORAGE_ACCOUNT \
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


