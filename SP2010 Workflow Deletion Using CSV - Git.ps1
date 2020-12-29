<# 
Microsoft provides programming examples for illustration only, without warranty either expressed or
 implied, including, but not limited to, the implied warranties of merchantability and/or fitness 
 for a particular purpose. 
 
 This sample assumes that you are familiar with the programming language being demonstrated and the 
 tools used to create and debug procedures. Microsoft support professionals can help explain the 
 functionality of a particular procedure, but they will not modify these examples to provide added 
 functionality or construct procedures to meet your specific needs. if you have limited programming 
 experience, you may want to contact a Microsoft Certified Partner or the Microsoft fee-based consulting 
 line at (800) 936-5200. 
 #>

# SET VARIABLES
$CSVFilePath = "C:\workflow.csv"
$url = "https://[TENANT].sharepoint.com/"
$userName = Read-Host "Please enter the admin user name"
$password = Read-Host "Please enter the password for $($userName)" -AsSecureString

# GET CSOM CREDENTIALS 
$SPOCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $password)
$context = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$context.Credentials = $SPOcredentials
 
Function Delete-WorkflowAssociations($SPOCredentials, $Web, $ListName, $WF) {
    write-host "Web: " $Web -ForegroundColor blue
    write-host "List: " $ListName -ForegroundColor blue
    write-host "WF: " $WF -ForegroundColor blue

    #Get Web information
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($web)
    $context.Credentials = $SPOCredentials
    $web = $context.Web
    $context.Load($web)
     
    try {
        $context.executeQuery()
        $context.Load($web.Lists)
        $context.ExecuteQuery() 
 
        foreach ($list in $web.Lists) {    
            if ($list.Title -eq $ListName) {
                write-host "FOUND LIST NAME: " $list.Title -ForegroundColor green
                $context.Load($list.WorkflowAssociations)   
                $context.ExecuteQuery() 
 
                $associations = @()

                foreach ($wfAssociation in $list.WorkflowAssociations) {
                    if ($wfAssociation.Name -eq $WF) {
                        Write-host "DELETING WORKFLOW: " $wfAssociation.Name -ForegroundColor green
                        $associations += $wfAssociation
                    }
                }
                foreach ($association in $associations) {
                    $association.DeleteObject()
                    $context.ExecuteQuery() 
                }
            }
        }
    }
    catch {

        write-host "Error: $($_.Exception.Message)" -foregroundcolor green
    }
}

$Workflows = Import-CSV -path $CSVFilePath

foreach ($Workflow in $Workflows) {
    Delete-WorkflowAssociations -SPOCredentials $SPOCredentials -Web $Workflow."Site URL" -List $Workflow."List Title" -WF $Workflow."Workflow Name"
}