$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\config\env.ps1')

$sqlFiles = @(
    (Join-Path $PSScriptRoot '..\sql\00_control_tables.sql'),
    (Join-Path $PSScriptRoot '..\sql\01_bronze_tables.sql'),
    (Join-Path $PSScriptRoot '..\sql\02_silver_tables.sql'),
    (Join-Path $PSScriptRoot '..\sql\03_gold_tables.sql')
)

foreach ($sqlFile in $sqlFiles) {
    if (-not (Test-Path $sqlFile)) {
        throw "SQL file not found: $sqlFile"
    }

    $tempBtq = Join-Path $PSScriptRoot "..\logs\setup_$([IO.Path]::GetFileNameWithoutExtension($sqlFile)).btq"
    $content = @"
.LOGON $($Env:TD_TDPID)/$($Env:TD_USER),$($Env:TD_PASS);
.RUN FILE = $sqlFile;
.LOGOFF;
.QUIT 0;
"@

    Set-Content -Path $tempBtq -Value $content -Encoding ascii

    Write-Host "Executing $sqlFile"
    $setupLog = Join-Path $PSScriptRoot "..\logs\setup_$([IO.Path]::GetFileNameWithoutExtension($sqlFile)).log"
    $cmdText = 'bteq < "{0}" > "{1}"' -f $tempBtq, $setupLog
    cmd /c $cmdText | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "BTEQ setup failed for $sqlFile. See log: $setupLog"
    }
}

Write-Host "Database setup completed successfully."
