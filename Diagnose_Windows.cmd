@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "SHAMIGO_DIAG_SELF=%~f0"
set "SHAMIGO_DIAG_BASE=%~dp0"
powershell.exe -NoLogo -NoProfile -Command "$s=[IO.File]::ReadAllText($env:SHAMIGO_DIAG_SELF,[Text.Encoding]::UTF8);$a=$s.LastIndexOf('::SHAMIGO_DIAG_BEGIN');$b=$s.LastIndexOf('::SHAMIGO_DIAG_END');if($a -lt 0 -or $b -le $a){exit 2};& ([ScriptBlock]::Create($s.Substring($a+'::SHAMIGO_DIAG_BEGIN'.Length,$b-$a-'::SHAMIGO_DIAG_BEGIN'.Length)))"
set "SHAMIGO_RESULT=%ERRORLEVEL%"
if not "%SHAMIGO_RESULT%"=="0" pause
exit /b %SHAMIGO_RESULT%
::SHAMIGO_DIAG_BEGIN
$ErrorActionPreference = 'Stop'
$lines = New-Object 'System.Collections.Generic.List[string]'
function Write-Line([string]$line) {
    $lines.Add($line)
    Write-Host $line
}
Write-Line 'ShamiGo v0.10.604 - Windows installation and startup-task diagnostic (read-only)'
Write-Line ('Date: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Line ('Windows: ' + [Environment]::OSVersion.VersionString)
try {
    $state = [int](Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' `
        -Name 'VerifiedAndReputablePolicyState' -ErrorAction Stop).VerifiedAndReputablePolicyState
    $label = switch ($state) { 0 {'Off'} 1 {'On'} 2 {'Evaluation'} default {'Unknown'} }
    Write-Line ('Smart App Control: ' + $label + ' (registry state ' + $state + ')')
} catch {
    Write-Line ('Smart App Control: could not read policy state (' + $_.Exception.Message + ')')
}
$base = $env:SHAMIGO_DIAG_BASE
if (-not [string]::IsNullOrWhiteSpace($base)) {
    foreach ($name in @('ShamiGo.exe','ShamiGo_AdminSetup.exe','ShamiGo_AdminLauncher.exe')) {
        $path = Join-Path $base ('Packages\Windows\ShamiGo\' + $name)
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            try {
                $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction Stop
                Write-Line ($name + ' signature: ' + $sig.Status + ' (' + $path + ')')
            } catch { Write-Line ($name + ' signature: unavailable (' + $_.Exception.Message + ')') }
        }
    }
}
Write-Line 'Current-user ShamiGo scheduled task (read-only):'
try {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $sid = [string]$identity.User.Value
    $taskName = 'ShamiGo_AutoStart_Admin_' + $sid
    Write-Line ('Signed-in account: ' + $identity.Name + '; SID: ' + $sid)
    Write-Line ('Task name: ' + $taskName)
    Import-Module ScheduledTasks -ErrorAction Stop
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath '\' -ErrorAction SilentlyContinue
    if ($null -eq $task) {
        Write-Line 'No matching current-user ShamiGo task is registered.'
    } else {
        Write-Line ('Task state: ' + $task.State)
        Write-Line ('Task principal: ' + [string]$task.Principal.UserId)
        Write-Line ('Task run level: ' + [string]$task.Principal.RunLevel)
        Write-Line ('Task actions: ' + @($task.Actions).Count)
        foreach ($a in @($task.Actions)) {
            Write-Line ('Action execute: ' + [string]$a.Execute)
            Write-Line ('Action arguments: ' + [string]$a.Arguments)
            Write-Line ('Action working directory: ' + [string]$a.WorkingDirectory)
        }
        $expected = Join-Path (Join-Path (Join-Path $env:ProgramFiles 'ShamiGo') $sid) 'ShamiGo.exe'
        Write-Line ('Expected current executable: ' + $expected)
    }
} catch {
    Write-Line ('Task inspection failed: ' + $_.Exception.Message)
}
Write-Line 'Recent ShamiGo Code Integrity enforcement events (ID 3077):'
try {
    $events = @(Get-WinEvent -FilterHashtable @{
        LogName='Microsoft-Windows-CodeIntegrity/Operational'
        Id=3077
        StartTime=(Get-Date).AddDays(-7)
    } -MaxEvents 100 -ErrorAction Stop | Where-Object { $_.Message -match 'ShamiGo' } | Select-Object -First 12)
    if ($events.Count -eq 0) { Write-Line 'No ShamiGo block events found in the last 7 days.' }
    foreach ($event in $events) {
        Write-Line ('[' + $event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss') + '] ' +
             ($event.Message -replace '[\r\n]+',' '))
    }
} catch { Write-Line ('Could not read Code Integrity events: ' + $_.Exception.Message) }
$downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
if (Test-Path -LiteralPath $downloads -PathType Container) {
    $outfile = Join-Path $downloads 'ShamiGo_Windows_Security_Diagnostics.txt'
    try {
        $lines.ToArray() | Set-Content -LiteralPath $outfile -Encoding UTF8 -ErrorAction Stop
        Write-Host ('Saved diagnostic: ' + $outfile)
    } catch { Write-Host ('Could not write optional diagnostic file: ' + $_.Exception.Message) }
}
Write-Host 'This diagnostic does not turn off Smart App Control or change system policy.'
::SHAMIGO_DIAG_END
