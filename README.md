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

5. **Apply the execution plan**:
   ```
   terraform apply "tfplan"
   ```

6. **Destroy the deployed resources**:
   ```
   terraform destroy
   ```

## CI/CD with GitHub Actions

To automate the deployment process, this project includes a GitHub Actions workflow. The workflow consists of the following steps:

1. **Checkout the repository**: Checkout the code from the repository.
2. **Setup Terraform**: Install the necessary Terraform version and Azure provider.
3. **Initialize Terraform**: Run `terraform init` to initialize the working directory.
4. **Validate Terraform configuration**: Run `terraform validate` to check the syntax and validity of the Terraform configuration.
5. **Apply Terraform changes**: Run `terraform apply` to deploy the infrastructure changes.

The GitHub Actions workflow is triggered on push events to the main branch, ensuring that any changes to the Terraform configuration are automatically deployed to the Azure environment.

## Conclusion

This project demonstrates how Terraform can be used to deploy Azure infrastructure and web applications in a consistent, scalable, and automated manner. By integrating Terraform with a CI/CD pipeline using GitHub Actions, you can streamline the deployment process and ensure that your Azure environment remains up-to-date and aligned with your codebase.
