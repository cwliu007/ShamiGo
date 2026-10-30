# ShamiGo Linux v0.10.366-1 - Windows 11 / VirtualBox Debian 13 / LMDE 7 installer restore Fix1.
# Requires VirtualBox Guest Additions with Guest Control running inside Debian.
# The .cmd file contains ASCII only; all Traditional Chinese UI is displayed here.
param(
    [ValidateSet('menu','install','remove')]
    [string]$Action = 'menu'
)
$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [Console]::OutputEncoding
} catch { }

$script:VBoxExe = $null
$script:VM = $null
$script:Auth = @()
$script:Stage = $null
$script:TempDir = $null
$script:StagingMade = $false
$script:UserName = $null

function Get-VBoxManagePath {
    $paths = @()
    if ($env:ProgramFiles) { $paths += (Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe') }
    if (${env:ProgramFiles(x86)}) { $paths += (Join-Path ${env:ProgramFiles(x86)} 'Oracle\VirtualBox\VBoxManage.exe') }
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p -PathType Leaf) { return $p }
    }
    $fromPath = Get-Command 'VBoxManage.exe' -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    throw '找不到 VBoxManage.exe。請先確認 Windows 11 已安裝 VirtualBox。'
}

function Invoke-VBox {
    param([string[]]$VBoxArgs,[string]$Phase,[switch]$Quiet)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $global:LASTEXITCODE = -1
        $output = @(& $script:VBoxExe @VBoxArgs 2>&1)
        $rc = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
    $message = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if (-not $Quiet -and -not [string]::IsNullOrWhiteSpace($message)) {
        Write-Host $message
    }
    if ($rc -ne 0) {
        throw ("{0} 失敗 (VirtualBox exit {1}).`n{2}" -f $Phase, $rc, $message)
    }
    return $message
}

function Get-RunningVM {
    $listing = Invoke-VBox -VBoxArgs @('list','runningvms') -Phase '取得虛擬機清單' -Quiet
    $names = @()
    foreach ($line in ($listing -split "`r?`n")) {
        if ($line -match '^\s*"(?<vm>.+)"\s+\{[0-9a-fA-F-]{36}\}\s*$') {
            $names += $Matches['vm']
        }
    }
    if ($names.Count -eq 0) { throw '沒有執行中的 VM。請先啟動 LMDE 7 並登入桌面；VM 內須安裝 VirtualBox Guest Additions。' }
    if ($names.Count -eq 1) {
        Write-Host ("使用的虛擬機：{0}" -f $names[0])
        return [string]$names[0]
    }
    Write-Host '請選擇 Debian 13 或 LMDE 7 虛擬機：' -ForegroundColor Cyan
    for ($i = 0; $i -lt $names.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i+1), $names[$i])
    }
    $selection = Read-Host '輸入虛擬機序號'
    $index = 0
    if (-not [int]::TryParse($selection, [ref]$index) -or $index -lt 1 -or $index -gt $names.Count) {
        throw '虛擬機序號不正確。'
    }
    return [string]$names[$index - 1]
}

