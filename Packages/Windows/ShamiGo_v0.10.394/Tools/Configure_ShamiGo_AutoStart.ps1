# ShamiGo v0.10.394 - one-consent bounded install and safe uninstall.
# Installer launches with one UAC; all subsequent helpers inherit elevation.
# No Windows service, stored password, background polling, or UAC suppression.
param(
    [ValidateSet('Install','Disable','Uninstall')]
    [string]$Mode = 'Install',
    [switch]$Elevated,
    [ValidateSet('None','Register','RemoveTask')]
    [string]$Worker = 'None',
    [string]$ExpectedSid = '',
    [string]$RunId = ''
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Say([string]$message) {
    Write-Host $message
    if ($script:logPath) {
        try { Add-Content -LiteralPath $script:logPath -Encoding UTF8 -Value ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $message) } catch { }
    }
}
function Fail([string]$message) { throw $message }
function Wait-Child([System.Diagnostics.Process]$p, [int]$seconds, [string]$stage) {
    try {
        if (-not $p.WaitForExit($seconds * 1000)) {
            try { $p.Kill() } catch { }
            Fail ("{0}: exceeded {1} seconds; stopped the waiting helper. Inspect the installation before retrying." -f $stage, $seconds)
        }
        return [int]$p.ExitCode
    } finally { $p.Dispose() }
}
function Assert-NoLinks([string]$path) {
    # Never recurse through junctions or symbolic links during uninstall.
    $stack = New-Object System.Collections.Stack
    $stack.Push($path)
    while ($stack.Count -gt 0) {
        $current = [string]$stack.Pop()
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            Fail ("A symbolic link or junction prevents safe removal: " + $current)
        }
        if ($item.PSIsContainer) {
            foreach ($child in @(Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop)) {
                $stack.Push($child.FullName)
            }
        }
    }
}
function Assert-ClosedForUninstall([string]$userSid) {
    if ($Mode -ne 'Uninstall') { return }
    $protectedExe = Join-Path (Join-Path (Join-Path $env:ProgramFiles 'ShamiGo') $userSid) 'ShamiGo.exe'
    $active = @(Get-Process -Name ShamiGo -ErrorAction SilentlyContinue | Where-Object {
        try { [string]$_.Path -ieq $protectedExe } catch { $false }
    })
    if ($active.Count -gt 0) {
        Fail 'ShamiGo is still running. Please exit ShamiGo from the system tray, then run Uninstall_Windows.cmd again. No files or scheduled tasks were changed.'
    }
}
function Check-TaskIdentity($task, [string]$expectedExe, [string]$sid, [string]$account) {
    $actual = [string]$task.Actions[0].Execute
    $isOwner = ([string]$task.Principal.UserId -eq $sid) -or
               ([string]$task.Principal.UserId -ieq $account)
    if ($task.Actions.Count -ne 1 -or $actual -ine $expectedExe -or -not $isOwner) {
        Fail 'A task with the ShamiGo name has an unexpected owner or executable. Refusing to overwrite/remove it.'
    }
}

