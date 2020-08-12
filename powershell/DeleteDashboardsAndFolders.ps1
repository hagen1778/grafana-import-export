

# Psrerequisites:
#   Powershell v2 or higher
#   Grafana API Key: Settings -> API Keys (A viewer-key will suffice only for dashboards and folders. An admin-key will be required for datasources)


$grafana_home_url = "http://localhost:3000"
$api_key = "eyJrIjoicWhLR09QNDVkbnZzWDRGUURCTlRMM1ZvNlJNVnR2SzAiLCJuIjoid29ybGQiLCJpZCI6MX0="

# Pattern to delete. ""=Delete all dashboards
#  Deleting a folder will delete all dashboards inside that folder too. Cannot be undone
$patternsToDelete = ""

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
		Write-Host "StatusCode: " $_.Exception.Response.StatusCode.value__ 
		Write-Host "StatusDescription: " $_.Exception.Response.StatusDescription
		Write-Host "Exception Message: " $_.Exception.Message
		Start-Sleep $failurePause_SleepSec
		exit 1
	}
	
}

function getDashboardsAndFolders() {
	Write-Host "Querying for dashboards and folders"
	$dashboardsAndFolders = grafanaApiCall "searching dashboards and folders" "search" "GET"
	return $dashboardsAndFolders
}




function deleteDashboards() {
	Param(
		[parameter(Mandatory=$true, Position=0)]
		[Object []] $dashboardsAndFolders
    )
	
	$apiPath = "dashboards/uid"
	Write-Host "Deleting dashboards that match patterns: $patternsToDelete"
	foreach ($dash in $dashboardsAndFolders) {
		if ($dash.type -ne "dash-db") {continue} # Not a dashboard - skip
		
		if (($patternsToDelete | %{"$($dash.title)".contains($_)}) -contains $true) { # If dashboard title contains pattern to delete
			Write-Host -NoNewLine "Deleting dashboard: "
			Write-Host "$($dash.title)" -ForegroundColor Yellow
			grafanaApiCall "delete dashboard $($dash.title)" "$apiPath/$($dash.uid)" "DELETE"
		}
	}
	Write-Host "Finished deleting dashboards"
}

function deleteFolders() {
	Param(
		[parameter(Mandatory=$true, Position=0)]
		[Object []] $dashboardsAndFolders
    )
	
	$apiPath = "folders"
	Write-Host "Deleting folders that match patterns: $patternsToDelete"
	foreach ($folder in $dashboardsAndFolders) {
		if (-not ($folder.type -eq "dash-folder")) {continue} # Not a folder - skip
		
		if (($patternsToDelete | %{"$($folder.title)".contains($_)}) -contains $true) { # If title contains pattern to delete
			grafanaApiCall "delete folder $($folder.title)" "$apiPath/$($folder.uid)" "DELETE"
		}
	}
	
	Write-Host "Finished deleting folders"
}


function main() {
	Write-Host "Deleter Started"
	$dashboardsAndFolders = getDashboardsAndFolders | Select -Last 1
	if ($dashboardsAndFolders) {
		deleteDashboards $dashboardsAndFolders
		deleteFolders $dashboardsAndFolders
	}
	Write-Host "`nDeleter Finished"
	Read-Host
}


main










