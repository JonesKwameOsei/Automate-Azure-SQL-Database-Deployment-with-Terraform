# Azure Infrastructure Deployment with Terraform
## Deployment of Azure Resource and Web Application with Terraform and CI/CD.

## Project Overview
This project demonstrates the deployment of **Azure** resources and a **DotNet** **web application** using **Terraform**, along with the implementation of a **CI/CD (Continuous Integration and Continuous Deployment) pipeline** using **GitHub Actions**. The goal is to showcase how Terraform can be utilised to **manage** and **provision Azure infrastructure** in a **versioned**, **reproducible**, **consistent** and **automated** manner.

## Why Terraform to Manage Azure Infrastructure?
Terraform is a powerful Infrastructure as Code (IaC) tool that allows developers to define infrastructure in a declarative manner. By using Terraform, cloud infrastructure engineers can enhance:

1. **Consistency**: Ensure that the **Azure** infrastructure is deployed consistently across different environments (e.g., development, staging, production).
2. **Scalability**: Easily scale the infrastructure by modifying the Terraform configuration files, without the need to manually provision resources.
3. **Collaboration**: Collaborate with DevOps team by versioning the Terraform code in a source control system like GitHub.
4. **Automation**: Integrate Terraform into a CI/CD pipeline to automate the deployment process.

## Setting Up Terraform Configuration Files

The Terraform configuration for this project consists of the following files:

1. **main.tf**: This file defines the Azure resources to be created, such as virtual networks, subnets, virtual machines, and web applications. In our case, we have confiugured reources including:
-  **resource group**
-  **Azure SQL Database**
-  **service plan**
-  **DotNet Web App**<p>
Below is the configurations for the main.tf:
```
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = {
    environment = "sandbox"
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = "tfstorage01jones"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "plan" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "P1v2"
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "app" {
  name                = "mywebapp-01357"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      dotnet_version = "v8.0"
    }
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "Database"
    type  = "SQLAzure"
    value = "Server=tcp:azurerm_mssql_server.sql.fully_qualified_domain_name Database=azurerm_mssql_database.db.name;User ID=azurerm_mssql_server.sql.administrator_login;Password=azurerm_mssql_server.sql.administrator_login_password;Trusted_Connection=False;Encrypt=True;"
  }
}

resource "azurerm_mssql_server" "sql" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "db" {
  name           = "ProductsDB"
  server_id      = azurerm_mssql_server.sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_mssql_database_extended_auditing_policy" "policy" {
  database_id                             = azurerm_mssql_database.db.id
  storage_endpoint                        = azurerm_storage_account.storage.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.storage.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 1
}
```
2. **variables.tf**: This file contains the input variables used in the Terraform configuration in the **main.tf**, making the deployment more flexible and reusable.
**Variables.tf** configuration: 
```
# Defining variables for the resources
variable "resource_group_name" {
  type        = string
  description = "RG name in Azure"
}

variable "resource_group_location" {
  type        = string
  description = "RG location in Azure"
}

variable "app_service_plan_name" {
  type        = string
  description = "App Service Plan name in Azure"
}

variable "app_service_name" {
  type        = string
  description = "App Service name in Azure"
}

variable "sql_server_name" {
  type        = string
  description = "SQL Server instance name in Azure"
}

variable "sql_database_name" {
  type        = string
  description = "SQL Database name in Azure"
}

variable "sql_admin_login" {
  type        = string
  description = "SQL Server login name in Azure"
}

variable "sql_admin_password" {
  type        = string
  description = "SQL Server password name in Azure"
}
```
3.**providers.tf**: This file specifies the provider (in this case, the Azure provider) and the required provider version.
**Providers.tf** configured below:
```
# Defining Terraform provider block
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.101.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```
4. **outputs.tf**: This file defines the output values that will be displayed after the deployment, such as the URLs of the deployed web applications.
```
output "webapp_url" {
  value = azurerm_windows_web_app.app.default_hostname
}

output "webapp_ips" {
  value = azurerm_windows_web_app.app.outbound_ip_addresses
}
```

