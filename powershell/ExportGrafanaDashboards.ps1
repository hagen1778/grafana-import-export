# 
# This script exports Grafana datasources, folders & dashboards.
# 
# Psrerequisites:
#   Powershell v2 or higher
#   Grafana API Key: Settings -> API Keys (A viewer-key will suffice only for dashboards and folders. An admin-key will be required for datasources)
# 
# If using powershell v2: $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptPath = $PSScriptRoot

# Save export data to:
$dashboardsDir = "$scriptPath\exported_dashboards"
$datasourcesDir = "$scriptPath\exported_datasources"
$foldersDir = "$scriptPath\exported_folders"


$grafana_home_url = "http://localhost:3000"
$api_key = "eyJrIjoicWhLR09QNDVkbnZzWDRGUURCTlRMM1ZvNlJNVnR2SzAiLCJuIjoid29ybGQiLCJpZCI6MX0="


# No need to touch this
$convertJsonDepth = 100

function grafanaApiCall() {
	Param(
		[parameter(Mandatory=$true, Position=0)]
		[String] $grafanaHost,
		[parameter(Mandatory=$true, Position=1)]
		[String] $apiType,
		[parameter(Mandatory=$true, Position=2)]
		[String] $apiKey
    )
	# Do not change unless you know what you are doing:
	$grafana_api_error_msg = "If you're seeing this Grafana has failed to load its application files"
	$basicAuth = [string]::Format("Bearer {0}", "${apiKey}")
	$headers = @{"Authorization" = $basicAuth }
	
	$grafanaFullUri = "$grafanaHost/api/$apiType"
	try {
		$resultData = Invoke-RestMethod -Uri $grafanaFullUri -Method GET -Headers $headers -ContentType 'application/json' -ErrorAction stop
		
		# Check for errors:
		if (($resultData -eq $null) -or ($resultData -Like "*${grafana_api_error_msg}*")) {Read-Host "Failed querying grafana api at: $grafanaFullUri using defined 'api_key' in this script"; exit 1}
		return $resultData
	} catch {
		# Note that value__ is not a typo.
		$errorCode = $_.Exception.Response.StatusCode.value__ 
		Write-Host "StatusCode:" $errorCode
		Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
		Write-Host "Exception Message:" $_.Exception.Message
		if ($errorCode -eq 403) {Write-Warning "This might indicate that your API key is for viewer/editor only and not an Admin one"}
		Read-Host "Press Enter to continue.."
		exit 1
	}
}


function saveFolderJsonFile() {
	Param(
		[parameter(Mandatory=$true, Position=0)]
		[Object []] $dash_Content
    )
	
	$folderJsonFormat_Content =  @{
		"title"= $dash_Content.dashboard.title
		"uid" = $dash_Content.dashboard.uid
		"id" = $dash_Content.dashboard.id
		"overwrite" = $true
	}
	$folder_title = $folderJsonFormat_Content.title
	Write-Host -NoNewLine "Exporting folder: "
	Write-Host "$folder_title" -ForegroundColor Yellow
	
	$folderJsonFormat_Content | ConvertTo-Json | Out-File "$foldersDir\$folder_title.json"
}

function saveDashboardJsonFile() {
	Param(
		[parameter(Mandatory=$true, Position=0)]
		[Object []] $dash_Content
    )
	
	
	$dash_title = $dash_Content.dashboard.title
	$folder_id = $dash_Content.meta.folderId
	$dash_Content.dashboard.id = $null   # When importing always assign $null to the dashboard.id field
	$dash_Content.dashboard.uid = $null  # When importing if setting dashboard.uid field to $null it will create a new dashboard. But will overwrite an existing dashboard otherwise
	# $dash_Content.dashboard.version = 1  # Reset dashboard version
	# $dash_Content.meta.version = 1
	$dash_Content | Add-Member -Type NoteProperty -Name 'overwrite' -Value $true -Force  # Add {"overwrite" : true} property
	$dash_Content | Add-Member -Type NoteProperty -Name 'folderId' -Value $folder_id -Force  # Add {"folderId" : $id} property
	Write-Host -NoNewLine "Exporting dashboard: "
	Write-Host "$dash_title " -ForegroundColor Yellow
	
	$dash_Content | ConvertTo-Json -Depth $convertJsonDepth | Out-File "$dashboardsDir\$dash_title.json" -Force
}


function exportDashboardsAndFolders() {
	$grafana_dashboards_api_url = "${grafana_home_url}/api/search"
	Write-Host "Exporting dashborads from: $grafana_home_url"
	Write-Host "Querying for dashboards and folders"
	$dashboards = grafanaApiCall "$grafana_home_url" "search" "$api_key"
	
	Write-Host "Found $($dashboards.count) dashboards" -ForegroundColor Cyan

	Write-Host "Exporting dashboards & folders to: `r`n - ${dashboardsDir} `r`n - ${foldersDir}"
	New-Item -ItemType Directory -Path "$dashboardsDir" -Force | Out-Null
	New-Item -ItemType Directory -Path "$foldersDir" -Force | Out-Null
	Write-Host ""

	foreach ($dash in $dashboards) {
		try {
			$dash_url = "${grafana_home_url}/api/dashboards/uid/$($dash.uid)"
			$dash_Content = grafanaApiCall "$grafana_home_url" "dashboards/uid/$($dash.uid)" "$api_key"
			
			if ($dash_Content.meta.isFolder) {
				saveFolderJsonFile $dash_Content
			} else {
				saveDashboardJsonFile $dash_Content
			}
			
			Write-Host "Success" -ForegroundColor Green
			
		} catch {
			Write-Host $_
			Write-Host "Failed to export $dash" -ForegroundColor Red
		}
	}
	Write-Host ""
	
}

function exportDatasources() {
	Write-Host "Exporting datasources from: $grafana_home_url"
	Write-Host "Querying for datasources"
	$datasources = grafanaApiCall "$grafana_home_url" "datasources" "$api_key"

	Write-Host "Found $($datasources.count) datasources" -ForegroundColor Cyan

	Write-Host "Exporting datasources to: `r`n - ${datasourcesDir}"
	New-Item -ItemType Directory -Path "$datasourcesDir" -Force | Out-Null
	Write-Host ""
	
	foreach ($dataSrc in $datasources) {
		try {
			$dataSrc_url = "${grafana_home_url}/api/datasources/$($dataSrc.id)"
			
			$dataSrc_Content = grafanaApiCall "$grafana_home_url" "datasources/$($dataSrc.id)" "$api_key"

			$dataSrc_Name = $dataSrc_Content.name
			$dataSrc_Content.id = $null   # When importing always assign $null to the datasource.id field
			
			Write-Host -NoNewLine "Exporting datasource: "
			Write-Host "$dataSrc_Name " -ForegroundColor Yellow
			$dataSrc_Content | ConvertTo-Json | Out-File "$datasourcesDir\$dataSrc_Name.json"
			Write-Host "Success" -ForegroundColor Green
		} catch {
			Write-Host $_
			Write-Host "Failed to export $dash" -ForegroundColor Red
		}
	}
	Write-Host ""
	
}




function main() {
	Write-Host "Exporter Started"
	exportDashboardsAndFolders
	exportDatasources
	Write-Host "Exporter Finished"
	Read-Host
}


main










