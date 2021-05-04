# Supporting Construction Supply Chain with Data Science

> This is a project developed for the Mota-Engil group for the Data Science thesis of Gustavo Fonseca in the Faculty of Sciences of the University of Lisbon.

## Structure



<div align="center">
  <img src="images/pipeline.png">
</div>

The pipeline is divided in **four** sections. The first part is the ETL pipeline. We initially load the data inside a Blob Storage, we use the Azure FunctionApp to transform it with a trigger from the Queue Storage, load it back into the Blob Storage in a cleaned up CSV format. With the file properly formatted, we BULK INSERT it into the Azure SQL Database, having it ready to be used by multiple applications[1].

Then we have three applications. The first is the development of a Power BI report that accesses the database and makes use of the created views [2]. The second uses Azure Databricks to process the material descriptions, cluster them into different groups and add this information into the data to be used by a search application[3]. The final application is the use of Azure Databricks to make predictions on material prices. We use these results to build visualizations again on Microsoft Power BI[4].

Through this repository it is possible to navigate to all of the sections of this project. This includes:

1. **ConvertData**: repository for the python source code for the transformation done in Azure FunctionApp;
2. **Deploy-PL-DB**: repository for the T-SQL source code for the deployment of data into the Azure SQL Database;
3. **Material-Search**: repository for the python source code for the material description comparison algorithm and trained clustering models;
4. **Material-Price-Forecasting**: repository for the python source code for the prediction of prices for materials.

## Requirements

### Azure CLI
The main method used to communicate with the Azure cloud, to provision and handle the different resources is the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli). Since it is intended to save the full deployment in code, and keep a certain level of security, the CLI allows the efficient handling of the different resources.

#### Setting up Credentials
In order to use AZ CLI without having to provide credentials all the time, we provide the login information by running `az login`.

### AZCopy
[AZCopy](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) is used to transfer files into, between and out of the Azure Data Lake Storage. 

### SQLCMD
[SQLCMD](https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility?view=sql-server-ver15) is used to communicate with the SQL Server within the Azure SQL Database. We use it to run queries inside the database, allowing to insert data, delete and modify as well as modify its configurations and schemas.

### Azure Functions Core Tools
[Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=linux%2Ccsharp%2Cbash) allows the setting up of the FunctionApp locally and deploying it into the FunctionApp service. 
## Main Deployment

To initialize the deployment we have to first introduce the data in the data/raw-data/ folder and run the following command:
```bash
bash deployment.sh
```

With the whole ADLS setup concluded, we use AZCopy to transfer files from data/raw-data storage into the ADLS raw-data/ file storage. 

```bash
./azcopy copy \
    "data/raw-data/*" \
    "https://${storageAccount}.dfs.core.windows.net/raw-data/?${sas}" \
    --recursive
```

To finalize we just need to create the Queue Storage to receive FunctionApp triggers and run the rest of the deployments to make the needed transformations and data deployments into the SQL Database.

## Maintenance Deployment

The maintenance deployment is deployed when the whole infrastructure is already provisioned and we just need to add data on top of what already exists.

Many commands have to be rerun due to security reasons, but most are made simpler and faster such as the addition of MB51 and MCBA data.

To run this deployment we should just run the following line:
```bash
bash maintenance.sh
```






