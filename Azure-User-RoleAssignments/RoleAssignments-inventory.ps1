<#
.SYNOPSIS
    This script generates inventory report and stores it in Azure Blob Storage
#>
[CmdletBinding()]
#Parameters
Param
(
    [Parameter(Mandatory = $true)]
    [String]$StorageAccountSubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$TargetStorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]$TargetStorageAccountResourceGroup,
    [Parameter(Mandatory = $true)]
    [string]$TargetContainerName,   
    [Parameter(Mandatory = $true)]
    [string]$azroleassignmentInventory
 
)
begin {  

    #Path of the report
    $ReportFileSystemPath = "$env:Build_ArtifactStagingDirectory/azure_role_assignments_inventory.csv"    
  
    # Turn all non-terminating errors into terminating ones
    $ErrorActionPreference = "Stop"
  
    # Suppress breaking changes warnings (https://aka.ms/azps-changewarnings)
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    $WarningPreference = 'SilentlyContinue'
  
    # Init flags for error handling
    $isErrorState = $false      
}  
process {
    try {   
            
            # Define a range of SubscriptionIDs to process 
            [array]$subscriptions = Get-AzSubscription 
            #[array]$subscriptions = Get-AzSubscription -SubscriptionId bf1d9056-4f86-4901-9eea-122d3b998e90
            Write-Output "`nSubscriptions avaliable for processing: $($subscriptions.Count)"

            # Process each subscription and generate report
            Write-Output "`nGenerating report..." 
            try {
                foreach ($subscription in $subscriptions) {
                    Write-Output "`nProcessing subscription $($subscriptions.IndexOf($subscription)+1) out of $($subscriptions.Count): $($subscription.Name)"
                    $roles=Get-AzRoleAssignment -Scope /subscriptions/$($subscription.SubscriptionId) | Where-Object {$_.Scope -eq "/subscriptions/$($subscription.SubscriptionId)"}
                    Write-Host $roles.count
                    $userRoles = $roles | Where-Object { $_.ObjectType -eq "User"} | Sort-Object -Property 'DisplayName' -Unique
                    Write-Host $userRoles.count
                    foreach ($userRole in $userRoles){
                        $userDetail = $roles | Where-Object {$_.DisplayName -eq $userRole.DisplayName}
                        $rolesAssigned = ""
                        foreach ($roleDefinition in $userDetail){
                            $rolesAssigned = $rolesAssigned + "," + $roleDefinition.RoleDefinitionName
                        }
                    
                    #Generate Report Details
                    $reportDetails = [ordered]@{
                        'SignInName'              = $userRole.SignInName
                        'DisplayName'             = $userRole.DisplayName
                        'Type'                    = $userRole.ObjectType
                        'RoleDefinitionName'      = $rolesAssigned.TrimStart(",")                       
                        'Subscription ID'         = $subscription.SubscriptionId
                        'Subscription Name'       = $subscription.Name
                    }
                    [PSCustomObject]$reportDetails | Export-Csv -Path $ReportFileSystemPath -NoTypeInformation -Append
                }
            }                
            }
            catch {
                write-host $_
                $isErrorState = $true
                $catchedError = $_
            }
        
        #Select subscription of target Storage Account
        Set-AzContext -SubscriptionId $StorageAccountSubscriptionId

        #Get Context of the destination storage account
        $targetStorageAccount = Get-AzStorageAccount -Name $TargetStorageAccountName -ResourceGroupName $TargetStorageAccountResourceGroup

        Write-Output "Uploading the result file"
      
        #Upload the file
        Set-AzStorageBlobContent -Container $TargetContainerName -File $ReportFileSystemPath -Blob $azroleassignmentInventory -Context $targetStorageAccount.Context -Force

        Write-Output "The result file is stored in the following location"
        Write-Output "SubcriptionId: $StorageAccountSubscriptionId"
        Write-Output "Resource Group: $TargetStorageAccountResourceGroup"
        Write-Output "Storage Account Name: $TargetStorageAccountName"
        Write-Output "Container Name: $TargetContainerName"
        Write-Output "File Paths: $azroleassignmentInventory  "
    }
  
    catch {
        $isErrorState = $true
        $catchedError = $_
    }
}
  
end {
    if ($isErrorState) {
        Write-Output "`nReport generated with errors."
        throw "`nLast error: $($catchedError | Out-String)"
    }
    else {
        Write-Output "`nReport generated successfully."
    }
}