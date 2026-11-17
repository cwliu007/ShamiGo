# ShamiGo v0.10.607 OneFolder: optional user-supplied dictionary importer.
# No administrator rights needed. Absence of liu-uni.tab is an allowed state.
param([string]$ReleaseRoot = '')
$ErrorActionPreference = 'Stop'
try {
    if ([string]::IsNullOrWhiteSpace($ReleaseRoot)) {
        $ReleaseRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..'))
    }
    $root = [IO.Path]::GetFullPath($ReleaseRoot)
    $tables = Join-Path $root 'LicensedTables'
    $runtime = Join-Path $root 'Packages\Windows\ShamiGo'
    $dest = Join-Path $runtime 'LicensedTables'
    $userTables = Join-Path $env:LOCALAPPDATA 'ShamiGo\LicensedTables'
    foreach ($dir in @($tables,$runtime)) {
        $item = Get-Item -LiteralPath $dir -ErrorAction Stop
        if (-not $item.PSIsContainer -or
            (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw ('Release folder is missing or linked: ' + $dir)
        }
    }
    foreach ($dir in @($dest,$userTables)) {
        if ([IO.Directory]::Exists($dir)) {
            $item = Get-Item -LiteralPath $dir -Force -ErrorAction Stop
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw ('Refusing linked dictionary destination: ' + $dir)
            }
        } else {
            [IO.Directory]::CreateDirectory($dir) | Out-Null
        }
    }
    $names = @('liu-uni.tab','liu-uni2.tab','liu-uni3.tab','liu-uni4.tab',
        'liuphon.tab','liuext.tab','AssociatedPhrases.cin')
    $sourcePairs = New-Object 'System.Collections.Generic.List[object]'
    foreach ($name in $names) {
        $source = Join-Path $tables $name
        if (-not [IO.File]::Exists($source)) { continue }
        $item = Get-Item -LiteralPath $source -Force -ErrorAction Stop
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $item.Length -lt 16 -or $item.Length -gt 33554432) {
            throw ('Table is invalid or not a regular file: ' + $source)
        }
        $sourcePairs.Add([pscustomobject]@{Source=$source; Name=$name})
    }
    function Update-File([string]$from,[string]$to) {
        if ([IO.File]::Exists($to)) {
            $old = Get-Item -LiteralPath $to -Force -ErrorAction Stop
            if (($old.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw ('Refusing linked target: ' + $to)
            }
            if ((Get-FileHash -LiteralPath $from -Algorithm SHA256).Hash -eq
                (Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash) { return $false }
        }
        $parent = [IO.Path]::GetDirectoryName($to)
        [IO.Directory]::CreateDirectory($parent) | Out-Null
        $stage = Join-Path $parent ('.shamigo-' + [guid]::NewGuid().ToString('N'))
        try {
            Copy-Item -LiteralPath $from -Destination $stage -ErrorAction Stop
            Move-Item -LiteralPath $stage -Destination $to -Force -ErrorAction Stop
        } finally {
            if ([IO.File]::Exists($stage)) { Remove-Item -LiteralPath $stage -Force }
        }
        return $true
    }
    $changed = 0
    foreach ($item in $sourcePairs) {
        foreach ($targetDir in @($dest,$userTables)) {
            if (Update-File $item.Source (Join-Path $targetDir $item.Name)) { $changed++ }
        }
    }
    $box = Join-Path $tables 'liu.box'
    if ([IO.File]::Exists($box)) {
        if (Update-File $box (Join-Path $runtime 'liu.box')) { $changed++ }
    }
    $reading = Join-Path $root 'Data\Phonetics\mcbopomofo_readings.tsv'
    if ([IO.File]::Exists($reading)) {
        if (Update-File $reading (Join-Path $runtime 'Phonetics\mcbopomofo_readings.tsv')) { $changed++ }
    }
    # When Explorer opens a CMD inside ZIP, it extracts to a temporary folder.
    # Never save this disappearing location as the source. A stable user-local
    # dictionary folder remains available for additions after installation.
    $sourceRoot = if ($env:SHAMIGO_FROM_ZIP -eq '1') { $userTables } else { $tables }
    $sourceRoot = [IO.Path]::GetFullPath($sourceRoot)
    if ($sourceRoot.Length -gt 960) { throw 'The dictionary source path is too long.' }
    [IO.File]::WriteAllText((Join-Path $runtime 'TableSourcePath.txt'),
        $sourceRoot,[Text.Encoding]::Unicode)
    $mainReady = [IO.File]::Exists((Join-Path $tables 'liu-uni.tab')) -or
        [IO.File]::Exists((Join-Path $userTables 'liu-uni.tab')) -or
        [IO.File]::Exists((Join-Path $dest 'liu-uni.tab'))
    if ($mainReady) {
        Write-Host ('[TABLES] Liu dictionary available. Updated {0} file copies.' -f $changed)
    } else {
        Write-Host '[TABLES] No liu-uni.tab yet. Installation remains allowed; Chinese input is unavailable.'
        Write-Host ('[TABLES] Add liu-uni.tab later to: ' + $sourceRoot)
        Write-Host '[TABLES] Exit and restart ShamiGo to activate it. Reinstallation is unnecessary.'
    }
    exit 0
} catch {
    [Console]::Error.WriteLine('[TABLES] ' + $_.Exception.Message)
    exit 2
}
