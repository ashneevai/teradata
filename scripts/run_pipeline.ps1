$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\config\env.ps1')

$rootDir = Resolve-Path (Join-Path $PSScriptRoot '..')
$logDir = Join-Path $rootDir 'logs'
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}

$global:RunId = [guid]::NewGuid().ToString('N')
$global:SourceFileName = [IO.Path]::GetFileName($Env:BOSTON_CSV)

function New-TempBtqFromTemplate {
    param(
        [Parameter(Mandatory = $true)] [string] $TemplatePath,
        [Parameter(Mandatory = $true)] [hashtable] $TokenMap,
        [Parameter(Mandatory = $true)] [string] $OutputName
    )

    $content = Get-Content -Path $TemplatePath -Raw
    foreach ($key in $TokenMap.Keys) {
        $content = $content.Replace("`${$key}", [string]$TokenMap[$key])
    }

    $outPath = Join-Path $logDir $OutputName
    Set-Content -Path $outPath -Value $content -Encoding ascii
    return $outPath
}

function Invoke-BteqScript {
    param(
        [Parameter(Mandatory = $true)] [string] $BtqPath,
        [Parameter(Mandatory = $true)] [string] $LogName
    )

    $logPath = Join-Path $logDir $LogName
    $cmdText = 'bteq < "{0}" > "{1}"' -f $BtqPath, $logPath
    cmd /c $cmdText | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "BTEQ failed: $BtqPath. See log: $logPath"
    }

    return $logPath
}

function Escape-SqlString {
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return '' }
    return $Value.Replace("'", "''")
}

function Update-RunStatus {
    param(
        [Parameter(Mandatory = $true)] [string] $JobName,
        [Parameter(Mandatory = $true)] [string] $Status,
        [Parameter(Mandatory = $true)] [int] $AttemptNo,
        [string] $ErrorMessage = '',
        [long] $RowsLoaded = 0,
        [bool] $IsStart = $false
    )

    $template = Join-Path $rootDir 'bteq\job_status_template.btq'
    $safeError = Escape-SqlString $ErrorMessage

    $tokenMap = @{
        'TDPID' = $Env:TD_TDPID
        'TD_USER' = $Env:TD_USER
        'TD_PASS' = $Env:TD_PASS
        'RUN_ID' = $global:RunId
        'JOB_NAME' = $JobName
        'RUN_STATUS' = $Status
        'START_TS_EXPR' = $(if ($IsStart) { 'CURRENT_TIMESTAMP(0)' } else { 'NULL' })
        'END_TS_EXPR' = $(if ($Status -eq 'RUNNING') { 'NULL' } else { 'CURRENT_TIMESTAMP(0)' })
        'ROWS_LOADED' = $RowsLoaded
        'ERROR_MESSAGE' = $safeError
        'ATTEMPT_NO' = $AttemptNo
    }

    $btq = New-TempBtqFromTemplate -TemplatePath $template -TokenMap $tokenMap -OutputName "status_${JobName}_$AttemptNo.btq"
    Invoke-BteqScript -BtqPath $btq -LogName "status_${JobName}_$AttemptNo.log" | Out-Null
}

function Check-Dependencies {
    param([Parameter(Mandatory = $true)] [string] $JobName)

    $template = Join-Path $rootDir 'bteq\dependency_check_template.btq'
    $tokenMap = @{
        'TDPID' = $Env:TD_TDPID
        'TD_USER' = $Env:TD_USER
        'TD_PASS' = $Env:TD_PASS
        'JOB_NAME' = $JobName
    }

    $btq = New-TempBtqFromTemplate -TemplatePath $template -TokenMap $tokenMap -OutputName "dep_${JobName}.btq"
    Invoke-BteqScript -BtqPath $btq -LogName "dep_${JobName}.log" | Out-Null
}

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory = $true)] [string] $JobName,
        [Parameter(Mandatory = $true)] [scriptblock] $Work
    )

    $maxRetry = 3
    $retryDelayMin = 30

    for ($attempt = 1; $attempt -le $maxRetry; $attempt++) {
        try {
            Check-Dependencies -JobName $JobName
            Update-RunStatus -JobName $JobName -Status 'RUNNING' -AttemptNo $attempt -IsStart $true

            & $Work

            Update-RunStatus -JobName $JobName -Status 'SUCCESS' -AttemptNo $attempt
            Write-Host "Job $JobName completed on attempt $attempt"
            return
        }
        catch {
            $err = $_.Exception.Message
            Update-RunStatus -JobName $JobName -Status 'FAILED' -AttemptNo $attempt -ErrorMessage $err
            Write-Host "Job $JobName failed on attempt ${attempt}: $err"

            if ($attempt -lt $maxRetry) {
                Write-Host "Waiting $retryDelayMin minutes before retry..."
                Start-Sleep -Seconds ($retryDelayMin * 60)
            }
            else {
                throw "Job $JobName failed after $maxRetry attempts"
            }
        }
    }
}

function Invoke-BronzeLoad {
    $tptFile = Join-Path $rootDir 'tpt\load_boston_bronze.tpt'
    if (-not (Test-Path $Env:BOSTON_CSV)) {
        throw "CSV file not found: $($Env:BOSTON_CSV)"
    }

    $tptLog = Join-Path $logDir "bronze_tpt_$($global:RunId).log"
    $tbuildArgs = @(
        '-f', $tptFile,
        '-u', "TDPID='$($Env:TD_TDPID)'",
        '-u', "TD_USER='$($Env:TD_USER)'",
        '-u', "TD_PASS='$($Env:TD_PASS)'",
        '-u', "CSV_FILE='$($Env:BOSTON_CSV)'",
        '-u', "RUN_ID='$($global:RunId)'",
        '-u', "SOURCE_FILE_NAME='$($global:SourceFileName)'"
    )

    & tbuild @tbuildArgs *> $tptLog
    if ($LASTEXITCODE -ne 0) {
        throw "TPT load failed. See log: $tptLog"
    }
}

function Invoke-SilverBuild {
    $template = Join-Path $rootDir 'bteq\30_silver_transform.btq'
    $tokenMap = @{
        'TDPID' = $Env:TD_TDPID
        'TD_USER' = $Env:TD_USER
        'TD_PASS' = $Env:TD_PASS
        'RUN_ID' = $global:RunId
    }
    $btq = New-TempBtqFromTemplate -TemplatePath $template -TokenMap $tokenMap -OutputName 'silver_run.btq'
    Invoke-BteqScript -BtqPath $btq -LogName "silver_$($global:RunId).log" | Out-Null
}

function Invoke-GoldBuild {
    $template = Join-Path $rootDir 'bteq\40_gold_transform.btq'
    $tokenMap = @{
        'TDPID' = $Env:TD_TDPID
        'TD_USER' = $Env:TD_USER
        'TD_PASS' = $Env:TD_PASS
        'RUN_ID' = $global:RunId
    }
    $btq = New-TempBtqFromTemplate -TemplatePath $template -TokenMap $tokenMap -OutputName 'gold_run.btq'
    Invoke-BteqScript -BtqPath $btq -LogName "gold_$($global:RunId).log" | Out-Null
}

Write-Host "Pipeline run started. Run ID: $($global:RunId)"

Invoke-WithRetry -JobName 'BRONZE_LOAD_BOSTON' -Work ${function:Invoke-BronzeLoad}
Invoke-WithRetry -JobName 'SILVER_BUILD_BOSTON' -Work ${function:Invoke-SilverBuild}
Invoke-WithRetry -JobName 'GOLD_BUILD_BOSTON' -Work ${function:Invoke-GoldBuild}

Write-Host "Pipeline completed successfully."
