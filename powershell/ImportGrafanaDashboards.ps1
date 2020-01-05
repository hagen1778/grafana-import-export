

# Psrerequisites:
#   Powershell v2 or higher
#   Grafana API Key: Settings -> API Keys (A viewer-key will suffice only for dashboards and folders. An admin-key will be required for datasources)

# If using powershell v2: $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptPath = $PSScriptRoot

$dashboardsDir = "$scriptPath\exported_dashboards"
$foldersDir = "$scriptPath\exported_folders"
$datasourcesDir = "$scriptPath\exported_datasources"

$grafana_home_url = "http://ec2-3-16-187-253.us-east-2.compute.amazonaws.com:3000"
$api_key = "eyJrIjoiOFhNUXVrdUcwMDRoOVpDcVdKMEduTWFnOGU5UEo5MGYiLCJuIjoiYWRtaW5fYXBpX2tleSIsImlkIjoxfQ=="

# Importing a folder that already exists gives this error
$folderExistErrorMsg = "A folder or dashboard in the general folder with the same name already exists"

# Show error for X seconds
$failurePause_SleepSec = 5



function grafanaApiCall() {
	Param(
		[parameter(Mandatory=$true, Position=0)]
		[String] $actionDescription,
		[parameter(Mandatory=$true, Position=1)]
		[String] $apiPath,
		[parameter(Mandatory=$true, Position=3)]
		[String] $methodType,
		[parameter(Position=4)]
		[String] $body = $null
    )
	
	# Do not change unless you know what you are doing:
	$grafana_api_error_msg = "If you're seeing this Grafana has failed to load its application files"
	$basicAuth = [string]::Format("Bearer {0}", "${api_key}")
	$headers = @{"Authorization" = $basicAuth }
	
	$grafanaFullUri = "$grafana_home_url/api/$apiPath"
	try {
		if ($body) {$resultData = Invoke-RestMethod -Uri $grafanaFullUri -Method $methodType -Headers $headers -ContentType 'application/json' -Body $body -ErrorAction Stop} 
		else       {$resultData = Invoke-RestMethod -Uri $grafanaFullUri -Method $methodType -Headers $headers -ContentType 'application/json' -ErrorAction Stop} 
		
		# Check for errors:
		if ((-not $?) -or ($resultData -eq $null) -or ($resultData -Like "*${grafana_api_error_msg}*")) {Read-Host "Error - Failed $actionDescription"; Start-Sleep $failurePause_SleepSec; exit 1}
		
		return $resultData
	} catch {
		# Note that value__ is not a typo.
		if ($_ -Like "*$folderExistErrorMsg*") {Write-Host "Already exists" -ForegroundColor Green; continue}
		Write-Error $_
		Write-Host "StatusCode: " $_.Exception.Response.StatusCode.value__ 
		Write-Host "StatusDescription: " $_.Exception.Response.StatusDescription
		Write-Host "Exception Message: " $_.Exception.Message
		Start-Sleep $failurePause_SleepSec
		# exit 1
	}
	
}


function importJsonFiles() {
	Param(
		[parameter(Mandatory=$true, Position=0)]
		[String] $importTitle,
		[parameter(Mandatory=$true, Position=1)]
		[String] $jsonFilesDir,
		[parameter(Mandatory=$true, Position=2)]
		[String] $apiPath
    )
	Write-Host "Importing all ${importTitle} json files from: $jsonFilesDir"
	
	$jsonFiles = Get-ChildItem -Path $jsonFilesDir -Recurse -Include *.json
	Write-Host "Found $($jsonFiles.count) $importTitle jsons files" -ForegroundColor Cyan
	
	foreach ($jsonFile in $jsonFiles) {
		try {
			
			$jsonFile_rawContent = Get-Content -Path $jsonFile -Raw -ErrorAction Stop
			
			Write-Host -NoNewLine "Importing ${importTitle}: "
			Write-Host "$($jsonFile.BaseName) " -ForegroundColor Yellow
			$actionDesc = "importing $importTitle $($jsonFile.BaseName)"
			grafanaApiCall $actionDesc $apiPath "POST" $jsonFile_rawContent
			
			Write-Host "Success" -ForegroundColor Green
		} catch {
			Write-Host $_
			Write-Host "Failed to import ${importTitle}: $($jsonFile.BaseName)" -ForegroundColor Red
		}
	}
	Write-Host ""
}


function main() {
	Write-Host "Importer Started"
	# importJsonFiles "Datasource"
	importJsonFiles "Folder"    $foldersDir    "folders"
	importJsonFiles "Dashboard" $dashboardsDir "dashboards/import"
	Write-Host "Importer Finished"
	Read-Host
}


main










