@echo off
setlocal EnableExtensions DisableDelayedExpansion
if exist "%~dp0Packages\Windows\ShamiGo\Tools\Configure_ShamiGo_AutoStart.ps1" goto extracted
set "SHAMIGO_ZIP_CMD=%~f0"
set "SHAMIGO_ZIP_EXPLICIT=%~1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SHAMIGO_ZIP_CMD,[Text.Encoding]::ASCII);$a=$s.LastIndexOf('::SHAMIGO_PS_BEGIN');$b=$s.LastIndexOf('::SHAMIGO_PS_END');if($a -lt 0 -or $b -le $a){exit 2};& ([ScriptBlock]::Create($s.Substring($a+'::SHAMIGO_PS_BEGIN'.Length,$b-$a-'::SHAMIGO_PS_BEGIN'.Length)))"
set "SHAMIGO_RESULT=%ERRORLEVEL%"
if not "%SHAMIGO_RESULT%"=="0" pause
exit /b %SHAMIGO_RESULT%
:extracted
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Packages\Windows\ShamiGo\Tools\Configure_ShamiGo_AutoStart.ps1" -Mode Uninstall
set "SHAMIGO_RESULT=%ERRORLEVEL%"
if not "%SHAMIGO_RESULT%"=="0" pause
exit /b %SHAMIGO_RESULT%
::SHAMIGO_PS_BEGIN
# ShamiGo v0.10.607: public ZIP/Explorer batch bootstrap.
# No executable, dictionary, Chinese index or licensed table is embedded here.
# Windows Explorer may stage only one .cmd from an opened ZIP. This script
# locates the ORIGINAL complete ZIP, verifies it, extracts to a unique TEMP
# directory, executes the selected action and removes the TEMP directory.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$mode = 'uninstall'
$version = '0.10.607'
$appDigest = 'e35a4e8ea3bfb7968d496a4bdb2ca14639b1552a127bbbc24ebdaa575bffcfc5'
$setupDigest = '9859cf79500591cdb7a45d5605736b4a2067a4e8725fd5f702789b235112d7e4'
$launcherDigest = 'e85fcd5c8e1f771a524a502faddd21ac96f1c18aa6db8cac57949c64b75c4d32'
$stage = $null
$exitCode = 1
# Only trust the actual ZIP contents, never its visible filename.
# Explorer extracts a CMD into TEMP without giving it the archive's full path.
# We locate candidate ZIP files and accept one only when the inner entry for
# the *running* CMD has the identical SHA-256 and VERSION.json agrees.
function Test-ShamiGoZipCandidate([string]$path, [string]$cmdName, [string]$cmdDigest) {
    if (-not [IO.File]::Exists($path)) { return $false }
    $zip = $null
    $sha = $null
    $stream = $null
    $reader = $null
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($path)
        $scriptEntry = $zip.GetEntry($cmdName)
        $versionEntry = $zip.GetEntry('VERSION.json')
        $manifestEntry = $zip.GetEntry('SHA256SUMS.txt')
        if ($null -eq $scriptEntry -or $null -eq $versionEntry -or
            $null -eq $manifestEntry) { return $false }
        if ($scriptEntry.Length -gt 50000 -or $scriptEntry.Length -lt 1000 -or
            $versionEntry.Length -gt 8192) { return $false }
        $sha = [Security.Cryptography.SHA256]::Create()
        $stream = $scriptEntry.Open()
        $digest = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant()
        $stream.Dispose(); $stream = $null
        if ($digest -cne $cmdDigest) { return $false }
        $reader = [IO.StreamReader]::new($versionEntry.Open(), [Text.Encoding]::UTF8)
        $meta = ConvertFrom-Json -InputObject ($reader.ReadToEnd())
        return ($meta.package.version -ceq $version -and $meta.windows.version -ceq $version)
    } catch { return $false }
    finally {
        if ($null -ne $reader) { $reader.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
        if ($null -ne $sha) { $sha.Dispose() }
        if ($null -ne $zip) { $zip.Dispose() }
    }
}
function Find-ShamiGoOriginalZip {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $cmdName = [IO.Path]::GetFileName($env:SHAMIGO_ZIP_CMD)
    $cmdDigest = (Get-FileHash -LiteralPath $env:SHAMIGO_ZIP_CMD -Algorithm SHA256).Hash.ToLowerInvariant()
    foreach ($requested in @($env:SHAMIGO_ZIP_SOURCE, $env:SHAMIGO_ZIP_EXPLICIT)) {
        if ([string]::IsNullOrWhiteSpace($requested) -or
            -not $requested.EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase)) { continue }
        $full = [IO.Path]::GetFullPath($requested)
        if (Test-ShamiGoZipCandidate $full $cmdName $cmdDigest) { return $full }
        throw ('The specified ZIP is not this verified ShamiGo release: ' + $full)
    }
    $folders = New-Object 'System.Collections.Generic.List[string]'
    $scriptFolder = [IO.Path]::GetDirectoryName($env:SHAMIGO_ZIP_CMD)
    $folders.Add($scriptFolder)
    $folders.Add([IO.Directory]::GetCurrentDirectory())
    $folders.Add((Join-Path $env:USERPROFILE 'Downloads'))
    $folders.Add((Join-Path $env:USERPROFILE 'Desktop'))
    $folders.Add((Join-Path $env:USERPROFILE 'Documents'))
    $folders.Add((Join-Path $env:USERPROFILE 'OneDrive\Downloads'))
    $folders.Add((Join-Path $env:USERPROFILE 'OneDrive\Desktop'))
    $folders.Add((Join-Path $env:USERPROFILE 'OneDrive\Documents'))
    $extraFiles = New-Object 'System.Collections.Generic.List[string]'
    try {
        $shell = New-Object -ComObject Shell.Application
        foreach ($known in @('shell:Downloads','shell:Desktop')) {
            $knownFolder = $shell.NameSpace($known)
            if ($knownFolder -and $knownFolder.Self -and $knownFolder.Self.Path) {
                $folders.Add([string]$knownFolder.Self.Path)
            }
        }
        # Some Explorer windows expose the source archive path via LocationURL.
        # This allows archives outside Downloads/Desktop when Explorer provides it.
        foreach ($window in @($shell.Windows())) {
            try {
                $url = [string]$window.LocationURL
                if ($url -notmatch '(?i)[.]zip(?:/|$)') { continue }
                $uri = [Uri]::new($url)
                if (-not $uri.IsFile) { continue }
                $local = [Uri]::UnescapeDataString($uri.LocalPath)
                $match = [regex]::Match($local,'(?i)^.*?[.]zip')
                if ($match.Success -and [IO.File]::Exists($match.Value)) {
                    $extraFiles.Add($match.Value)
                }
            } catch { }
        }
    } catch { }
    $viewerFolder = [IO.Path]::GetFileName($scriptFolder)
    $items = New-Object 'System.Collections.Generic.List[object]'
    $seen = @{}
    foreach ($file in $extraFiles) {
        if (-not $seen.ContainsKey($file.ToLowerInvariant())) {
            $seen[$file.ToLowerInvariant()] = $true
            $items.Add(([IO.FileInfo]::new($file)))
        }
    }
    foreach ($folder in $folders) {
        if ([string]::IsNullOrWhiteSpace($folder) -or -not [IO.Directory]::Exists($folder)) { continue }
        # Only enumerate top-level ZIP files; never recursively scan user data.
        foreach ($path in [IO.Directory]::EnumerateFiles($folder,'*.zip',[IO.SearchOption]::TopDirectoryOnly)) {
            $key = $path.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $items.Add(([IO.FileInfo]::new($path)))
        }
    }
    # Windows Explorer's TEMP folder often ends with "<archive name>.zip.<number>".
    # Prefer this cue, but NEVER REQUIRE it: arbitrary downloaded names work.
    $ordered = @($items | Where-Object { $_.Length -gt 1000000 -and $_.Length -lt 150000000 } |
        Sort-Object -Property @{Expression={
            $n=$_.Name
            if ($viewerFolder.EndsWith($n,[StringComparison]::OrdinalIgnoreCase) -or
                $viewerFolder -match ([regex]::Escape($n) + '[.]\d+$')) { 2 }
            elseif ($_.Name -like ('*' + $version + '*')) { 1 }
            else { 0 }
        };Descending=$true}, @{Expression={$_.LastWriteTimeUtc};Descending=$true})
    foreach ($candidate in $ordered) {
        if (Test-ShamiGoZipCandidate $candidate.FullName $cmdName $cmdDigest) {
            return $candidate.FullName
        }
    }
    throw ('Cannot locate the matching ShamiGo ZIP. The launcher accepts ANY ZIP filename. ' +
        'Keep the downloaded archive in Downloads or Desktop, or fully extract it. ' +
        'No installed files were changed.')
}
function Test-ZipEntries([IO.Compression.ZipArchive]$archive) {
    $seen = @{}
    [int64]$total = 0
    if ($archive.Entries.Count -lt 20 -or $archive.Entries.Count -gt 160) {
        throw 'Unexpected ZIP file count.'
    }
    foreach ($entry in $archive.Entries) {
        $name = [string]$entry.FullName
        if ([string]::IsNullOrEmpty($name) -or $name.EndsWith('/') -or
            $name.Contains('\\') -or $name.Contains(':') -or $name.StartsWith('/') -or
            $name.Contains('//') -or $name -match '(^|/)\.{1,2}(/|$)' -or
            $name -match '[<>|?*]' -or $name.Length -gt 240) {
            throw ('Unsafe ZIP member: ' + $name)
        }
        if ($name -notmatch '^[A-Za-z0-9_./ -]+$') {
            throw ('Unexpected release filename characters: ' + $name)
        }
        foreach ($piece in $name.Split('/')) {
            if ($piece.EndsWith('.') -or $piece.EndsWith(' ') -or
                $piece -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') {
                throw ('Unsafe Windows ZIP path: ' + $name)
            }
        }
        $lower = $name.ToLowerInvariant()
        if ($seen.ContainsKey($lower)) { throw ('Duplicate ZIP file: ' + $name) }
        $seen[$lower] = $true
        if ((($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) {
            throw ('Refusing ZIP symlink: ' + $name)
        }
        $total += [int64]$entry.Length
        if ($total -gt 450000000 -or $entry.Length -gt 120000000) {
            throw 'Unexpected ZIP expansion size.'
        }
    }
    foreach ($required in @('SHA256SUMS.txt','VERSION.json',
        'Packages/Windows/ShamiGo/ShamiGo.exe',
        'Packages/Windows/ShamiGo/ShamiGo_AdminSetup.exe',
        'Packages/Windows/ShamiGo/Tools/Configure_ShamiGo_AutoStart.ps1',
        'Packages/Windows/ShamiGo/Tools/Prepare_ECDICT.ps1',
        'Data/EnglishECDICT.tar.xz',
        'Data/EnglishChineseReverse.tar.xz',
        'Packages/Windows/ShamiGo/LicensedTables/README.txt')) {
        if (-not $seen.ContainsKey($required.ToLowerInvariant())) {
            throw ('ZIP missing required file: ' + $required)
        }
    }
    return $seen
}
function Assert-ReleaseIntegrity([string]$root, $entries) {
    $versionFile = Join-Path $root 'VERSION.json'
    $v = Get-Content -LiteralPath $versionFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($v.package.version -cne $version -or $v.windows.version -cne $version) {
        throw 'Unexpected ShamiGo package version.'
    }
    $manifestPath = Join-Path $root 'SHA256SUMS.txt'
    $verified = @{}
    foreach ($line in [IO.File]::ReadAllLines($manifestPath)) {
        if ($line -cnotmatch '^([0-9a-f]{64})  ([A-Za-z0-9_./ -]+)$') {
            throw 'Malformed release checksum manifest.'
        }
        $digest = $Matches[1]; $name = $Matches[2]
        $key = $name.ToLowerInvariant()
        if (-not $entries.ContainsKey($key) -or $verified.ContainsKey($key) -or
            $name -ceq 'SHA256SUMS.txt') {
            throw ('Unexpected manifest path: ' + $name)
        }
        $verified[$key] = $true
        $path = Join-Path $root ($name.Replace('/', '\\'))
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $digest) {
            throw ('Release file failed SHA-256: ' + $name)
        }
    }
    if ($verified.Count -ne ($entries.Count - 1)) {
        throw 'Incomplete release manifest.'
    }
    $release = Join-Path $root 'Packages\Windows\ShamiGo'
    foreach ($item in @(@('ShamiGo.exe',$appDigest),
        @('ShamiGo_AdminSetup.exe',$setupDigest),
        @('ShamiGo_AdminLauncher.exe',$launcherDigest))) {
        $exe = Join-Path $release $item[0]
        if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ine $item[1]) {
            throw ('Unexpected Windows executable: ' + $item[0])
        }
    }
}
function Install-GlossaryAssets([string]$root) {
    $tools = Join-Path $root 'Packages\Windows\ShamiGo\Tools\Prepare_ECDICT.ps1'
    & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $tools `
        -Archive (Join-Path $root 'Data\EnglishECDICT.tar.xz') `
        -UsageArchive (Join-Path $root 'Data\EnglishUsage.tar.xz') `
        -ReverseArchive (Join-Path $root 'Data\EnglishChineseReverse.tar.xz')
    if ($LASTEXITCODE -ne 0) { throw 'Offline ECDICT initialization failed.' }
}
try {
    if ([string]::IsNullOrWhiteSpace($env:SHAMIGO_ZIP_CMD) -or
        -not [IO.File]::Exists($env:SHAMIGO_ZIP_CMD)) {
        throw 'The CMD entrypoint was not found.'
    }
    $source = Find-ShamiGoOriginalZip
    Write-Host ('[ShamiGo v' + $version + '] Verifying ZIP: ' + $source)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($source)
    try { $entries = Test-ZipEntries $zip }
    finally { $zip.Dispose() }
    $stage = Join-Path ([IO.Path]::GetTempPath()) ('ShamiGo-v601-' + [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($stage) | Out-Null
    [IO.Compression.ZipFile]::ExtractToDirectory($source,$stage)
    Assert-ReleaseIntegrity $stage $entries
    $release = Join-Path $stage 'Packages\Windows\ShamiGo'
    $app = Join-Path $release 'ShamiGo.exe'
    $config = Join-Path $release 'Tools\Configure_ShamiGo_AutoStart.ps1'
    if ($mode -in @('install','run')) {
        $personal = Join-Path $stage 'Tools\Prepare_Windows_Data.ps1'
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $personal -ReleaseRoot $stage
        if ($LASTEXITCODE -ne 0) { throw 'Original Windows personal data preparation failed.' }
        Install-GlossaryAssets $stage
    }
    if ($mode -in @('install','uninstall')) {
        $action = if ($mode -eq 'uninstall') { 'Uninstall' }
                  elseif ($env:SHAMIGO_LAUNCH_ACTION -eq 'Disable') { 'Disable' }
                  else { 'Install' }
        Write-Host ('[ShamiGo] ' + $action + ' from temporary extracted package.')
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $config -Mode $action
        $exitCode = [int]$LASTEXITCODE
    } elseif ($mode -eq 'run') {
        # A portable app must outlive temporary extraction, so publish the
        # smallest necessary verified runtime as a user-local versioned cache.
        $cacheParent = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ShamiGo\ZipPortable'
        $cache = Join-Path $cacheParent ('v' + $version)
        [IO.Directory]::CreateDirectory($cacheParent) | Out-Null
        if (-not [IO.Directory]::Exists($cache)) {
            $candidate = Join-Path $cacheParent ('.stage-' + [guid]::NewGuid().ToString('N'))
            try {
                Copy-Item -LiteralPath $release -Destination $candidate -Recurse -ErrorAction Stop
                Move-Item -LiteralPath $candidate -Destination $cache -ErrorAction Stop
            } finally {
                if ([IO.Directory]::Exists($candidate)) {
                    Remove-Item -LiteralPath $candidate -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            # Update only changed application resources, not external user
            # preferences. Never delete a running version on failure.
            foreach ($file in [IO.Directory]::GetFiles($release,'*',[IO.SearchOption]::AllDirectories)) {
                $relative = $file.Substring($release.Length).TrimStart('\\')
                $to = Join-Path $cache $relative
                if ([IO.File]::Exists($to) -and
                    (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ieq
                    (Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash) { continue }
                $targetParent = [IO.Path]::GetDirectoryName($to)
                [IO.Directory]::CreateDirectory($targetParent) | Out-Null
                Copy-Item -LiteralPath $file -Destination $to -Force -ErrorAction Stop
            }
        }
        $exe = Join-Path $cache 'ShamiGo.exe'
        if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ine $appDigest) {
            throw 'Portable executable SHA-256 mismatch.'
        }
        $null = Start-Process -FilePath $exe -WorkingDirectory $cache -PassThru -ErrorAction Stop
        Write-Host ('[ShamiGo] Portable program started: ' + $cache)
        $exitCode = 0
    } elseif ($mode -eq 'vm') {
        $manager = Join-Path $stage 'Packages\Linux\ShamiGo_VM_Manager.ps1'
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $manager -Action menu
        $exitCode = [int]$LASTEXITCODE
    } else { throw 'Unsupported ZIP launcher mode.' }
} catch {
    Write-Host ('[ShamiGo] ERROR: ' + $_.Exception.Message)
    $exitCode = 1
} finally {
    if ($null -ne $stage -and [IO.Directory]::Exists($stage)) {
        try { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction Stop }
        catch { Write-Host ('[ShamiGo] Temporary cleanup warning: ' + $stage) }
    }
}
exit $exitCode
::SHAMIGO_PS_END
