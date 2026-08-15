###############################################################################
# KDE Connect SFTP to Windows Explorer
#
# PURPOSE
#
# Windows Explorer does not natively support SFTP locations. When selecting
# "Browse this device" in KDE Connect, Windows may therefore be unable to open
# the sftp:// link supplied by KDE Connect.
#
# This script acts as the Windows SFTP protocol handler and converts the
# connection supplied by KDE Connect into an SSHFS-Win drive.
#
# REQUIREMENTS
#
# - WinFsp
# - SSHFS-Win
#
# INSTALL
#
# Save this script somewhere under the current user's profile, for example:
#
#   %USERPROFILE%\Scripts\kdeconnect-sftp-mount.ps1
#
# Run the following commands from PowerShell as Administrator, replacing
# <SCRIPT_PATH> with the full path to this script:
#
#   reg add "HKCR\sftp" /ve /d "URL:SFTP Protocol" /f
#   reg add "HKCR\sftp" /v "URL Protocol" /d "" /f
#   reg add "HKCR\sftp\shell\open\command" /ve /d 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<SCRIPT_PATH>" "%1"' /f
#
# Example:
#
#   reg add "HKCR\sftp\shell\open\command" /ve /d 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\USERNAME\Scripts\kdeconnect-sftp-mount.ps1" "%1"' /f
#
# After registration, KDE Connect -> "Browse this device" invokes this script,
# mounts the supplied SFTP location using SSHFS-Win, and opens it in Explorer.
#
###############################################################################

param(
    [Parameter(Mandatory = $true)]
    [string]$Url
)

$uri = [System.Uri]$Url

$userInfo = $uri.UserInfo.Split(':', 2)

if ($userInfo.Count -lt 2) {
    Add-Type -AssemblyName PresentationFramework

    [System.Windows.MessageBox]::Show(
        "The KDE Connect SFTP URL did not contain authentication details.",
        "KDE Connect Files"
    )

    exit 1
}

$user = $userInfo[0]
$password = $userInfo[1]

$hostName = $uri.Host
$port = $uri.Port
$path = $uri.AbsolutePath.Trim('/').Replace('/', '\')

$drive = 'P:'

if ([string]::IsNullOrWhiteSpace($path)) {
    $remote = "\\sshfs.r\$user@$hostName!$port"
} else {
    $remote = "\\sshfs.r\$user@$hostName!$port\$path"
}

# Remove an existing mapping for the selected drive letter.
cmd /c "net use $drive /delete /y" 2>$null | Out-Null

# Map the KDE Connect SFTP location using its temporary credentials.
cmd /c "net use $drive `"$remote`" `"$password`" /user:$user /persistent:no"

if ($LASTEXITCODE -eq 0) {

    Start-Process explorer.exe "$drive\"

} else {

    Add-Type -AssemblyName PresentationFramework

    [System.Windows.MessageBox]::Show(
        "Could not mount the device as $drive",
        "KDE Connect Files"
    )
}