5. **local.tf**: This file defines any local values used in the Terraform configuration, which can be helpful for organizing and managing the code. N?B: We will leave this unconfigured for now.

## Terraform Commands to Create Resources

To deploy the **Azure SQL** Database and the **DotNet (.Net)** web application using Terraform, let's run these commands:

1. **Initialize the Terraform working directory**:
   ```
   terraform init
   ```
The output after running the command should look like this:
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.101.0"...
- Installing hashicorp/azurerm v3.101.0...
- Installed hashicorp/azurerm v3.101.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
2. **Format and validate the configuration files**
  ```
  terraform fmt
  ```
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/e317ceb5-0217-40de-ab9e-530c512f7243)<p>

Formatting Terraform configuration files using the **terraform fmt** command ensures consistent code style and readability. The files returned as output were well formatted by **Terraform**.
  ```
  terraform validate
  ```
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/2cf0c526-6e06-4eb6-b6d9-25567a09c837)<p>

Validating the configuration with **terraform validate** checks for syntax errors and compatibility issues, catching problems early in the deployment process. These practices promote reproducibility, maintainability, and reliability of your infrastructure deployments across different environments. The output, **"Success! The configuration is valid"**, means that there is no error in any of the files. 

3. **Create an execution plan**:
   ```
   terraform plan -out=tfplan
   ```
Conventionally, we can run **terraform plan** without any argument. However, we added the argument **-out=tfplan** to store our infrastructure plan in a file. The **terraform plan** command generates an **execution plan** that outlines the actions **Terraform** will take to bring the infrastructure to the desired state defined in the configuration files, allowing us to preview the changes before actually applying them.<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/96de6b55-fa9c-483d-bfe1-977a6fcc637e)<p>
4. **show the tfplan file**
The the plan is initially stored in a binary format. To display it as a readable text, run:
  ```
  terraform show -json tfplan                                 # Makes it readable but not well formatted. Writing the output in a well format is recommended. 
  terraform show -json tfplan >> tfplan.json                  # This saves the output in a json file.
  terraform show -json tfplan | jq '.' > tfplan.json          # Format to a more readable format tfplan.json file
  ```
Before we exceute the plan which will create 7 resources, let's confirm that there no resources in the **Azure Portal**. <p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/0a290f37-abad-49b6-81e5-fc0ff8ffad82)<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/f9e91faf-cdbf-4226-bad3-782d18394afb)<p>
Now we can deploy the resources.<p>

5. **Apply the execution plan**:
   ```
   terraform apply "tfplan"
   ```
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/a6dead9b-8534-448a-9ac4-e9f67fc76123)<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/8a1c46d4-9a15-4027-8069-9419210eccb6)<p>
The deployment has been successfully executed. Let us verify this in the **Azure Portal**. <p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/999b9e8e-0232-4d87-8712-9117f498c05d)<p>
The reource group has been created with all components and the **Azure SQL Database**.<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/9fdb2cef-8e11-450d-b38f-6cc850eeeb74)<p>

### Connect to the SQL Server:
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/90880a0b-e52c-4e35-8faa-eef9e3766943)<p>
We have successfully connected to the **database**. <p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/62f2118a-a047-43d1-b975-69a08e36e804)<p>
Now, we can perform some operations in the database since it is ready and running. Let us create a table called **Products**. 
```
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    Price DECIMAL(10, 2),
    Description NVARCHAR(255),
    StockQuantity INT
);
GO;

INSERT INTO Products (ProductID, ProductName, Price, Description, StockQuantity)
VALUES 
(1, 'Smartphone', 599.99, 'High-end smartphone with advanced features', 100),
(2, 'Laptop', 1099.99, 'Powerful laptop for professional use', 50),
(3, 'Tablet', 399.99, 'Portable tablet for entertainment and productivity', 75),
(4, 'Headphones', 149.99, 'Wireless headphones with noise-cancellation', 150),
(5, 'Smartwatch', 249.99, 'Fitness tracker with smartwatch features', 200),
(6, 'Camera', 799.99, 'Professional DSLR camera with interchangeable lenses', 25),
(7, 'Television', 1499.99, '4K Ultra HD smart TV with HDR support', 30),
(8, 'Gaming Console', 399.99, 'Next-generation gaming console for immersive gaming experiences', 100),
(9, 'Wireless Speaker', 129.99, 'Portable wireless speaker with long battery life', 120),
(10, 'External Hard Drive', 89.99, 'High-capacity external hard drive for data storage', 80);
GO;

Select * FROM Products;
GO;
```
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/6fd4f65d-10d5-4cc6-bedf-4cebcedb3310)<p>
We can drop the table by running:
```
DROP TABLE Products;
```
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/80b68609-fcdb-46a2-b2dc-7087f8a56def)<p>

