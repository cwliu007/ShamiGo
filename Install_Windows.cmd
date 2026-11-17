@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "SHAMIGO_ROOT=%~dp0"
set "SHAMIGO_WIN=%SHAMIGO_ROOT%Packages\Windows\ShamiGo"
if not exist "%SHAMIGO_WIN%\ShamiGo.exe" goto zip_boot
if not exist "%SHAMIGO_WIN%\Tools\Import_LicensedTables.ps1" goto zip_boot
if not exist "%SHAMIGO_WIN%\Tools\Prepare_ECDICT.ps1" goto zip_boot
if not exist "%SHAMIGO_ROOT%Data\EnglishECDICT.tar.xz" goto zip_boot
if not exist "%SHAMIGO_ROOT%Data\EnglishChineseReverse.tar.xz" goto zip_boot
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SHAMIGO_WIN%\Tools\Import_LicensedTables.ps1" -ReleaseRoot "%SHAMIGO_ROOT%."
if errorlevel 1 goto failed
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SHAMIGO_WIN%\Tools\Prepare_ECDICT.ps1" -Archive "%SHAMIGO_ROOT%Data\EnglishECDICT.tar.xz" -UsageArchive "%SHAMIGO_ROOT%Data\EnglishUsage.tar.xz" -ReverseArchive "%SHAMIGO_ROOT%Data\EnglishChineseReverse.tar.xz"
if errorlevel 1 goto failed
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SHAMIGO_WIN%\Tools\Configure_ShamiGo_AutoStart.ps1" -Mode Install
if errorlevel 1 goto failed
echo [ShamiGo] Windows installation finished.
exit /b 0

