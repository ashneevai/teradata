$ErrorActionPreference = 'Stop'

$pipelineScript = Join-Path $PSScriptRoot 'run_pipeline.ps1'
if (-not (Test-Path $pipelineScript)) {
    throw "Pipeline script not found: $pipelineScript"
}

$taskName = 'Teradata_Boston_Pipeline_530_IST'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$pipelineScript`""
$trigger = New-ScheduledTaskTrigger -Daily -At 5:30AM
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 6)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null

Write-Host "Task '$taskName' registered for daily 05:30."
Write-Host "Important: ensure Windows timezone is set to 'India Standard Time' so this is 05:30 IST."