try {
    # A random operation identifier associates the elevated log with the
    # initiating CMD, without letting unprivileged callers select an arbitrary
    # file for the elevated process to write.
    if ([string]::IsNullOrWhiteSpace($RunId)) { $RunId = [guid]::NewGuid().ToString('N') }
    if ($RunId -cnotmatch '^[a-f0-9]{32}$') { Fail 'Invalid internal operation identifier.' }
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $sid = $identity.User.Value
    if ($sid -notmatch '^S-1-[0-9-]+$') { Fail 'Cannot determine the current user SID.' }
    if ($Worker -ne 'None' -and -not $Elevated) { Fail 'Internal worker requires elevation.' }

    # Only the privileged child writes logs; the parent reads its exact
    # RunId after the child exits. We never accept a path from the command line.
    if ($Elevated) {
        $logFolder = Join-Path $env:LOCALAPPDATA 'ShamiGo\SetupLogs'
        if (-not (Test-Path -LiteralPath $logFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $logFolder -Force -ErrorAction Stop | Out-Null
        }
        $script:logPath = Join-Path $logFolder ('setup_{0}_{1}.log' -f $Mode,$RunId)
        Say ('ShamiGo ' + $Mode + ' started. Log: ' + $script:logPath)
        if ($ExpectedSid -ne $sid) {
            Say 'ERROR: Windows UAC used a different administrator account. For safety, configuration currently requires the signed-in account and UAC administrator account to be the same.'
            exit 20
        }
        $isAdmin = (New-Object System.Security.Principal.WindowsPrincipal($identity)).IsInRole(
            [System.Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) { Fail 'Administrator consent was not granted.' }
    }

    if (-not $Elevated) {
        # Avoid a partial uninstall: an active protected EXE would otherwise
        # block file deletion after the auto-start task has already been removed.
        Assert-ClosedForUninstall $sid
        Say ('ShamiGo v0.10.394: ' + $Mode)
        Say 'Requesting Windows administrator approval (one UAC prompt)...'
        $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $argText = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Elevated -ExpectedSid "{1}" -Mode {2} -RunId {3}' -f $PSCommandPath,$sid,$Mode,$RunId
        $p = Start-Process -FilePath $psExe -ArgumentList $argText -Verb RunAs -PassThru -ErrorAction Stop
        $exitCode = Wait-Child $p 130 'Administrator configuration'
        if ($exitCode -ne 0) {
            $reported = Join-Path $env:LOCALAPPDATA ('ShamiGo\SetupLogs\setup_{0}_{1}.log' -f $Mode,$RunId)
            if (Test-Path -LiteralPath $reported -PathType Leaf) {
                Say 'Administrator process diagnostic:'
                Get-Content -LiteralPath $reported -Tail 18 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
                Say ('Diagnostic log: ' + $reported)
            }
            if ($exitCode -eq 20) {
                Fail 'The UAC approval used a different Windows administrator account. Sign in as the account to uninstall and run this CMD, or use an administrator account to remove the installation for the correct user.'
            }
            Fail ('Administrator configuration failed (code {0}). Review the diagnostic above and the SetupLogs folder.' -f $exitCode)
        }
        Say 'Finished successfully. You may close this window.'
        exit 0
    }

    $releaseDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $installRoot = Join-Path $env:ProgramFiles 'ShamiGo'
    $installDir = Join-Path $installRoot $sid
    $installedExe = Join-Path $installDir 'ShamiGo.exe'
    $taskName = 'ShamiGo_AutoStart_Admin_' + $sid
    $taskPath = '\'

    if ($Worker -ne 'None') {
        # Isolated, elevated ScheduledTasks calls; the parent imposes a hard wait limit.
        Import-Module ScheduledTasks -ErrorAction Stop
        $old = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
        if ($null -ne $old) {
            Check-TaskIdentity $old $installedExe $sid $identity.Name
        }
        if ($Worker -eq 'RemoveTask') {
            if ($null -ne $old) {
                Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false -ErrorAction Stop
                Say 'Removed ShamiGo administrator logon task.'
            } else { Say 'No administrator logon task was installed.' }
            exit 0
        }
        if (-not (Test-Path -LiteralPath $installedExe -PathType Leaf)) {
            Fail 'Protected ShamiGo.exe does not exist; cannot schedule it.'
        }
        if ($null -ne $old) { Say 'Updating existing ShamiGo task...' }
        $action = New-ScheduledTaskAction -Execute $installedExe -WorkingDirectory $installDir
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $sid
        $principal = New-ScheduledTaskPrincipal -UserId $sid -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
            -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -Priority 4
        Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action `
            -Trigger $trigger -Principal $principal -Settings $settings `
            -Description 'Run protected ShamiGo at interactive logon with highest approved privileges.' `
            -Force -ErrorAction Stop | Out-Null
        $verify = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction Stop
        Check-TaskIdentity $verify $installedExe $sid $identity.Name
        if ([string]$verify.Principal.RunLevel -ne 'Highest') { Fail 'Task was not registered at highest privilege.' }
        Say 'Task verified: elevated ShamiGo at next Windows sign-in.'
        exit 0
    }

    function Run-TaskWorker([string]$kind) {
        $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $args = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Elevated -ExpectedSid "{1}" -Mode {2} -Worker {3}' -f $PSCommandPath,$sid,$Mode,$kind
        $stdout = Join-Path $logFolder ('task_{0}_{1}.out' -f $kind,$PID)
        $stderr = Join-Path $logFolder ('task_{0}_{1}.err' -f $kind,$PID)
        Say ('Updating Windows Task Scheduler (' + $kind + ')...')
        $p = Start-Process -FilePath $psExe -ArgumentList $args -PassThru -WindowStyle Hidden `
            -RedirectStandardOutput $stdout -RedirectStandardError $stderr -ErrorAction Stop
        $code = Wait-Child $p 40 'Windows Task Scheduler'
        if ($code -ne 0) {
            $detail = ''
            foreach ($file in @($stderr,$stdout)) {
                if (Test-Path -LiteralPath $file) {
                    $detail += ((Get-Content -LiteralPath $file -Tail 8 -ErrorAction SilentlyContinue) -join ' ') + ' '
                }
            }
            Fail ('Windows Task Scheduler failed (code {0}). {1}' -f $code,$detail)
        }
        Say ('Windows Task Scheduler completed (' + $kind + ').')
    }

    if ($Mode -eq 'Install') {
        Say '[1/3] Checking release files...'
        $versionFile = Join-Path $releaseDir 'VERSION.txt'
        if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf)) { Fail 'VERSION.txt missing: extract the complete ZIP first.' }
        $version = (Get-Content -LiteralPath $versionFile -Encoding ASCII -TotalCount 1).Trim()
        $match = [regex]::Match($version, '^ShamiGo v(0\.[0-9]+\.[0-9]+)$')
        if (-not $match.Success) { Fail 'VERSION.txt contains an invalid version.' }
        $portableExe = Join-Path $releaseDir ('ShamiGo_v' + $match.Groups[1].Value + '.exe')
        $setupExe = Join-Path $releaseDir 'ShamiGo_AdminSetup.exe'
        foreach ($file in @($portableExe,$setupExe)) {
            if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Fail ('Missing component: ' + $file) }
        }
        Say '[2/3] Installing protected copy (maximum 60 seconds)...'
        # IMPORTANT: do not use Start-Process -Wait. It waits for all descendants,
        # including processes that might stay alive. Wait for this exact helper PID.
        $p = Start-Process -FilePath $setupExe -ArgumentList '--setup-only' `
            -WorkingDirectory $releaseDir -PassThru -ErrorAction Stop
        $code = Wait-Child $p 60 'Native ShamiGo installer'
        if ($code -ne 0) { Fail ('Native installer returned exit code {0}. Close any old elevated ShamiGo and retry.' -f $code) }
        if (-not (Test-Path -LiteralPath $installedExe -PathType Leaf)) { Fail 'Protected ShamiGo.exe is missing after setup.' }
        $portableHash = (Get-FileHash -LiteralPath $portableExe -Algorithm SHA256).Hash
        if ((Get-FileHash -LiteralPath $installedExe -Algorithm SHA256).Hash -ne $portableHash) {
            Fail 'Protected executable differs from the packaged executable.'
        }
        Say '[3/3] Registering auto-start (maximum 40 seconds)...'
        Run-TaskWorker 'Register'
        Say 'SUCCESS: ShamiGo is installed. Elevated auto-start begins at the next Windows sign-in.'
        Say 'Normal sign-ins do not require another UAC prompt.'
        exit 0
    }

    # Recheck after elevation: the process may have started during the UAC prompt.
    Assert-ClosedForUninstall $sid
    Say '[1/2] Removing the ShamiGo auto-start task...'
    Run-TaskWorker 'RemoveTask'
    if ($Mode -eq 'Disable') {
        Say 'SUCCESS: auto-start disabled. ShamiGo program and user data remain installed.'
        exit 0
    }

    Say '[2/2] Removing protected ShamiGo installation...'
    if (-not (Test-Path -LiteralPath $installDir)) {
        Say 'SUCCESS: no protected installation found. Portable files and personal data were not deleted.'
        exit 0
    }
    # Confirm this exact user's protected directory before deleting anything.
    if ((Split-Path -Leaf $installDir) -ne $sid -or
        (Split-Path -Leaf (Split-Path -Parent $installDir)) -ne 'ShamiGo') {
        Fail 'Unexpected installation directory: refusing removal.'
    }
    Assert-NoLinks $installDir
    $running = @(Get-Process -Name ShamiGo -ErrorAction SilentlyContinue | Where-Object {
        try { $_.Path -ieq $installedExe } catch { $false }
    })
    if ($running.Count -gt 0) { Fail 'ShamiGo is still running. Exit it from the tray and run uninstall again.' }
    # Keep all non-EXE user data in a persistent per-user backup before removing.
    $backupBase = Join-Path $env:LOCALAPPDATA 'ShamiGo\UninstallBackups'
    if (-not (Test-Path -LiteralPath $backupBase -PathType Container)) {
        New-Item -ItemType Directory -Path $backupBase -Force -ErrorAction Stop | Out-Null
    }
    $backupDir = Join-Path $backupBase ('backup_{0}_{1}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'),[guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $backupDir -ErrorAction Stop | Out-Null
    $keepNames = @('ShamiGo.ini','ShamiGoCPP.ini','RemoteViewers.txt','liu.box',
                   'LicensedTables','Phonetics','Phrases')
    $saved = 0
    foreach ($name in $keepNames) {
        $source = Join-Path $installDir $name
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $backupDir $name) -Recurse -Force -ErrorAction Stop
            $saved++
        }
    }
    # Any unfamiliar file/directory is treated as user data, not as junk.
    $owned = @('ShamiGo.exe','ShamiGo.installing.tmp','ShamiGo.previous.tmp',
               'VERSION.txt','RELEASE_NOTES.txt','ShamiGo_Help.html','History') + $keepNames
    foreach ($item in @(Get-ChildItem -LiteralPath $installDir -Force -ErrorAction Stop)) {
        if ($owned -notcontains $item.Name) {
            Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $backupDir $item.Name) -Recurse -Force -ErrorAction Stop
            $saved++
        }
    }
    # Never delete any installed data if a backup copy failed.
    Say ('Preserved {0} user-data groups in: {1}' -f $saved,$backupDir)
    Remove-Item -LiteralPath $installDir -Force -Recurse -ErrorAction Stop
    if ((Test-Path -LiteralPath $installRoot -PathType Container) -and
        @((Get-ChildItem -LiteralPath $installRoot -Force -ErrorAction Stop)).Count -eq 0) {
        Remove-Item -LiteralPath $installRoot -Force -ErrorAction Stop
    }
    Say 'SUCCESS: removed protected ShamiGo and its scheduled task.'
    Say 'Your portable ZIP folder is untouched. Saved user files remain in the backup folder above.'
    exit 0
} catch {
    $message = 'ERROR: ' + $_.Exception.Message
    Say $message
    if ($script:logPath) { Say ('Diagnostic log: ' + $script:logPath) }
    exit 1
}
