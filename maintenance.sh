#!/bin/bash

resourceGroup="DataScienceThesisRG"
location="westeurope"
storageAccount="dsthesissa"

# save the previous data in another folder
az storage fs create -n old-ready --auth-mode login --account-name $storageAccount

# get the secrets
source Deploy-Azure-DB/secrets/database_pws.sh
server=$(az sql server list --query [0].name -o tsv)

# get ip and open firewall to it
thisIP=$(wget -O - -q https://icanhazip.com/)
az sql server firewall-rule create \
    --server $server \
    -n AllowMyIP \
    --start-ip-address $thisIP \
    --end-ip-address $thisIP

# get the last date in the data and extract month and year
lastentry=$(sqlcmd -S tcp:$server.database.windows.net -d $database -U $login -P $password -Q "SELECT MAX(EntryDate) FROM [PPP].[MB51]" | awk '/2/ {print $1}')
yearLastEntry=$(echo $lastentry | awk 'BEGIN { FS = "-" } ; { print $1 }')
monthLastEntry=$(echo $lastentry | awk 'BEGIN { FS = "-" } ; { print $2 }')

# setting up AZCopy
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
mv ./azcopy_linux_amd64_*/azcopy .
rm -r downloadazcopy-v10-linux ./azcopy_linux_amd64_*

echo "Uploading files to storage"

# setting up the sas code
end=$(date -u -d "200 minutes" '+%Y-%m-%dT%H:%MZ')
sas=$(az storage account generate-sas --permissions cdlruwap --account-name $storageAccount --services b --resource-types sco --expiry $end -o tsv)

# Needs to transfer with blob identification. DFS doesn't seem to be working.
# Move and delete previous files
./azcopy copy "https://${storageAccount}.blob.core.windows.net/data-ready/*?${sas}" "https://${storageAccount}.blob.core.windows.net/old-ready/${lastentry}/data-ready/?${sas}" --recursive
./azcopy copy "https://${storageAccount}.blob.core.windows.net/raw-data/*?${sas}" "https://${storageAccount}.blob.core.windows.net/old-ready/${lastentry}/raw-data/?${sas}" --recursive
./azcopy rm "https://${storageAccount}.blob.core.windows.net/data-ready/*?${sas}" --recursive
./azcopy rm "https://${storageAccount}.blob.core.windows.net/raw-data/*?${sas}" --recursive

# need to check if rows with headers are correct in the Function App code
./azcopy copy "Data-Preparation/raw-data/*" "https://${storageAccount}.dfs.core.windows.net/raw-data/?${sas}"  --recursive


cd ConvertData/

# run the Azure FunctionApp deployment script
bash maintenance_script.sh

cd ../Deploy-Azure-DB/

# run the Azure SQL DB deployment script
bash maintenance_script.sh

echo "Completed!"