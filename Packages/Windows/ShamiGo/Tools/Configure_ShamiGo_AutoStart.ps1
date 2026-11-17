# ShamiGo package v0.10.607 - SAC preflight and rollback-aware installation.
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
# 0283ac0f-fff1-49ae-ada1-8a933130cad6 is Microsoft's
# VerifiedAndReputableDesktop / Smart App Control enforcing policy.
# This checks compatibility; it does NOT modify SAC, WDAC, trust stores,
# execution restrictions or Windows Defender.
function Get-SmartAppControlState {
    try {
        $state = [int](Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' `
            -Name 'VerifiedAndReputablePolicyState' -ErrorAction Stop).VerifiedAndReputablePolicyState
        if ($state -eq 1) { return 'On' }
        if ($state -eq 2) { return 'Evaluation' }
        if ($state -eq 0) { return 'Off' }
    } catch { }
    # If the registry value is unavailable, check the documented active policy.
    $policyFile = Join-Path $env:SystemRoot ('System32\CodeIntegrity\CiPolicies\Active\' +
        '{0283ac0f-fff1-49ae-ada1-8a933130cad6}.cip')
    if (Test-Path -LiteralPath $policyFile -PathType Leaf) { return 'On' }
    return 'Unknown'
}
function Assert-InstallerAllowedBeforeChanges {
    if ($Mode -ne 'Install') { return }
    $state = Get-SmartAppControlState
    $release = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    # Verify only the executable components used by the installer.
    $blockedComponents = New-Object 'System.Collections.Generic.List[string]'
    foreach ($name in @('ShamiGo.exe','ShamiGo_AdminLauncher.exe')) {
        $binary = Join-Path $release $name
        if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) {
            Fail ('Required component is missing: ' + $binary)
        }
        $signature = Get-AuthenticodeSignature -FilePath $binary -ErrorAction Stop
        Say ('Preflight: Smart App Control={0}; {1} signature={2}' -f $state,$name,$signature.Status)
        if ($signature.Status -ne 'Valid') { $blockedComponents.Add($name + ' (' + $signature.Status + ')') }
    }
    if ($state -eq 'On' -and $blockedComponents.Count -gt 0) {
        $detail = 'Windows 11 Smart App Control (VerifiedAndReputableDesktop, policy 0283ac0f-fff1-49ae-ada1-8a933130cad6) is ON. The following ShamiGo executables do not have a valid trusted Authenticode signature: ' + ($blockedComponents -join ', ') + '. Windows event 3077 may block it. This install was stopped BEFORE the old ShamiGo, logon task or preferences were changed. Do not turn off Smart App Control to run this installer. A trusted signed release is required for supported installation on this PC. You can test the separate portable Run_Windows.cmd, but Windows may also block the unsigned main executable.'
        $downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
        if (Test-Path -LiteralPath $downloads -PathType Container) {
            $note = Join-Path $downloads 'ShamiGo_Install_SmartAppControl_Block.txt'
            try {
                @('ShamiGo v0.10.607 installation preflight',
                  ('Detected: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
                  ('Smart App Control: ' + $state),
                  ('Unsigned or untrusted components: ' + ($blockedComponents -join ', ')),
                  $detail) | Set-Content -LiteralPath $note -Encoding UTF8 -ErrorAction Stop
                Say ('Saved diagnostic: ' + $note)
            } catch { Say ('Cannot write the optional Downloads diagnostic: ' + $_.Exception.Message) }
        }
        Fail $detail
    }
}
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
# Terminate only an identified ShamiGo runtime of the user that is installing.
# The old executable can be running from the protected directory, ZipPortable,
# or a user-extracted private ZIP, including historical versioned EXE names.
# Never terminate unknown processes, another user's session, or the setup helper.
function Get-OldShamiGoRuntimes([string]$expectedSid) {
    $processList = New-Object 'System.Collections.Generic.List[object]'
    $candidates = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'ShamiGo%.exe'" -ErrorAction Stop)
    foreach ($entry in $candidates) {
        $name = [string]$entry.Name
        if ($name -notmatch '^ShamiGo(?:_v[0-9]+[.][0-9]+[.][0-9]+)?[.]exe$') { continue }
        $pidValue = [int]$entry.ProcessId
        if ($pidValue -le 4 -or $pidValue -eq $PID) { continue }
        # A process may disappear between the enumeration and the SID query.
        if ($null -eq (Get-Process -Id $pidValue -ErrorAction SilentlyContinue)) { continue }
        try {
            $owner = Invoke-CimMethod -InputObject $entry -MethodName GetOwnerSid -ErrorAction Stop
        } catch {
            if ($null -eq (Get-Process -Id $pidValue -ErrorAction SilentlyContinue)) { continue }
            Fail ('Cannot verify the owner of running ShamiGo PID {0}, path="{1}": {2}. Refusing to stop any unverified process.' -f
                $pidValue,[string]$entry.ExecutablePath,$_.Exception.Message)
        }
        if ([int]$owner.ReturnValue -ne 0 -or [string]$owner.Sid -notmatch '^S-1-[0-9-]+$') {
            Fail ('Cannot verify ShamiGo PID {0} owner SID (code {1}), image="{2}". No unrelated process will be terminated.' -f
                $pidValue,[int]$owner.ReturnValue,[string]$entry.ExecutablePath)
        }
        if ([string]$owner.Sid -ne $expectedSid) {
            Say ('Leaving other-user ShamiGo PID {0} unchanged; owner SID={1}' -f $pidValue,$owner.Sid)
            continue
        }
        $processList.Add([pscustomobject]@{
            Id=$pidValue
            Name=$name
            Path=[string]$entry.ExecutablePath
        })
    }
    return @($processList.ToArray())
}
# Send WM_CLOSE only to the native ShamiGo window owned by the exact PID
# already verified through Win32_Process.GetOwnerSid. The fallback below
# terminates that same verified process if an old build lacks this window.
function Request-ShamiGoGracefulExit([int]$processId) {
    try {
        if (-not ('ShamiGoInstallWindow' -as [type])) {
            $cs = @'
using System;
using System.Runtime.InteropServices;
public static class ShamiGoInstallWindow {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern IntPtr FindWindow(string className, string title);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
}
'@
            Add-Type -TypeDefinition $cs -ErrorAction Stop
        }
        $window = [ShamiGoInstallWindow]::FindWindow('ShamiGoCpp186','ShamiGo native host')
        if ($window -eq [IntPtr]::Zero) { return $false }
        [uint32]$windowPid=0
        [void][ShamiGoInstallWindow]::GetWindowThreadProcessId($window,[ref]$windowPid)
        if ($windowPid -ne $processId) { return $false }
        if (-not [ShamiGoInstallWindow]::PostMessage($window,0x0010,[IntPtr]::Zero,[IntPtr]::Zero)) { return $false }
        Say ('Requested graceful ShamiGo shutdown for verified PID {0}.' -f $processId)
        return $true
    } catch {
        Say ('Graceful close unavailable; using verified-process fallback: ' + $_.Exception.Message)
        return $false
    }
}
function Stop-ExistingShamiGo([string]$expectedSid) {
    Say 'Stopping verified old ShamiGo instances before replacing executable files...'
    $stable = 0
    # A prior task may be exiting at the same time. Recheck until two
    # consecutive quiet observations; do not race a still-loaded image.
    for ($pass=1; $pass -le 12; $pass++) {
        $running = @(Get-OldShamiGoRuntimes $expectedSid)
        if ($running.Count -eq 0) {
            $stable++
            if ($stable -ge 2) { return }
            Start-Sleep -Milliseconds 250
            continue
        }
        $stable = 0
        foreach ($process in $running) {
            $processId = [int]$process.Id
            Say ('Old ShamiGo: PID={0}, image="{1}", path="{2}"; stopping ({3}/12).' -f
                $processId,$process.Name,$process.Path,$pass)
            # The input method needs a chance to unregister its low-level
            # hooks, flush settings and release audio handles before removal.
            if (Request-ShamiGoGracefulExit $processId) {
                $grace=(Get-Date).AddSeconds(2)
                while ($null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue) -and
                       (Get-Date) -lt $grace) { Start-Sleep -Milliseconds 100 }
            }
            if ($null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
                Say ('Old ShamiGo PID {0} did not exit; forcing verified runtime shutdown.' -f $processId)
                # Re-verify PID/image before force-stop to avoid PID reuse.
                $live=Get-CimInstance Win32_Process -Filter ('ProcessId = {0}' -f $processId) -ErrorAction SilentlyContinue
                if ($null -eq $live) {
                    # If the old PID no longer exists, no force-stop is needed.
                    # If CIM cannot re-verify a still-running PID, fail safely.
                    if ($null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
                        Fail ('Cannot re-verify running ShamiGo PID {0}. No unknown process will be terminated.' -f $processId)
                    }
                    continue
                }
                if ([string]$live.Name -ine $process.Name -or
                    [string]$live.ExecutablePath -ine $process.Path) {
                    Fail ('Process identity changed for PID {0} during shutdown. Aborting installation.' -f $processId)
                }
                try {
                    Stop-Process -Id $processId -Force -ErrorAction Stop
                } catch {
                    if ($null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
                        Fail ('Unable to terminate old ShamiGo PID {0}: {1}' -f
                            $processId,$_.Exception.Message)
                    }
                }
            }
            $deadline=(Get-Date).AddSeconds(8)
            while ($null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue) -and
                   (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 125 }
            if ($null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
                Fail ('Old ShamiGo PID {0} is still active after termination. Installation was stopped to preserve the previous files.' -f $processId)
            }
        }
        Start-Sleep -Milliseconds 250
    }
    $remaining = @(Get-OldShamiGoRuntimes $expectedSid)
    if ($remaining.Count -gt 0) {
        $details = ($remaining | ForEach-Object { '{0}: {1}' -f $_.Id,$_.Path }) -join '; '
        Fail ('Old ShamiGo keeps restarting: {0}. Installation cannot safely replace a running EXE.' -f $details)
    }
}
function Backup-And-RemoveInstalledShamiGo([string]$directory,[string]$ownerSid) {
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { return $null }
    if ((Split-Path -Leaf $directory) -ne $ownerSid -or
        (Split-Path -Leaf (Split-Path -Parent $directory)) -ne 'ShamiGo') {
        Fail 'Unexpected protected installation path: refusing to delete.'
    }
    $protectedRoot = Split-Path -Parent $directory
    $rootItem = Get-Item -LiteralPath $protectedRoot -Force -ErrorAction Stop
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        Fail 'Protected ShamiGo root is a link; refusing to remove it.'
    }
    Assert-NoLinks $directory
    $parent = Join-Path $env:LOCALAPPDATA 'ShamiGo\InstallBackups'
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
    }
    $backup = Join-Path $parent ('pre_reinstall_{0}_{1}' -f
        (Get-Date -Format 'yyyyMMdd_HHmmss'),[guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $backup -ErrorAction Stop | Out-Null
    # The *program* and previous History are removed, not retained as old
    # installable binaries. Personal settings, licensed tables and unknown
    # user-created files are copied first. Any copy failure aborts removal.
    $obsolete = @('ShamiGo.exe','ShamiGo.installing.tmp',
                  'ShamiGo.previous.tmp','VERSION.txt','RELEASE_NOTES.txt',
                  'ShamiGo_Help.html','History')
    $saved = 0
    foreach ($entry in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
        if ($obsolete -contains $entry.Name) { continue }
        Copy-Item -LiteralPath $entry.FullName -Destination (Join-Path $backup $entry.Name) `
            -Recurse -Force -ErrorAction Stop
        $saved++
    }
    Say ("Backed up {0} personal-data entries to {1}" -f $saved,$backup)
    # Do not remove the old installation here. The caller first makes
    # an atomic sibling rename and retains it until new setup is complete.
    return $backup
}
function Restore-PreviousPreferences([string]$backup,[string]$destination) {
    if ([string]::IsNullOrWhiteSpace($backup)) { return }
    # Fresh binaries and dictionaries come from this release, but the user's
    # hotkeys, timing and UI preferences should not silently disappear.
    foreach ($name in @('ShamiGoCPP.ini','ShamiGo.ini','RemoteViewers.txt','liu.box')) {
        $from = Join-Path $backup $name
        if (Test-Path -LiteralPath $from -PathType Leaf) {
            if ($name -eq 'liu.box' -and (Test-Path -LiteralPath (Join-Path $destination $name) -PathType Leaf)) { continue }
            Copy-Item -LiteralPath $from -Destination (Join-Path $destination $name) `
                -Force -ErrorAction Stop
            Say ('Restored user preference file: ' + $name)
        }
    }
    foreach ($folderName in @('LicensedTables','Phonetics','Phrases')) {
        $oldFolder = Join-Path $backup $folderName
        if (-not (Test-Path -LiteralPath $oldFolder -PathType Container)) { continue }
        $newFolder = Join-Path $destination $folderName
        [IO.Directory]::CreateDirectory($newFolder) | Out-Null
        foreach ($oldFile in @(Get-ChildItem -LiteralPath $oldFolder -File -Recurse -Force -ErrorAction Stop)) {
            # Use substring after the separator; no [char]'\\' conversion.
            $relative = $oldFile.FullName.Substring($oldFolder.Length + 1)
            $newFile = Join-Path $newFolder $relative
            if ([IO.File]::Exists($newFile)) { continue }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($newFile)) | Out-Null
            Copy-Item -LiteralPath $oldFile.FullName -Destination $newFile -ErrorAction Stop
        }
        Say ('Preserved missing previous-user files in: ' + $folderName)
    }
}
# Windows Task Scheduler may serialize a valid task with a quoted executable,
# an expandable environment variable, or an NT account name instead of a SID.
# Compare canonical paths and resolved security identities, never loose substrings.
function Resolve-ShamiGoTaskPath([string]$value) {
    $path = $value.Trim()
    if ($path.Length -ge 2 -and $path.StartsWith('"') -and $path.EndsWith('"')) {
        $path = $path.Substring(1, $path.Length - 2)
    }
    $path = [Environment]::ExpandEnvironmentVariables($path)
    if (-not [IO.Path]::IsPathRooted($path)) { return '' }
    try { return [IO.Path]::GetFullPath($path).TrimEnd([char]'\') }
    catch { return '' }
}
function Resolve-ShamiGoTaskSid([string]$principal) {
    $value = $principal.Trim()
    if ($value -match '^S-1-[0-9-]+$') { return $value }
    if ([string]::IsNullOrWhiteSpace($value)) { return '' }
    try {
        $account = New-Object System.Security.Principal.NTAccount($value)
        return $account.Translate([System.Security.Principal.SecurityIdentifier]).Value
    } catch { return '' }
}
function Check-TaskIdentity($task, [string]$expectedExe, [string]$sid, [string]$account) {
    $actions = @($task.Actions)
    $principal = [string]$task.Principal.UserId
    $resolvedSid = Resolve-ShamiGoTaskSid $principal
    $sameUser = ($resolvedSid -eq $sid) -or ($principal -ieq $account)
    $actualText = if ($actions.Count -eq 1) { [string]$actions[0].Execute } else { '' }
    $argsText = if ($actions.Count -eq 1) { [string]$actions[0].Arguments } else { '' }
    $workText = if ($actions.Count -eq 1) { [string]$actions[0].WorkingDirectory } else { '' }
    $actual = Resolve-ShamiGoTaskPath $actualText
    $expected = Resolve-ShamiGoTaskPath $expectedExe
    $normalAction = ($actual.Length -gt 0 -and $actual -ieq $expected)
    $legacyAction = $false
    if ($actual.Length -gt 0 -and -not $normalAction) {
        # Only recognize exact, per-user historical ShamiGo locations. Never
        # accept arbitrary paths just because the basename contains ShamiGo.
        $allowedFolders = @(
            (Join-Path (Join-Path $env:ProgramFiles 'ShamiGo') $sid),
            (Join-Path $env:ProgramFiles 'ShamiGo'),
            (Join-Path $env:LOCALAPPDATA 'ShamiGo'),
            (Join-Path (Join-Path $env:LOCALAPPDATA 'ShamiGo') 'ZipPortable')
        )
        $leaf = [IO.Path]::GetFileName($actual)
        if ($leaf -match '^ShamiGo(?:_v0[.]10[.][0-9]+|_AdminLauncher)?[.]exe$') {
            $folder = [IO.Path]::GetDirectoryName($actual)
            foreach ($candidate in $allowedFolders) {
                if ($folder -ieq (Resolve-ShamiGoTaskPath $candidate)) {
                    $legacyAction = $true
                    break
                }
            }
        }
    }
    # A clean legacy task has a single direct executable action. A command
    # with custom arguments or a foreign working directory is not auto-removed.
    $argumentsSafe = [string]::IsNullOrWhiteSpace($argsText)
    $workingSafe = [string]::IsNullOrWhiteSpace($workText) -or
        ((Resolve-ShamiGoTaskPath $workText) -ieq [IO.Path]::GetDirectoryName($actual))
    $approved = $actions.Count -eq 1 -and $sameUser -and $argumentsSafe -and
        $workingSafe -and ($normalAction -or $legacyAction)
    if (-not $approved) {
        Say ('Existing ShamiGo task identity: principal="{0}" (resolved SID="{1}"); actionCount={2}; execute="{3}"; arguments="{4}"; workingDirectory="{5}"' -f
            $principal,$resolvedSid,$actions.Count,$actualText,$argsText,$workText)
        Say ('Expected signed-in SID="{0}"; canonical executable="{1}"' -f $sid,$expected)
        Fail ('Existing ShamiGo scheduled task is not verified (sameUser={0}, actionValid={1}, argumentsSafe={2}, workingDirectorySafe={3}). No task was removed. Inspect SetupLogs or use Get-ScheduledTask to review the existing task.' -f
            $sameUser,($normalAction -or $legacyAction),$argumentsSafe,$workingSafe)
    }
    if ($legacyAction) {
        Say ('Verified legacy ShamiGo logon task for this user: ' + $actual)
    }
}
# Restore the exact previous scheduled task XML when an upgrade fails. A prior
# portable or older protected executable must not silently become a different
# autostart command during rollback.
function Restore-SavedTask {
    if ([string]::IsNullOrWhiteSpace($script:previousTaskXml)) { return }
    Import-Module ScheduledTasks -ErrorAction Stop
    $current = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    if ($null -ne $current) {
        Check-TaskIdentity $current $installedExe $sid $identity.Name
    }
    Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Xml $script:previousTaskXml `
        -Force -ErrorAction Stop | Out-Null
    $restored = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction Stop
    Check-TaskIdentity $restored $installedExe $sid $identity.Name
    Say 'ROLLBACK: exact previous ShamiGo startup task was restored.'
}

# Rollback markers are scoped to the current elevated installation only.
$script:rollbackDir = $null
$script:installDirToRestore = $null
$script:installCompleted = $false
$script:taskRemovedForInstall = $false
$script:hadExistingInstallation = $false
$script:hadPreviousStartupTask = $false
$script:previousTaskXml = $null
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
        # The elevated Uninstall action removes our autostart task and then
        # gracefully closes every verified same-user ShamiGo before deleting.
        # Never refuse removal merely because ShamiGo is running.
        Assert-InstallerAllowedBeforeChanges
        Say ('ShamiGo package v0.10.607: ' + $Mode + ' (native setup component v0.10.607)')
        Say 'Requesting Windows administrator approval (one UAC prompt)...'
        $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $argText = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Elevated -ExpectedSid "{1}" -Mode {2} -RunId {3}' -f $PSCommandPath,$sid,$Mode,$RunId
        $p = Start-Process -FilePath $psExe -ArgumentList $argText -Verb RunAs -PassThru -ErrorAction Stop
        $adminWaitSeconds = if ($Mode -eq 'Uninstall') { 360 } else { 130 }
        $exitCode = Wait-Child $p $adminWaitSeconds 'Administrator configuration'
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
        Say 'Finished successfully. Installation console will close automatically.'
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
                # Unregistering the task alone does not necessarily stop its
                # running instance. Stop it first, then close any remaining
                # same-user ShamiGo process in the parent setup stage.
                if ([string]$old.State -eq 'Running') {
                    Say 'Stopping the running, verified ShamiGo scheduled task...'
                    try {
                        Stop-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction Stop
                    } catch {
                        Say ('The running task could not be stopped directly; the parent will validate and close its runtime: ' + $_.Exception.Message)
                    }
                }
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
        Say '[1/5] Checking release files...'
        $versionFile = Join-Path $releaseDir 'VERSION.txt'
        if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf)) { Fail 'VERSION.txt missing: extract the complete ZIP first.' }
        $packageMarker = Join-Path $releaseDir 'PACKAGE_VERSION.txt'
        if (-not (Test-Path -LiteralPath $packageMarker -PathType Leaf)) {
            Fail 'PACKAGE_VERSION.txt missing: extract the complete v607 release.'
        }
        if ((Get-Content -LiteralPath $packageMarker -Encoding ASCII -TotalCount 1).Trim() -cne
            'ShamiGo package v0.10.607') { Fail 'Package/installer version mismatch.' }
        $version = (Get-Content -LiteralPath $versionFile -Encoding ASCII -TotalCount 1).Trim()
        $match = [regex]::Match($version, '^ShamiGo v(0\.[0-9]+\.[0-9]+)$')
        if (-not $match.Success) { Fail 'VERSION.txt contains an invalid version.' }
        $portableExe = Join-Path $releaseDir 'ShamiGo.exe'
        foreach ($file in @($portableExe)) {
            if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Fail ('Missing component: ' + $file) }
        }
        # Repeat after elevation: policies and files can change during UAC.
        Assert-InstallerAllowedBeforeChanges
        $script:hadExistingInstallation = (Test-Path -LiteralPath $installedExe -PathType Leaf)
        Import-Module ScheduledTasks -ErrorAction Stop
        $previousTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
        if ($null -ne $previousTask) {
            Check-TaskIdentity $previousTask $installedExe $sid $identity.Name
            $script:previousTaskXml = Export-ScheduledTask -TaskName $taskName `
                -TaskPath $taskPath -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($script:previousTaskXml)) {
                Fail 'Could not back up the existing ShamiGo logon task; no changes made.'
            }
            $script:hadPreviousStartupTask = $true
        }
        # Remove the verified logon task BEFORE stopping the old process.
        # Otherwise ShamiGo can restart during the executable replacement.
        # The catch handler re-registers the old task if installation aborts.
        Say '[2/5] Disabling old ShamiGo auto-start, then closing all old runtime processes...'
        $script:taskRemovedForInstall = $true
        Run-TaskWorker 'RemoveTask'
        Stop-ExistingShamiGo $sid
        # Close any late old instance that appeared while the helper returned.
        # Do this before moving the protected directory or touching private data.
        Stop-ExistingShamiGo $sid
        Say '[3/5] Backing up settings and removing the previous version from the active install path...'
        $savedPreferences = Backup-And-RemoveInstalledShamiGo $installDir $sid
        if (Test-Path -LiteralPath $installDir -PathType Container) {
            # Atomic same-volume rename: unlike Delete, the previous EXE and
            # personal files remain restorable until setup and task checks pass.
            $rollbackName = $sid + '.rollback.' + [guid]::NewGuid().ToString('N')
            $rollbackPath = Join-Path $installRoot $rollbackName
            if (Test-Path -LiteralPath $rollbackPath) { Fail 'Rollback path already exists.' }
            Rename-Item -LiteralPath $installDir -NewName $rollbackName -ErrorAction Stop
            $script:rollbackDir = $rollbackPath
            $script:installDirToRestore = $installDir
            Say ('Old version uninstalled from active path; rollback copy retained until new installation succeeds: ' + $rollbackPath)
        }
        # The previous task was stopped before process termination; old
        # binaries remain in the rollback folder until success is verified.
        Say '[4/5] Installing a clean protected copy from the extracted release...'
        # Avoid ShamiGo_AdminSetup.exe --setup-only (Windows error 2 on v607).
        # Source binaries are already verified by the caller; the old directory
        # remains available for rollback until the new task is registered.
        # An unlicensed public package may start in English-only mode.
        # Import_LicensedTables.ps1 creates TableSourcePath.txt before UAC,
        # allowing the installed runtime to load tables added after setup.
        if (-not (Test-Path -LiteralPath (Join-Path $releaseDir 'TableSourcePath.txt') -PathType Leaf)) {
            Fail 'Table source configuration is missing; use Install_Windows.cmd.'
        }
        Assert-NoLinks $releaseDir
        [IO.Directory]::CreateDirectory($installDir) | Out-Null
        foreach ($entry in @(Get-ChildItem -LiteralPath $releaseDir -Force -ErrorAction Stop)) {
            Copy-Item -LiteralPath $entry.FullName -Destination (Join-Path $installDir $entry.Name) `
                -Force -Recurse -ErrorAction Stop
        }
        Say 'Protected files copied successfully without native setup helper.'
        if (-not (Test-Path -LiteralPath $installedExe -PathType Leaf)) { Fail 'Protected ShamiGo.exe is missing after setup.' }
        $portableHash = (Get-FileHash -LiteralPath $portableExe -Algorithm SHA256).Hash
        if ((Get-FileHash -LiteralPath $installedExe -Algorithm SHA256).Hash -ne $portableHash) {
            Fail 'Protected executable differs from the packaged executable.'
        }
        Restore-PreviousPreferences $savedPreferences $installDir
        Say '[5/5] Registering auto-start (maximum 40 seconds)...'
        Run-TaskWorker 'Register'
        # Mark success before optional cleanup; cleanup failure must not roll
        # back a functioning new installation.
        $script:installCompleted = $true
        if ($script:rollbackDir -and (Test-Path -LiteralPath $script:rollbackDir)) {
            try {
                Assert-NoLinks $script:rollbackDir
                Remove-Item -LiteralPath $script:rollbackDir -Recurse -Force -ErrorAction Stop
                Say 'Previous protected binaries cleared after successful verification.'
            } catch {
                Say ('WARNING: installation succeeded, but old rollback directory was retained: ' + $script:rollbackDir)
            }
        }
        try {
            Start-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction Stop
            Say 'Started the installed ShamiGo task for this Windows session.'
        } catch {
            Say ('WARN: installed successfully but auto-start now failed: ' + $_.Exception.Message)
        }
        Say 'SUCCESS: ShamiGo installed; elevated auto-start is registered for future sign-ins.'
        Say 'Normal sign-ins do not require another UAC prompt.'
        exit 0
    }

    if ($Mode -eq 'Disable') {
        Say 'Removing the current-user ShamiGo auto-start task...'
        Run-TaskWorker 'RemoveTask'
        Say 'SUCCESS: auto-start disabled. ShamiGo program and user data remain installed.'
        exit 0
    }

    # Full uninstall is intentionally different from reinstall: NONE of the
    # installed preferences, licensed-table COPIES, cache or backups are kept.
    # It must never remove the downloaded ZIP, the extracted release source,
    # other Windows users' installations, or unrelated Program Files entries.
    if ($Mode -ne 'Uninstall') { Fail 'Unexpected administrator operation.' }
    Say '[1/4] Checking complete-uninstall scope and disabling automatic restart...'
    $localBase = [Environment]::GetFolderPath('LocalApplicationData')
    $roamingBase = [Environment]::GetFolderPath('ApplicationData')
    if ([string]::IsNullOrWhiteSpace($localBase) -or
        [string]::IsNullOrWhiteSpace($roamingBase)) {
        Fail 'Cannot locate the current user application-data folders safely.'
    }
    $localOwned = Join-Path $localBase 'ShamiGo'
    $roamingOwned = Join-Path $roamingBase 'ShamiGo'
    $programBase = [IO.Path]::GetFullPath($env:ProgramFiles)
    $installedExpected = Join-Path (Join-Path $programBase 'ShamiGo') $sid
    if ([IO.Path]::GetFullPath($installDir) -ine
        [IO.Path]::GetFullPath($installedExpected)) {
        Fail 'The protected install path is outside the current user ShamiGo scope.'
    }
    if ([IO.Path]::GetFileName($localOwned) -cne 'ShamiGo' -or
        [IO.Path]::GetFileName($roamingOwned) -cne 'ShamiGo') {
        Fail 'Application data path scope validation failed.'
    }
    if (Test-Path -LiteralPath $installRoot -PathType Container) {
        $rootInfo = Get-Item -LiteralPath $installRoot -Force -ErrorAction Stop
        if (($rootInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Fail 'Protected program root is a symlink or junction; refusing deletion.'
        }
    }
    if (Test-Path -LiteralPath $installDir) { Assert-NoLinks $installDir }
    if (Test-Path -LiteralPath $localOwned) { Assert-NoLinks $localOwned }
    if (Test-Path -LiteralPath $roamingOwned) { Assert-NoLinks $roamingOwned }
    # Leftover same-account rollback folders are previous INSTALL artifacts,
    # not personal project folders. Never touch other users' SID directories.
    $rollbackPattern = '^' + [regex]::Escape($sid) + '[.]rollback[.][a-f0-9]{32}$'
    $staleRollbacks = @()
    if (Test-Path -LiteralPath $installRoot -PathType Container) {
        $staleRollbacks = @(Get-ChildItem -LiteralPath $installRoot -Directory -Force -ErrorAction Stop |
            Where-Object { $_.Name -match $rollbackPattern })
        foreach ($entry in $staleRollbacks) { Assert-NoLinks $entry.FullName }
    }
    # A task may start a new instance while an old one closes. Remove the
    # verified task first, then close only processes owned by THIS user's SID.
    Run-TaskWorker 'RemoveTask'
    Say '[2/4] Closing running ShamiGo instances (including portable instances)...'
    Stop-ExistingShamiGo $sid
    Stop-ExistingShamiGo $sid
    if (@(Get-OldShamiGoRuntimes $sid).Count -ne 0) {
        Fail 'ShamiGo remained active: no installed files were deleted.'
    }

    Say '[3/4] Deleting the current-user protected install and program data...'
    # Recheck after stopping: another process could have changed the folders.
    if (Test-Path -LiteralPath $installDir) {
        Assert-NoLinks $installDir
        Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction Stop
    }
    foreach ($entry in $staleRollbacks) {
        if (Test-Path -LiteralPath $entry.FullName) {
            Assert-NoLinks $entry.FullName
            Remove-Item -LiteralPath $entry.FullName -Recurse -Force -ErrorAction Stop
        }
    }
    if (Test-Path -LiteralPath $installRoot -PathType Container) {
        if (@(Get-ChildItem -LiteralPath $installRoot -Force -ErrorAction Stop).Count -eq 0) {
            Remove-Item -LiteralPath $installRoot -Force -ErrorAction Stop
        }
    }
    # LocalAppData\ShamiGo owns Dictionaries, LicensedTables copies, ZipPortable
    # cache, SetupLogs, previous InstallBackups and UninstallBackups. Keep
    # none after full uninstall. Do not re-create a log in the removed folder.
    if (Test-Path -LiteralPath $localOwned) {
        Assert-NoLinks $localOwned
        $script:logPath = $null
        Remove-Item -LiteralPath $localOwned -Recurse -Force -ErrorAction Stop
    }
    # Older releases may also have written ShamiGo-specific roaming settings.
    if (Test-Path -LiteralPath $roamingOwned) {
        Assert-NoLinks $roamingOwned
        Remove-Item -LiteralPath $roamingOwned -Recurse -Force -ErrorAction Stop
    }

    Say '[4/4] Verifying no current-user ShamiGo installation remains...'
    Import-Module ScheduledTasks -ErrorAction Stop
    if ($null -ne (Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue)) {
        Fail 'ShamiGo scheduled task still exists; uninstall is incomplete.'
    }
    if ((Test-Path -LiteralPath $installDir) -or
        (Test-Path -LiteralPath $localOwned) -or
        (Test-Path -LiteralPath $roamingOwned)) {
        Fail 'ShamiGo installation or application-data directory still exists.'
    }
    if (Test-Path -LiteralPath $installRoot -PathType Container) {
        if (@(Get-ChildItem -LiteralPath $installRoot -Directory -Force -ErrorAction Stop |
            Where-Object { $_.Name -match $rollbackPattern }).Count -gt 0) {
            Fail 'An old same-user ShamiGo rollback folder remains.'
        }
    }
    if (@(Get-OldShamiGoRuntimes $sid).Count -ne 0) {
        Fail 'A ShamiGo process started again during uninstall.'
    }
    Say 'SUCCESS: all current-user installed ShamiGo files, settings, dictionaries, cache, backups and auto-start task were removed.'
    Say 'The original ZIP or manually extracted release directory was not changed.'
    exit 0
 } catch {
    $failureReason = $_.Exception.Message
    if ($Mode -eq 'Install' -and -not $script:installCompleted -and
        -not [string]::IsNullOrWhiteSpace($script:rollbackDir) -and
        (Test-Path -LiteralPath $script:rollbackDir -PathType Container)) {
        try {
            # Only the protected directory selected from the current user's
            # validated SID is eligible for rollback. Never follow links.
            if (Test-Path -LiteralPath $script:installDirToRestore) {
                Assert-NoLinks $script:installDirToRestore
                Remove-Item -LiteralPath $script:installDirToRestore -Recurse -Force -ErrorAction Stop
            }
            $sidName = Split-Path -Leaf $script:installDirToRestore
            Rename-Item -LiteralPath $script:rollbackDir -NewName $sidName -ErrorAction Stop
            Say 'ROLLBACK: previous protected ShamiGo installation was restored.'
            try {
                if ($script:hadPreviousStartupTask) {
                    Restore-SavedTask
                }
            } catch {
                Say ('WARNING: previous program restored but auto-start could not be restored: ' + $_.Exception.Message)
            }
        } catch {
            Say ('CRITICAL: automatic rollback failed. Previous data remains at ' +
                 $script:rollbackDir + '. Detail: ' + $_.Exception.Message)
        }
    }
    if ($Mode -eq 'Install' -and -not $script:installCompleted -and
        $script:taskRemovedForInstall -and $script:hadPreviousStartupTask -and
        [string]::IsNullOrWhiteSpace($script:rollbackDir)) {
        # Task was removed but the old installation was not yet staged.
        # A valid legacy task may point to a separate portable executable, so
        # restore its saved XML rather than assuming a protected EXE exists.
        try {
            Restore-SavedTask
        } catch {
            Say ('WARNING: could not restore previous startup task: ' + $_.Exception.Message)
        }
    }
    $message = 'ERROR: ' + $failureReason
    Say $message
    if ($script:logPath) {
        Say ('Diagnostic log: ' + $script:logPath)
        try {
            $downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
            if ([IO.Directory]::Exists($downloads)) {
                Copy-Item -LiteralPath $script:logPath -Destination (Join-Path $downloads 'ShamiGo_Install_Last_Error.log') -Force -ErrorAction Stop
                Say ('A copy of the failure log was saved to Downloads.')
            }
        } catch { Say ('Could not copy the optional Downloads log: ' + $_.Exception.Message) }
    }
    exit 1
}
