# Supporting Construction Supply Chain with Data Science

> This is a project developed for the Mota-Engil group for the Data Science thesis of Gustavo Fonseca in the Faculty of Sciences of the University of Lisbon.

## Structure



<div align="center">
  <img src="images/pipeline.png">
</div>

The pipeline is divided in **four** sections. The first part is the ETL pipeline. We initially load the data inside a Blob Storage, we use the Azure FunctionApp to transform it with a trigger from the Queue Storage, load it back into the Blob Storage in a cleaned up CSV format. With the file properly formatted, we BULK INSERT it into the Azure SQL Database, having it ready to be used by multiple applications.

Then we have three applications. The first is the development of a Power BI report that accesses the database and makes use of the created views. The second uses Azure Databricks to process the material descriptions, cluster them into different groups and add this information into the data to be used by a search application. The final application is the use of Azure Databricks to make predictions on material prices. We use these results to build visualizations again on Microsoft Power BI.

Through this repository it is possible to navigate to all of the sections of this project. This includes:

1. ConvertData: repository for the python source code for the transformation done in Azure FunctionApp;
2. Deploy-PL-DB: repository for the T-SQL source code for the deployment of data into the Azure SQL Database;
3. Material-Search: repository for the python source code for the material description comparison algorithm and trained clustering models;
4. Material-Price-Forecasting: repository for the python source code for the prediction of prices for materials.

## Using Azure CLI

The main method used to communicate with the Azure cloud, to provision and handle the different resources is the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli). Since it is intended to save the full deployment in code, and keep a certain level of security, the CLI allows the efficient handling of the different resources.

## Main Deployment






