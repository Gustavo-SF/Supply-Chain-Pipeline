#!/bin/bash
#
# The following script will do the maintenance of all the
# Procurement Pipeline Project data.

echo "[PPP] Starting the maintenance deployment of the Procurement Pipeline Project."

# Variable loading
export $(xargs < ppp.env)

cd ConvertData/
# run the Azure FunctionApp deployment script
bash maintenance.sh

echo "[PPP] New data has been uploaded and transformed with Azure FunctionApp."

cd ../Deploy-Azure-DB/

# run the Azure SQL DB deployment script
bash maintenance.sh

echo "[PPP] Transformed data has been uploaded into Azure SQL Database."

echo "[PPP] Completed!"