Next, we will confirm if the .Net wep application is running<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/600a946e-47b9-42f5-96ef-7246ed6663ef)<p>

The service plan is also running<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/4ad27417-de25-4b32-8d8c-690b0f966952)<p>
Having a glimpse of the configurations in Azure SQL Database will help enhance the configuration. Let us check the configurations. <p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/1bfa80f3-64ed-4b2b-9750-8aecc89ca9c0)<p>

6. **Destroy the deployed resources**: When the resources are no more service needed, terraform can tear them down to reduce cost. 
   ```
   terraform destroy
   ```
Resources deleted by terraform successfully.<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/4f7663ed-1a52-4c9c-a5cb-515d69574d56)<p>
Let us verify from the Azure Portal if all the resources were deleted.<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/cd2126e5-574c-4a39-8a13-dc997874768a)<p>
![image](https://github.com/JonesKwameOsei/Azure-Infrastructure-Deployment-with-Terraform/assets/81886509/a0a42834-b20f-4333-ac30-9e834efcef59)<p>

## CI/CD with GitHub Actions
Before we can utilise **Github actions** to automate the building, testing and deploying of our infrastructure, we need to do the following:
1. Clone the Github repository.
```
git clone <repo link>
```
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/233f3b50-6ae4-41ab-8b8f-bb090e21a334)<p>
2. Create **.github/workflows** directory in the repo.
```
mkdir -p .github/workflows
```
3. Configure Git. 
```
git config --global user.name <username>
git config --global user.email <user@example.com>
```
4. Initialise/reinitialise the repo
```
git init
```
5. Cretae hub
```
hub create
```
6. Create **service princial** / **AppRegistration** for **GitHub actions**
We will utilise a service principal/app registration to deploy resources from GitHub into Azure. We can create this App registration using **Azure CLI**. Remember to edit the subscription ID to yours before runing the command.
```
az account show --query id --output tsv                                                   # Prints the azure subscription account

az account list --query "[].{Name:name, SubscriptionId:id}" --output table                # This command will list all your subscriptions along with their names and IDs in a tabular format.


az ad sp create-for-rbac --name "SP-GitHubAction-Blog" --role contributor --scopes /subscriptions/{subscriptionid} --sdk-auth  # Creates the service principal
```
7. Create required GitHub secrets. 
To create the secret in GitHub:
- In the GiHub repo, click on **Settings**
- Then click on the **DropDown** next to **Secrets and Variables**<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/1032987c-9041-4ee1-ab38-92e33b34e858)<p>
- Next, click on **Actions**.<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/0ce6d04a-9acd-4449-bbe1-5cbc3e2a790b)<p>
- Click on **New repository secret** <p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/4c20a15f-bd1c-48bd-a040-6c11166da840)<p>
- We will create 4 secrets for **AZURE_CLIENT_ID**, **AZURE_CLIENT_SECRET**, **AZURE_TENANT_ID** and **MVP_SUBSCRIPTION** using the outputs of the **service principal** we created earlier. Each will look like this:<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/6714b39f-1a07-4865-a091-7b99b200546b)<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/1222176c-d42c-4d92-8394-53bd8030325e)<p>