function New-PrivateCredentialFile {
    $base = $env:TEMP
    if ([string]::IsNullOrWhiteSpace($base)) { $base = [System.IO.Path]::GetTempPath() }
    $directory = Join-Path $base ('ShamiGoVM-' + [Guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($directory)
    $script:TempDir = $directory
    # Restrict the temporary directory to the current Windows user.
    $acl = Get-Acl -LiteralPath $directory
    $acl.SetAccessRuleProtection($true, $false)
    $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
    $inherit = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    $rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
        $sid,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        $inherit,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow)
    $acl.SetAccessRule($rule)
    Set-Acl -LiteralPath $directory -AclObject $acl

    $secret = Read-Host '輸入 Linux 使用者密碼（需有 sudo 權限，輸入時不顯示）' -AsSecureString
    if ($null -eq $secret) { throw '沒有輸入 Debian 密碼。' }
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        if ([string]::IsNullOrEmpty($plain) -or $plain.Contains("`n") -or $plain.Contains("`r")) {
            throw 'Debian 密碼不可空白或包含換行。'
        }
        $passwordPath = Join-Path $directory 'shamigo-credential.tmp'
        [System.IO.File]::WriteAllText($passwordPath, $plain, ([System.Text.UTF8Encoding]::new($false)))
        return $passwordPath
    } finally {
        if ($ptr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
        $plain = $null
        $secret.Dispose()
    }
}

function Invoke-GuestShell {
    param([string]$Command,[string]$Phase,[switch]$Quiet,[int]$TimeoutMs = 30000)
    $argsList = @('guestcontrol',$script:VM,'run') + $script:Auth + @(
        '--exe=/bin/sh','--wait-stdout','--wait-stderr',"--timeout=$TimeoutMs",'--','-c',$Command)
    return Invoke-VBox -VBoxArgs $argsList -Phase $Phase -Quiet:$Quiet
}

# CopyTo is preferred, but some VirtualBox Guest Additions versions return
# VERR_ACCESS_DENIED when querying an otherwise writable guest destination.
# In that situation, use guestcontrol run to write independently checked chunks.
# A full SHA256 comparison is mandatory in either transfer mode.
function Get-GuestFileHash {
    param([string]$Target)
    # Guest staging names are strictly validated, so no nested shell quoting
    # needs to pass through Windows PowerShell 5.1's native argv conversion.
    if ($Target -notmatch '^/tmp/shamigo-v366-[0-9a-f]{32}/[A-Za-z0-9._-]+$') {
        throw '拒絕不安全的 Debian 檔案路徑。'
    }
    $command = "test -f $Target && sha256sum $Target"
    $response = Invoke-GuestShell -Command $command -Phase '核對 Debian 檔案 SHA256' -Quiet -TimeoutMs 120000
    if ($response -notmatch '(?m)^\s*([0-9A-Fa-f]{64})\s') {
        throw ("無法取得 Debian 檔案雜湊值：{0}" -f $Target)
    }
    return $Matches[1].ToLowerInvariant()
}

function Copy-GuestFileByChunks {
    param([string]$Source,[string]$Target)
    # Each 19,200-byte block becomes 25,600 Base64 characters, below the
    # Windows CreateProcess command line limit (32,767 UTF-16 characters).
    # All content is still transferred by authenticated VBox Guest Control.
    $sizes = @(19200, 4800)
    $total = (Get-Item -LiteralPath $Source).Length
    foreach ($blockSize in $sizes) {
        $stream = $null
        try {
            $prepare = "umask 077; : > $Target && chmod 600 $Target && printf SHAMIGO_TRUNCATED"
            $ready = Invoke-GuestShell -Command $prepare -Phase '準備備援檔案傳輸' -Quiet
            if ($ready -notmatch 'SHAMIGO_TRUNCATED') { throw '無法重置暫存傳輸檔案。' }
            $stream = [System.IO.File]::OpenRead($Source)
            $buffer = New-Object byte[] $blockSize
            [long]$sent = 0
            $lastShown = -1
            while ($true) {
                $count = $stream.Read($buffer, 0, $buffer.Length)
                if ($count -le 0) { break }
                $chunk = [System.Convert]::ToBase64String($buffer, 0, $count)
                # Base64 comprises only safe shell word characters (+, /, =).
                $command = "printf %s $chunk | base64 -d >> $Target && printf SHAMIGO_CHUNK_OK"
                $marker = Invoke-GuestShell -Command $command -Phase '傳送備援資料區塊' -Quiet -TimeoutMs 120000
                if ($marker -notmatch 'SHAMIGO_CHUNK_OK') { throw 'Debian 未確認備援資料區塊。' }
                $sent += $count
                if ($total -gt 0) {
                    $percent = [int][Math]::Floor(100.0 * $sent / $total)
                    if ($percent -ge ($lastShown + 10) -or $percent -eq 100) {
                        Write-Host ("備援傳輸進度：{0}%" -f $percent) -ForegroundColor DarkCyan
                        $lastShown = $percent
                    }
                }
            }
            if ($sent -ne $total) { throw '傳輸位元組數不符。' }
            return
        } catch {
            $detail = $_.Exception.Message
            if ($blockSize -eq $sizes[$sizes.Length - 1]) {
                throw ("備援傳輸也失敗：{0}" -f $detail)
            }
            Write-Host '備援傳輸較大區塊未成功，改用較小區塊重新傳送。' -ForegroundColor Yellow
        } finally {
            if ($null -ne $stream) { $stream.Dispose() }
        }
    }
    throw '備援傳輸未完成。'
}

function Copy-GuestFile {
    param([string]$Source,[string]$Name)
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw ("找不到傳輸檔案：{0}" -f $Source) }
    if ($Name -notmatch '^[A-Za-z0-9._-]+$') { throw '拒絕不安全的檔案名稱。' }
    $target = "$script:Stage/$Name"
    $expected = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash.ToLowerInvariant()

    # Pre-create the file as the authenticated non-root Debian user.  VBoxManage
    # copyto sometimes cannot stat a nonexistent guest file inside a mode-0700
    # directory even though guestcontrol run can access that directory.
    $prepare = "umask 077; test -d $script:Stage && test -w $script:Stage && test ! -L $target && test ! -d $target && : > $target && chmod 600 $target && test -w $target && printf SHAMIGO_TARGET_READY"
    $prepared = Invoke-GuestShell -Command $prepare -Phase '檢查 Debian 傳輸目的地權限' -Quiet
    if ($prepared -notmatch 'SHAMIGO_TARGET_READY') { throw 'Debian 目的檔案不允許目前帳號寫入。' }

    # Try the officially documented --target-directory form first.  This
    # avoids treating a directory as a file or a newly-created file as a dir.
    # The source basename and destination basename must match exactly.
    $copyErrors = @()
    if ([System.IO.Path]::GetFileName($Source) -ceq $Name) {
        try {
            [void](Invoke-VBox -VBoxArgs (@('guestcontrol',$script:VM,'copyto') + $script:Auth + @(
                "--target-directory=$script:Stage",$Source)) -Phase ("傳送檔案 {0} (目錄模式)" -f $Name) -Quiet)
            $actual = Get-GuestFileHash -Target $target
            if ($actual -eq $expected) { return }
            $copyErrors += 'VirtualBox 目錄模式未通過 SHA256 驗證。'
        } catch {
            $copyErrors += $_.Exception.Message
        }
    }
    try {
        [void](Invoke-VBox -VBoxArgs (@('guestcontrol',$script:VM,'copyto') + $script:Auth + @(
            $Source,$target)) -Phase ("傳送檔案 {0} (檔案模式)" -f $Name) -Quiet)
        $actual = Get-GuestFileHash -Target $target
        if ($actual -eq $expected) { return }
        $copyErrors += 'VirtualBox 檔案模式未通過 SHA256 驗證。'
    } catch {
        $copyErrors += $_.Exception.Message
    }
    Write-Host ("VirtualBox copyto 無法完成 {0}，切換自動備援傳輸。" -f $Name) -ForegroundColor Yellow
    if (($copyErrors -join "`n") -match 'VERR_ACCESS_DENIED') {
        Write-Host '偵測到 Guest Control 檔案存取拒絕，改用 Guest Shell 分塊傳輸。' -ForegroundColor Yellow
    }
    Copy-GuestFileByChunks -Source $Source -Target $target
    $actual = Get-GuestFileHash -Target $target
    if ($actual -ne $expected) {
        throw ("檔案雜湊不符，停止安裝（{0}）。" -f $Name)
    }
}