:failed
set "SHAMIGO_RC=%ERRORLEVEL%"
if "%SHAMIGO_RC%"=="0" set "SHAMIGO_RC=2"
echo [ShamiGo] The command could not complete. See the error above.
pause
exit /b %SHAMIGO_RC%
:zip_boot
set "SHAMIGO_BOOT_CMD=%~f0"
set "SHAMIGO_BOOT_ZIP=%~1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SHAMIGO_BOOT_CMD,[Text.Encoding]::ASCII);$a=$s.LastIndexOf('::SHAMIGO_PS_BEGIN');$b=$s.LastIndexOf('::SHAMIGO_PS_END');if($a -lt 0 -or $b -le $a){exit 2};& ([ScriptBlock]::Create($s.Substring($a+'::SHAMIGO_PS_BEGIN'.Length,$b-$a-'::SHAMIGO_PS_BEGIN'.Length)))"
set "SHAMIGO_RC=%ERRORLEVEL%"
if not "%SHAMIGO_RC%"=="0" pause
exit /b %SHAMIGO_RC%
::SHAMIGO_PS_BEGIN
# ShamiGo v0.10.607 OneFolder FullUninstall (2026-11-17) ZIP bootstrap.
# SCRIPT_MODE and EDITION are fixed in the launcher's embedded text.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$mode = 'install'
$edition = 'public'
$version = '0.10.607'
$stage = $null
$exitCode = 1
function Test-Candidate([string]$archivePath,[string]$entryName,[string]$expectedHash) {
    if (-not [IO.File]::Exists($archivePath)) { return $false }
    $z = $null; $stream = $null; $h = $null; $reader = $null
    try {
        $z = [IO.Compression.ZipFile]::OpenRead($archivePath)
        $entry = $z.GetEntry($entryName)
        $versionEntry = $z.GetEntry('VERSION.json')
        if ($null -eq $entry -or $null -eq $versionEntry -or
            $null -eq $z.GetEntry('SHA256SUMS.txt')) { return $false }
        $privateEntry = $z.GetEntry('Projects/Windows/NativeApp/shamigo_native_win.cpp')
        if ($edition -eq 'private' -and $null -eq $privateEntry) { return $false }
        if ($edition -eq 'public' -and $null -ne $privateEntry) { return $false }
        $stream = $entry.Open()
        $h = [Security.Cryptography.SHA256]::Create()
        $actual = [BitConverter]::ToString($h.ComputeHash($stream)).Replace('-','').ToLowerInvariant()
        if ($actual -cne $expectedHash) { return $false }
        $reader = New-Object IO.StreamReader($versionEntry.Open(),[Text.Encoding]::UTF8)
        $metadata = ConvertFrom-Json -InputObject ($reader.ReadToEnd())
        return ($metadata.package.version -ceq $version -and
                $metadata.windows.version -ceq $version)
    } catch { return $false }
    finally {
        if ($null -ne $reader) { $reader.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
        if ($null -ne $h) { $h.Dispose() }
        if ($null -ne $z) { $z.Dispose() }
    }
}
function Find-OriginalArchive {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $entry = [IO.Path]::GetFileName($env:SHAMIGO_BOOT_CMD)
    $entryHash = (Get-FileHash -LiteralPath $env:SHAMIGO_BOOT_CMD -Algorithm SHA256).Hash.ToLowerInvariant()
    foreach ($given in @($env:SHAMIGO_ZIP_SOURCE,$env:SHAMIGO_BOOT_ZIP)) {
        if ([string]::IsNullOrWhiteSpace($given)) { continue }
        if (Test-Candidate $given $entry $entryHash) { return $given }
        throw ('The selected archive is not this ShamiGo ' + $edition + ' package: ' + $given)
    }
    $scriptFolder = [IO.Path]::GetDirectoryName($env:SHAMIGO_BOOT_CMD)
    $folders = New-Object 'System.Collections.Generic.List[string]'
    foreach ($path in @($scriptFolder,[IO.Directory]::GetCurrentDirectory(),
        (Join-Path $env:USERPROFILE 'Downloads'),
        (Join-Path $env:USERPROFILE 'Desktop'),
        (Join-Path $env:USERPROFILE 'Documents'),
        (Join-Path $env:USERPROFILE 'OneDrive\Downloads'),
        (Join-Path $env:USERPROFILE 'OneDrive\Desktop'))) {
        if (-not [string]::IsNullOrWhiteSpace($path)) { $folders.Add($path) }
    }
    $direct = New-Object 'System.Collections.Generic.List[string]'
    try {
        $shell = New-Object -ComObject Shell.Application
        foreach ($known in @('shell:Downloads','shell:Desktop')) {
            $folder = $shell.NameSpace($known)
            if ($folder -and $folder.Self -and $folder.Self.Path) {
                $folders.Add([string]$folder.Self.Path)
            }
        }
        foreach ($window in @($shell.Windows())) {
            try {
                $uriText = [string]$window.LocationURL
                if ($uriText -notmatch '(?i)[.]zip(?:/|$)') { continue }
                $uri = New-Object Uri($uriText)
                if (-not $uri.IsFile) { continue }
                $path = [Uri]::UnescapeDataString($uri.LocalPath)
                $m = [regex]::Match($path,'(?i)^.*?[.]zip')
                if ($m.Success -and [IO.File]::Exists($m.Value)) { $direct.Add($m.Value) }
            } catch { }
        }
    } catch { }
    $seen = @{}
    $candidates = New-Object 'System.Collections.Generic.List[IO.FileInfo]'
    foreach ($file in $direct) {
        $key = $file.ToLowerInvariant()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $candidates.Add([IO.FileInfo]::new($file))
        }
    }
    foreach ($folder in $folders) {
        if (-not [IO.Directory]::Exists($folder)) { continue }
        foreach ($file in [IO.Directory]::EnumerateFiles($folder,'*.zip',[IO.SearchOption]::TopDirectoryOnly)) {
            $key = $file.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $candidates.Add([IO.FileInfo]::new($file))
        }
    }
    $viewerName = [IO.Path]::GetFileName($scriptFolder)
    $ordered = @($candidates | Where-Object { $_.Length -gt 1000000 -and $_.Length -lt 157286400 } |
        Sort-Object -Property @{Expression={
            if ($viewerName.StartsWith($_.Name,[StringComparison]::OrdinalIgnoreCase)) { 3 }
            elseif ($_.Name -like '*0.10.607*') { 2 }
            else { 1 }
        };Descending=$true},@{Expression={$_.LastWriteTimeUtc};Descending=$true})
    foreach ($candidate in $ordered) {
        if (Test-Candidate $candidate.FullName $entry $entryHash) { return $candidate.FullName }
    }
    # Unusual ZIP locations are not an installation error. Ask for the exact
    # archive using a native file picker, then verify its CMD hash and metadata.
    Add-Type -AssemblyName System.Windows.Forms
    $picker = New-Object System.Windows.Forms.OpenFileDialog
    try {
        $picker.Title = 'Choose the full ShamiGo v0.10.607 ZIP archive'
        $picker.Filter = 'ZIP archives (*.zip)|*.zip'
        $picker.CheckFileExists = $true
        if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and
            (Test-Candidate $picker.FileName $entry $entryHash)) {
            return $picker.FileName
        }
    } finally { $picker.Dispose() }
    throw 'Cannot locate the matching complete ZIP. No installed files were changed.'
}
function Check-ZipEntries([IO.Compression.ZipArchive]$zip) {
    $seen = @{}; [int64]$total = 0
    if ($zip.Entries.Count -lt 35 -or $zip.Entries.Count -gt 800) {
        throw 'Unexpected archive member count.'
    }
    foreach ($entry in $zip.Entries) {
        $name = [string]$entry.FullName
        if ($name -cnotmatch '^[A-Za-z0-9_./ -]+$' -or $name.Length -gt 240 -or
            $name.Contains('\\') -or $name.Contains(':') -or $name.StartsWith('/') -or
            $name.Contains('//') -or $name.EndsWith('/') -or
            $name -match '(^|/)\.{1,2}(/|$)' -or $name -match '[<>|?*]') {
            throw ('Unsafe ZIP member: ' + $name)
        }
        foreach ($segment in $name.Split('/')) {
            if ($segment.EndsWith(' ') -or $segment.EndsWith('.') -or
                $segment -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') {
                throw ('Unsafe Windows ZIP segment: ' + $name)
            }
        }
        $key = $name.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { throw ('Duplicate ZIP member: ' + $name) }
        $seen[$key] = $true
        if ((($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) {
            throw ('ZIP symlink refused: ' + $name)
        }
        if ($entry.Length -gt 100000000) { throw ('ZIP member too large: ' + $name) }
        $total += [int64]$entry.Length
        if ($total -gt 250000000) { throw 'Unexpected ZIP uncompressed size.' }
    }
    foreach ($required in @('SHA256SUMS.txt','VERSION.json','Install_Windows.cmd',
        'Run_Windows.cmd','Uninstall_Windows.cmd','LicensedTables/README.txt',
        'Packages/Windows/ShamiGo/ShamiGo.exe',
        'Packages/Windows/ShamiGo/Tools/Configure_ShamiGo_AutoStart.ps1',
        'Packages/Windows/ShamiGo/Tools/Import_LicensedTables.ps1',
        'Packages/Windows/ShamiGo/Tools/Prepare_ECDICT.ps1',
        'Data/EnglishECDICT.tar.xz','Data/EnglishChineseReverse.tar.xz')) {
        if (-not $seen.ContainsKey($required.ToLowerInvariant())) {
            throw ('ZIP missing required file: ' + $required)
        }
    }
    return $seen
}
function Verify-Extracted([string]$root,$seen) {
    $manifest = Join-Path $root 'SHA256SUMS.txt'
    $checked = @{}
    foreach ($line in [IO.File]::ReadAllLines($manifest)) {
        if ($line -cnotmatch '^([0-9a-f]{64})  ([A-Za-z0-9_./ -]+)$') {
            throw 'Malformed SHA256SUMS entry.'
        }
        $sha = $Matches[1]; $name = $Matches[2]
        $key = $name.ToLowerInvariant()
        if (-not $seen.ContainsKey($key) -or $checked.ContainsKey($key) -or
            $name -ceq 'SHA256SUMS.txt') {
            throw ('Unexpected SHA256SUMS path: ' + $name)
        }
        $checked[$key] = $true
        $path = Join-Path $root ($name.Replace('/','\'))
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $sha) {
            throw ('ShamiGo release file changed: ' + $name)
        }
    }
    foreach ($name in $seen.Keys) {
        if ($name -eq 'sha256sums.txt' -or $checked.ContainsKey($name)) { continue }
        # Users may add licensed tables themselves to a ZIP. Only these exact
        # names are unpinned; all distributable binaries/scripts are pinned.
        if ($name -notin @('licensedtables/liu-uni.tab','licensedtables/liu-uni2.tab',
            'licensedtables/liu-uni3.tab','licensedtables/liu-uni4.tab',
            'licensedtables/liuphon.tab','licensedtables/liuext.tab',
            'licensedtables/associatedphrases.cin','licensedtables/liu.box')) {
            throw ('Unexpected extra ZIP file: ' + $name)
        }
    }
    $v = Get-Content -LiteralPath (Join-Path $root 'VERSION.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($v.package.version -cne $version -or $v.windows.version -cne $version) {
        throw 'Archive version mismatch.'
    }
}
try {
    if (-not [IO.File]::Exists($env:SHAMIGO_BOOT_CMD)) {
        throw 'The active ZIP CMD entrypoint is missing.'
    }
    $source = Find-OriginalArchive
    Write-Host ('[ShamiGo v' + $version + '] Verifying ' + $edition + ' ZIP: ' + $source)
    $zip = [IO.Compression.ZipFile]::OpenRead($source)
    try { $entries = Check-ZipEntries $zip }
    finally { $zip.Dispose() }
    $stage = Join-Path ([IO.Path]::GetTempPath()) ('ShamiGo-v607-' + [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($stage) | Out-Null
    [IO.Compression.ZipFile]::ExtractToDirectory($source,$stage)
    Verify-Extracted $stage $entries
    $env:SHAMIGO_FROM_ZIP = '1'
    if ($mode -eq 'install') {
        & (Join-Path $stage 'Install_Windows.cmd')
        $exitCode = [int]$LASTEXITCODE
    } elseif ($mode -eq 'uninstall') {
        & (Join-Path $stage 'Uninstall_Windows.cmd')
        $exitCode = [int]$LASTEXITCODE
    } elseif ($mode -eq 'vm') {
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $stage 'Packages\Linux\ShamiGo_VM_Manager.ps1') -Action menu
        $exitCode = [int]$LASTEXITCODE
    } elseif ($mode -eq 'run') {
        $win = Join-Path $stage 'Packages\Windows\ShamiGo'
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $win 'Tools\Import_LicensedTables.ps1') -ReleaseRoot $stage
        if ($LASTEXITCODE -ne 0) { throw 'Optional table initialization failed.' }
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $win 'Tools\Prepare_ECDICT.ps1') `
            -Archive (Join-Path $stage 'Data\EnglishECDICT.tar.xz') `
            -UsageArchive (Join-Path $stage 'Data\EnglishUsage.tar.xz') `
            -ReverseArchive (Join-Path $stage 'Data\EnglishChineseReverse.tar.xz')
        if ($LASTEXITCODE -ne 0) { throw 'ECDICT initialization failed.' }
        $cacheParent = Join-Path $env:LOCALAPPDATA 'ShamiGo\ZipPortable'
        $cache = Join-Path $cacheParent 'v0.10.607-OneFolder'
        [IO.Directory]::CreateDirectory($cacheParent) | Out-Null
        if (-not [IO.Directory]::Exists($cache)) {
            $partial = Join-Path $cacheParent ('.stage-' + [guid]::NewGuid().ToString('N'))
            try {
                Copy-Item -LiteralPath $win -Destination $partial -Recurse -ErrorAction Stop
                Move-Item -LiteralPath $partial -Destination $cache -ErrorAction Stop
            } finally {
                if ([IO.Directory]::Exists($partial)) {
                    Remove-Item -LiteralPath $partial -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            foreach ($file in [IO.Directory]::GetFiles($win,'*',[IO.SearchOption]::AllDirectories)) {
                $relative = $file.Substring($win.Length+1)
                $destination = Join-Path $cache $relative
                $folder = [IO.Path]::GetDirectoryName($destination)
                [IO.Directory]::CreateDirectory($folder) | Out-Null
                if ([IO.File]::Exists($destination) -and
                    (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ieq
                    (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash) { continue }
                Copy-Item -LiteralPath $file -Destination $destination -Force -ErrorAction Stop
            }
        }
        $exe = Join-Path $cache 'ShamiGo.exe'
        if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ine
            (Get-FileHash -LiteralPath (Join-Path $win 'ShamiGo.exe') -Algorithm SHA256).Hash) {
            throw 'Portable runtime executable checksum mismatch.'
        }
        Start-Process -FilePath $exe -WorkingDirectory $cache -ErrorAction Stop | Out-Null
        Write-Host ('[ShamiGo] Portable startup requested from: ' + $cache)
        $exitCode = 0
    } else { throw 'Unsupported ZIP launcher action.' }
} catch {
    Write-Host ('[ShamiGo] ERROR: ' + $_.Exception.Message)
    $exitCode = 1
} finally {
    $env:SHAMIGO_FROM_ZIP = $null
    if ($null -ne $stage -and [IO.Directory]::Exists($stage)) {
        try { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction Stop }
        catch { Write-Host ('[ShamiGo] Could not remove temporary extraction: ' + $stage) }
    }
}
exit $exitCode

::SHAMIGO_PS_END
