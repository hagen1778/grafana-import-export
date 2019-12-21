

# Psrerequisites:
#  Get API Key from Grafana at: Settings -> API Keys (viewer key will suffice)

# If using powershell v2: $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptPath = $PSScriptRoot

$grafana_home_url = "http://13.90.250.12:3000"
$api_key = "eyJrIjoiS3pDM2QyT1dYZ1Q3V0kxV1hqcW9aMXY4cEpUNWxueVkiLCJuIjoiZGFzaGJvYXJkc19leHBvcnRfaW1wb3J0IiwiaWQiOjF9"

# Do not change unless you know what you are doing:
$grafana_api_error_msg = "If you're seeing this Grafana has failed to load its application files"


function exportDashboards() {
	$grafana_dashboards_api_url = "${grafana_home_url}/api/search"
	
	Write-Host "Exporting dashborads from: $grafana_home_url"

	Write-Host "Querying.."
	$basicAuth = [string]::Format("Bearer {0}", "${api_key}")
	$headers = @{"Authorization" = $basicAuth }

	try {
		$dashboards = Invoke-RestMethod -Uri $grafana_dashboards_api_url -Headers $headers -ContentType 'application/json'
		
		# Check for errors:
		if ($dashboards -eq $null -or $dashboards.count -eq $null) {Read-Host "Failed querying grafana at: $grafana_dashboards_api_url using defined 'api_key' in this script"; exit 1}
		if ($dashboards -Like "*${grafana_api_error_msg}*")        {Read-Host "Failed querying grafana at: $grafana_dashboards_api_url using defined 'api_key' in this script"; exit 1}
	} catch {
		# Note that value__ is not a typo.
		Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
		Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
		Read-Host "Exception Message:" $_.Exception.Message
		exit 1
	}


	Write-Host "Found $($dashboards.count) dashboards"

	Write-Host "Creating exported dashboards and folders dirs next to this script at: $scriptPath"
	New-Item -ItemType Directory -Path "$scriptPath\exported_dashboards" -Force
	New-Item -ItemType Directory -Path "$scriptPath\exported_folders" -Force

	foreach ($dash in $dashboards) {
		Write-Host "Exporting: $($dash.title)"
		$dash_url = "${grafana_home_url}/api/dashboards/uid/$($dash.uid)"
		
		try {
			$dash_content = Invoke-RestMethod -Uri $dash_url -Headers $headers -ContentType 'application/json'
		} catch {
			# Note that value__ is not a typo.
			Write-Error "Failed to export a dashboard"
			Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
			Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
			Write-Host "Exception Message:" $_.Exception.Message
			continue
		}

		$dash_title = $dash_content.dashboard.title
		$dash_content.dashboard.id = $null   # When importing always assign $null to the dashboard.id field
		$dash_content.dashboard.uid = $null  # When importing if setting dashboard.uid field to $null it will create a new dashboard. But will overwrite an existing dashboard otherwise
		$dash_content.dashboard.version = 1
		$dash_content.meta.version = 1

		Write-Host "Saving exported: $dash_title"
		if ($dash_content.meta.isFolder) {$dash_content | ConvertTo-Json | Out-File "$scriptPath\exported_folders\$dash_title.json"}
		else {$dash_content | ConvertTo-Json | Out-File "$scriptPath\exported_dashboards\$dash_title.json"}

		Write-Host "`n"

	}
	
}






function main() {
	Write-Host "Exporter Started"
	exportDashboards
	Write-Host "Exporter Finished"
}


main










