# ShamiGo ECDICT offline asset bootstrap.  Windows 11 tar.exe handles XZ.
# No downloads, Python, registry writes or elevation.  Reuses a verified
# user-local, memory-mappable TSV on every subsequent launch.
param([Parameter(Mandatory=$true)][string]$Archive,
      [string]$UsageArchive = '',
      [Parameter(Mandatory=$true)][string]$ReverseArchive)
$ErrorActionPreference = 'Stop'
$expected = '669341bbf6d27355eca1dcadb54559ef46a4bb22f5c5d97ac411062e64978497'
$archiveExpected = 'ee415b9d2d2c60f668afc43519d59134bfaa941cc788e583c6815d0cd2f87af2'
$stage = $null
try {
    if (-not [IO.File]::Exists($Archive)) { throw ('Bundled ECDICT archive missing: ' + $Archive) }
    if ((Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash -ine $archiveExpected) {
        throw 'ECDICT compressed archive integrity check failed.'
    }
    $folder = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ShamiGo\Dictionaries'
    $dest = Join-Path $folder 'EnglishECDICT.tsv'
    $valid = [IO.File]::Exists($dest) -and
        (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash -ieq $expected
    if (-not $valid) {
        [IO.Directory]::CreateDirectory($folder) | Out-Null
        $stage = Join-Path $folder ('.ecdict-' + [guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($stage) | Out-Null
        $contents = @(& tar.exe -tf $Archive 2>&1)
        if ($LASTEXITCODE -ne 0 -or $contents.Count -ne 1 -or
            $contents[0].Trim() -cne 'EnglishECDICT.tsv') {
            throw 'ECDICT archive member list is unexpected.'
        }
        & tar.exe -xf $Archive -C $stage
        if ($LASTEXITCODE -ne 0) { throw 'Windows tar could not unpack ECDICT.' }
        $candidate = Join-Path $stage 'EnglishECDICT.tsv'
        $info = Get-Item -LiteralPath $candidate -ErrorAction Stop
        if ($info.Length -lt 40000000 -or $info.Length -gt 100000000 -or
            (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash -ine $expected) {
            throw 'ECDICT TSV did not pass full SHA-256 integrity verification.'
        }
        $partial = Join-Path $folder ('.EnglishECDICT-' + [guid]::NewGuid().ToString('N'))
        try {
            Move-Item -LiteralPath $candidate -Destination $partial -ErrorAction Stop
            Move-Item -LiteralPath $partial -Destination $dest -Force -ErrorAction Stop
        } finally {
            if ([IO.File]::Exists($partial)) { Remove-Item -LiteralPath $partial -Force }
        }
        Write-Host '[ECDICT] Offline English/Chinese dictionary installed (770,611 entries).'
    }
    # Optional licensed usage corpus. The public ZIP does not distribute it.
    if ($UsageArchive -and [IO.File]::Exists($UsageArchive)) {
    # Supplemental, SHA-pinned real examples and WordNet lexical relations.
    # Keep these separate: ECDICT remains the ONLY definition dictionary.
    $usageTarget = Join-Path $folder 'EnglishUsage.tsv'
    if (-not [IO.File]::Exists($UsageArchive) -or
        (Get-FileHash -LiteralPath $UsageArchive -Algorithm SHA256).Hash -ine '48d376a93df343480a54c3e19eef1d7a7771219de02574415d18a8b2e7507a87') {
        throw 'Missing or damaged offline Tatoeba/WordNet usage archive.'
    }
    $usageValid = [IO.File]::Exists($usageTarget) -and
        (Get-FileHash -LiteralPath $usageTarget -Algorithm SHA256).Hash -ieq '184291296c6f992844a0083ecf578406334211b9852227b86ec4d7fbbe12a7b2'
    if (-not $usageValid) {
        [IO.Directory]::CreateDirectory($folder) | Out-Null
        $usageStage = Join-Path $folder ('.usage-' + [guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($usageStage) | Out-Null
        try {
            $members = @(& tar.exe -tf $UsageArchive 2>&1)
            if ($LASTEXITCODE -ne 0 -or $members.Count -ne 1 -or
                $members[0].Trim() -cne 'EnglishUsage.tsv') {
                throw 'Usage archive contains unexpected members.'
            }
            & tar.exe -xf $UsageArchive -C $usageStage
            if ($LASTEXITCODE -ne 0) { throw 'Usage archive extraction failed.' }
            $candidate = Join-Path $usageStage 'EnglishUsage.tsv'
            if ((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash -ine '184291296c6f992844a0083ecf578406334211b9852227b86ec4d7fbbe12a7b2') {
                throw 'Attested example TSV integrity check failed.'
            }
            Move-Item -LiteralPath $candidate -Destination $usageTarget -Force
        } finally {
            Remove-Item -LiteralPath $usageStage -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Host '[USAGE] Verified offline Tatoeba examples and WordNet relations.'
    }
    }
    # Immutable Chinese-to-English suffix index, derived only from the same
    # Taiwan ECDICT translations. Always validate BEFORE reuse or replacement.
    $reverseExpected = 'f9a7a967baeda770aed8305e94f8e2c05ac892faeb797a7dd367cdaf6f168472'
    $reverseArchiveExpected = '9880b6b6d3ffb20aafdb8e361008b7daed2042b4b373bcb9cf1444cbf9324572'
    if (-not [IO.File]::Exists($ReverseArchive) -or
        (Get-FileHash -LiteralPath $ReverseArchive -Algorithm SHA256).Hash -ine $reverseArchiveExpected) {
        throw 'Chinese reverse index archive failed integrity verification.'
    }
    $reverseTarget = Join-Path $folder 'EnglishChineseReverse.tsv'
    $reverseValid = [IO.File]::Exists($reverseTarget) -and
        (Get-FileHash -LiteralPath $reverseTarget -Algorithm SHA256).Hash -ieq $reverseExpected
    if (-not $reverseValid) {
        [IO.Directory]::CreateDirectory($folder) | Out-Null
        $reverseStage = Join-Path $folder ('.reverse-' + [guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($reverseStage) | Out-Null
        try {
            $members = @(& tar.exe -tf $ReverseArchive 2>&1)
            if ($LASTEXITCODE -ne 0 -or $members.Count -ne 1 -or
                $members[0].Trim() -cne 'EnglishChineseReverse.tsv') {
                throw 'Chinese reverse archive members are unexpected.'
            }
            & tar.exe -xf $ReverseArchive -C $reverseStage
            if ($LASTEXITCODE -ne 0) { throw 'Chinese reverse index extraction failed.' }
            $candidate = Join-Path $reverseStage 'EnglishChineseReverse.tsv'
            if ((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash -ine $reverseExpected) {
                throw 'Chinese reverse index SHA-256 mismatch.'
            }
            Move-Item -LiteralPath $candidate -Destination $reverseTarget -Force
            Write-Host '[ECDICT] Offline Chinese-to-English reverse index installed.'
        } finally {
            Remove-Item -LiteralPath $reverseStage -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    # Remove only known retired ShamiGo dictionaries; never a user's others.
    foreach ($old in @('EnglishStarDict.tsv','EnglishWordNet.tsv','EnglishDictionary.tsv')) {
        $path = Join-Path $folder $old
        if ([IO.File]::Exists($path)) { Remove-Item -LiteralPath $path -Force }
    }
    exit 0
} catch {
    [Console]::Error.WriteLine('[ECDICT] ' + $_.Exception.Message)
    exit 21
} finally {
    if ($stage -and [IO.Directory]::Exists($stage)) {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    }
}