function Remove-GuestStage {
    if (-not $script:StagingMade) { return $true }
    if ($script:Stage -notmatch '^/tmp/shamigo-v366-[0-9a-f]{32}$') { return $false }
    try {
        [void](Invoke-VBox -VBoxArgs (@('guestcontrol',$script:VM,'rmdir') + $script:Auth + @('--recursive',$script:Stage)) -Phase '移除 Debian 暫存目錄' -Quiet)
        return $true
    } catch {
        # Some VirtualBox Guest Additions versions fail the rmdir subcommand.
        # Only our randomly created, validated directory may be removed.
        try {
            [void](Invoke-GuestShell -Command ("rm -rf -- {0} && printf SHAMIGO_CLEAN_OK" -f $script:Stage) -Phase '備援清理 Debian 暫存目錄' -Quiet)
            return $true
        } catch { return $false }
    }
}

function Invoke-ShamiGoAction {
    param([ValidateSet('install','remove')][string]$Operation)
    $script:VM = $null
    $script:Auth = @()
    $script:Stage = $null
    $script:TempDir = $null
    $script:StagingMade = $false
    $script:UserName = $null
    $status = 1
    try {
        # Use the script folder, including when launched from the menu.
        $base = $PSScriptRoot
        $guestScript = Join-Path $base 'ShamiGo_VM_Guest.sh'
        $platformScript = Join-Path $base 'ShamiGo_Platform_Check.py'
        $preflightScript = Join-Path $base 'ShamiGo_Dpkg_Preflight.sh'
        $payload = Join-Path $base 'ShamiGo_v0.10.366_VM_Payload.tar.gz'
        if (-not (Test-Path -LiteralPath $guestScript -PathType Leaf)) {
            throw '找不到 ShamiGo_VM_Guest.sh。請先將 ZIP 完整解壓縮。'
        }
        if (-not (Test-Path -LiteralPath $platformScript -PathType Leaf)) { throw '找不到平台相容性檢查檔案。請完整解壓縮。' }
        if (-not (Test-Path -LiteralPath $preflightScript -PathType Leaf)) { throw '找不到 dpkg 安全預檢程式。請完整解壓縮新版 ZIP。' }
        if ($Operation -eq 'install' -and -not (Test-Path -LiteralPath $payload -PathType Leaf)) {
            throw '找不到 Debian 安裝資料包。請先將 ZIP 完整解壓縮。'
        }
        # Pin the shipped VM archive before prompting for Linux credentials.
        # A transfer hash alone only checks the network copy, not original files.
        $expectedPackageHash = $null
        if ($Operation -eq 'install') {
            $payloadManifest = Join-Path $base 'VM_PAYLOAD_SHA256.txt'
            if (-not (Test-Path -LiteralPath $payloadManifest -PathType Leaf)) {
                throw '缺少 VM_PAYLOAD_SHA256.txt，無法確認 Linux 資料包。'
            }
            $manifestLine = (Get-Content -LiteralPath $payloadManifest -Encoding ASCII -TotalCount 1)
            if ($manifestLine -cnotmatch '^([a-fA-F0-9]{64})  ShamiGo_v0\.10\.366_VM_Payload\.tar\.gz$') {
                throw 'VM_PAYLOAD_SHA256.txt 格式不正確。'
            }
            $expectedPackageHash = $Matches[1].ToLowerInvariant()
            $actualPayloadHash = (Get-FileHash -LiteralPath $payload -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($actualPayloadHash -ne $expectedPackageHash) {
                throw 'VM 安裝資料包 SHA-256 不一致，安裝已停止。'
            }
        }

        $script:VBoxExe = Get-VBoxManagePath
        $script:VM = Get-RunningVM
        $script:UserName = Read-Host 'Linux (Debian/LMDE) 登入帳號（不是 Windows 帳號）'
        if ($script:UserName -notmatch '^[a-z_][a-z0-9_-]*[$]?$') { throw 'Debian 登入帳號格式不正確。' }
        $passwordFile = New-PrivateCredentialFile
        $script:Auth = @( "--username=$script:UserName", "--passwordfile=$passwordFile" )

        Write-Host '連接 VirtualBox Guest Additions...' -ForegroundColor Cyan
        $probe = Invoke-GuestShell -Command 'printf SHAMIGO_GUEST_READY' -Phase '登入 LMDE 7 / Debian 13' -Quiet
        if ($probe -notmatch 'SHAMIGO_GUEST_READY') { throw 'Guest Control 無法執行 Linux 命令，請檢查 LMDE Guest Additions（VBoxService）。' }

        $ticket = [Guid]::NewGuid().ToString('N')
        $script:Stage = "/tmp/shamigo-v366-$ticket"
        Write-Host '建立 Debian 暫存資料夾...' -ForegroundColor Cyan
        # Always create the stage through the SAME authenticated Linux shell
        # used for installation.  This avoids guestcontrol mkdir/create ownership
        # differences and validates effective ownership before uploading secrets.
        # IMPORTANT: do not embed POSIX $(...) or double quotes in a native
        # VBoxManage argument from Windows PowerShell 5.1.  Fix3's nested quotes
        # led to: /bin/sh: Syntax error: end of file unexpected (expecting ")").
        # Each command below uses plain safe path tokens; ownership is checked
        # using two separate shell invocations rather than command substitution.
        $makeStage = ('umask 077; mkdir -m 700 -- {0} && test -d {0} && test -w {0} && test -x {0} && test ! -L {0} && printf SHAMIGO_STAGE_READY' -f $script:Stage)
        $stageResult = Invoke-GuestShell -Command $makeStage -Phase '以登入帳號建立 Debian 暫存目錄' -Quiet
        if ($stageResult -notmatch 'SHAMIGO_STAGE_READY') { throw 'Debian 暫存資料夾未能建立。' }
        $script:StagingMade = $true
        $userUid = (Invoke-GuestShell -Command 'id -u' -Phase '檢查 Debian 使用者 UID' -Quiet).Trim()
        $ownerUid = (Invoke-GuestShell -Command ("stat -c %u {0}" -f $script:Stage) -Phase '檢查暫存目錄擁有者' -Quiet).Trim()
        $stageMode = (Invoke-GuestShell -Command ("stat -c %a {0}" -f $script:Stage) -Phase '檢查暫存目錄權限' -Quiet).Trim()
        if ($userUid -notmatch '^[0-9]+$' -or $ownerUid -notmatch '^[0-9]+$' -or $userUid -ne $ownerUid -or $stageMode -ne '700') {
            throw ("Debian 暫存目錄擁有者或權限不正確 (UID {0}/{1}; mode {2})。" -f $userUid, $ownerUid, $stageMode)
        }

        Write-Host '傳送安裝或移除腳本...' -ForegroundColor Cyan
        Copy-GuestFile -Source $guestScript -Name 'ShamiGo_VM_Guest.sh'
        Copy-GuestFile -Source $platformScript -Name 'ShamiGo_Platform_Check.py'
        Copy-GuestFile -Source $preflightScript -Name 'ShamiGo_Dpkg_Preflight.sh'
        # Send the password last, after any large transfer succeeds.
        $sha = '0' * 64
        if ($Operation -eq 'install') {
            Write-Host '傳送v366 安裝資料包（程式及個人字庫）...' -ForegroundColor Cyan
            # Verify again just before transfer in case the archive changed.
            $sha = (Get-FileHash -LiteralPath $payload -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($sha -ne $expectedPackageHash) { throw 'VM payload changed during installation.' }
            Copy-GuestFile -Source $payload -Name 'ShamiGo_v0.10.366_VM_Payload.tar.gz'
        }
        Copy-GuestFile -Source $passwordFile -Name 'shamigo-credential.tmp'
        Write-Host '在 Debian 中執行操作...' -ForegroundColor Cyan
        $result = Invoke-VBox -VBoxArgs (@('guestcontrol',$script:VM,'run') + $script:Auth + @(
            '--exe=/bin/sh','--wait-stdout','--wait-stderr','--timeout=1800000','--',
            "$script:Stage/ShamiGo_VM_Guest.sh",$Operation,$script:Stage,$sha)) -Phase '執行 Debian 操作'
        if ($result -notmatch 'SHAMIGO_RESULT=OK') { throw 'Debian 未回傳成功標記，不能判定安裝已完成。' }
        if ($Operation -eq 'install') {
            Write-Host '安裝成功。請在 LMDE 登出再登入，然後從 Fcitx5 設定加入蝦米GO。' -ForegroundColor Green
            Write-Host '通常按 Ctrl+Space 可在 Debian 輸入法間切換；以 Fcitx5 快捷鍵設定為準。'
        } else {
            Write-Host '移除成功。個人字庫與設定保留。' -ForegroundColor Green
        }
        $status = 0
    } catch {
        Write-Host ''
        Write-Host ("操作失敗：{0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host '請確認 Guest Additions 已安裝、LMDE 帳密正確，或改在 LMDE 執行 Install_ShamiGo_LMDE7.sh。' -ForegroundColor Yellow
        $status = 1
    } finally {
        if (-not (Remove-GuestStage)) {
            Write-Host ("警告：Debian 暫存目錄清除未完成：{0}" -f $script:Stage) -ForegroundColor Yellow
            Write-Host '此目錄可能含暫時驗證資料，請從 Debian 終端機確認並刪除。' -ForegroundColor Yellow
            $status = 1
        }
        if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir -PathType Container)) {
            try {
                Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction Stop
            } catch {
                Write-Host ('警告：Windows 暫存資料無法刪除：' + $script:TempDir) -ForegroundColor Red
                $status = 1
            }
        }
    }
    return $status
}

function Show-Menu {
    while ($true) {
        Write-Host ''
        Write-Host '===================================================='
        Write-Host '  蝦米GO ShamiGo  Debian 13 / LMDE 7 / VirtualBox 安裝管理器' -ForegroundColor Cyan
        Write-Host '===================================================='
        Write-Host ' [1] 安裝或更新蝦米GO（保留個人資料）'
        Write-Host ' [2] 移除蝦米GO程式（保留個人字庫與設定）'
        Write-Host ' [0] 結束'
        Write-Host ''
        Write-Host '請先啟動並登入 VirtualBox 的 LMDE 7（或 Debian 13），並確認已安裝 Guest Additions。'
        $choice = Read-Host '請選擇 [1/2/0]'
        if ($choice -eq '0') { return 0 }
        if ($choice -notin @('1','2')) {
            Write-Host '請輸入 1、2 或 0。' -ForegroundColor Yellow
            continue
        }
        $operation = if ($choice -eq '1') { 'install' } else { 'remove' }
        $outcome = Invoke-ShamiGoAction -Operation $operation
        Write-Host ''
        if ($outcome -eq 0) {
            Write-Host '本次操作完成。' -ForegroundColor Green
        } else {
            Write-Host '本次操作沒有成功。請查看上方錯誤原因。' -ForegroundColor Red
        }
        [void](Read-Host '按 Enter 回到主選單')
    }
}

if ($Action -eq 'menu') {
    exit (Show-Menu)
}
exit (Invoke-ShamiGoAction -Operation $Action)
