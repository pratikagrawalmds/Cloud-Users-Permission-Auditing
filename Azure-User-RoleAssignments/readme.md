# Pipeline to extract User Role Assignments from Azure AD into a CSV file.

Create report in CSV format, containing:
  - SignInName  
  - Display Name
  - Type  
  - RoleDefinitionName  
  - Subscription ID  
  - Subscription Name
  

And upload it into Azure storage account `wkservicenowdiscovery`.

## Getting Started

### Prerequisites or script dependencies  

### Input Parameters
There is no input parameters.

Predefined parameters:
- `inventoryFileName` default value is RoleAssignments.csv
- `storageAccountSubscription` default value is GBS-ITO-RainierCldPlatform-Prod (e25f921a-492f-468e-ab0c-3052e5f208d5) 
- `storageKeyVaultName` default value is ZUSE1GBSKVTP1SERVICES
- `targetContainerName` default value is azure


### Output

- CSV file RoleAssignments.csv