## Code Deployment with GitHub Actions
To deploy the code in the configration files, we will use GitHub actions instead of the command line. <p>

To automate the deployment process, this project includes a GitHub Actions workflow. The workflow consists of the following steps in a **yaml** file called **actions.yaml**:

1. **Checkout the repository**: Checkout the code from the repository.
2. **Setup Terraform**: Install the necessary Terraform version and Azure provider.
3. **Initialize Terraform**: Run `terraform init` to initialize the working directory.
4. **Validate Terraform configuration**: Run `terraform validate` to check the syntax and validity of the Terraform configuration.
5. **Apply Terraform changes**: Run `terraform apply` to deploy the infrastructure changes.
```
# This is a basic workflow to help you get started with Actions

name: Terraform-Azure-SQL-Database-Deployment

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the main branch
  push:
    branches:
      - main

  # Allows you to run this workflow manually from the Actions tab
#   workflow_dispatch:

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a single job called "build"
  resourcegroups:
    name: 'Terraform Depoly Resource'
    # The type of runner that the job will run on
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: Terraform
    
    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
        # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
    - name: checkout Repo
      uses: actions/checkout@v4

    - name: Setup Terraform 
      uses: hashicorp/setup-terraform@v2

    - name: 'Terraform init'
      run: terraform init 
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.MVP_SUBSCRIPTION }}
        ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }} 
    
    - name: Terraform Validate
      run: terraform validate

    - name: Terraform Plan 
      run: terraform plan
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.MVP_SUBSCRIPTION }}
        ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

                    
    - name: 'Terraform apply'
      run: terraform apply --auto-approve  
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.MVP_SUBSCRIPTION }}
        ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

### Push Changes to GitHub to activate Github Action
The GitHub Actions workflow is triggered on push events to the main branch, ensuring that any changes to the Terraform configuration are automatically deployed to the Azure environment. It is recommended to push the changes from a different branch, then merge it with the main branch by making a **pull request**.
```
git checkout -b deployAzureSQLDB        # Creates a new braanch and switch into it from the main

git add .                               # Adds the changes to the repo

git status                              # Lists the changes to be commited or pushed to the repo

git commit -m "commit message"          # States the reason for the push or changes

git push origin deployAzureSQLDB       # pushes the changes to the repo from the new branch
```
We need to create the pull request to merge the changes to the main branch to trigger the actions.<p>

![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/36c05487-8fbd-4714-841b-ab9ac4d8b866)<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/4df5b980-181c-4a13-8454-06a674dc337e)<p>
Now we will click on the green button **Create pull request**. <p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/227b8bea-8fbb-4419-a9a8-64f1dd46c44d)<p>
To **Merge** the changes to the **main** branch, we will click on the green button **Merge pull request** and then **Confirm merge**. Confirming the nerge will trigger the actions.<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/152bf200-f7f1-455b-abaf-83207efea7a3)<p>
Pull request successfully merged.<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/c47b47b8-6901-4f41-9859-fcb93a565936)<p>

**GitHub action** running successfully as expected:<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/b8542e0a-ca6c-4c75-b5d3-1fd4143a4fb4)<p>

![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/5d2fd083-cd08-49c5-a62c-b79b78eabbeb)<p>

Let's confirm from the **Azure Portal that the resources are created. Indeed, the resources have been created.<p>
![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/6aa05114-3116-4745-81c0-6d5044443990)<p>

## Conclusion

This project demonstrates how Terraform can be used to deploy Azure infrastructure and web applications in a consistent, scalable, and automated manner. By integrating Terraform with a CI/CD pipeline using GitHub Actions, you can streamline the deployment process and ensure that your Azure environment remains up-to-date and aligned with your codebase.<p>

![image](https://github.com/JonesKwameOsei/Automate-Azure-SQL-Database-Deployment-with-Terraform/assets/81886509/8a0ea0f3-d886-4b45-b9a3-8b75f4fa5e0a)

