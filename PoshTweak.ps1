<#
.SYNOPSIS
   Automates PowerShell terminal customization and system-wide Registry
   optimizations.

.DESCRIPTION
   PoshTweak customizes the PowerShell environment across all user profiles on
   Windows. It configures console colors (Catppuccin Macchiato), applies
   custom fonts (Hack), removes restrictive Registry overrides for
   Administrator consoles, and injects a custom lightweight prompt without
   degrading startup performance.

   Key Features:
   - Sets global terminal colors and font parameters via Windows Registry.
   - Cleans up system-level Registry overrides (%SystemRoot%_System32...) to
     ensure consistent themes in elevated (Administrator) shells.
   - Safely injects/updates custom prompt logic in $PROFILE using marker bounds.
   - Handles NTUSER.DAT lock release with aggressive Garbage Collection during
     Default User profile modifications.

.PARAMETER Force
   Optional switch to force profile recreation or bypass user prompts
   (if applicable).

.EXAMPLE
   PS C:\> .\PoshTweak.ps1
   Applies default Catppuccin theme, registry tweaks, and updates profile.

.INPUTS
   None. You cannot pipe objects to PoshTweak.ps1.

.OUTPUTS
   System.String / Console Output. Displays task execution progress and status.

.NOTES
   File Name      : PoshTweak.ps1
   Version        : 1.0.0
   Author         : Burak Yeşilyurt
   Date Created   : 27/07/2026
   Date Updated   : 28/07/2026
   Prerequisites  : PowerShell 5.1+, winget, Administrator Rights (for Registry
                    and Default User edits)
   License        : MIT License
   Tested Environment:
      - Hardware: ASUS TUF A15 FA507XI LP013
      - OS: Windows 11 Pro 25H2 (OS Build 26200.8894)
      - Shell: PowerShell 5.1 & PowerShell 7.x
#>


# ==============================================================================
# Command line parameters
# ==============================================================================

[CmdletBinding()]
param (
   [Switch]$Force
)


# ==============================================================================
# Ensure script is running with Administrative Privileges
# ==============================================================================

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

# Check if the current user session holds the Administrator role
if (
   -not $principal.IsInRole(
      [Security.Principal.WindowsBuiltInRole]::Administrator
   )
) {
   Write-Host -ForegroundColor Red `
      "[X] ERROR: This script must be executed as Administrator!"
   Exit 1
}


# ==============================================================================
# Check Windows version for Winget compatibility
# ==============================================================================

$WindowsBuild = [System.Environment]::OSVersion.Version.Build

# Winget requires Windows 10 build 17763 or later
if ($WindowsBuild -lt 17763) {
   Write-Host -ForegroundColor Red `
      "[X] Windows version is too old for winget."
   Exit 1
}


# ==============================================================================
# Check Winget availability and attempt to register if missing
# ==============================================================================

$Winget = Get-Command winget -ErrorAction SilentlyContinue

if (-not $Winget) {
   Write-Host -ForegroundColor Yellow `
      "[!] winget not found. Trying to register App Installer..."

   # Attempt to manually register the App Installer package
   try {
      Add-AppxPackage -RegisterByFamilyName `
         -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe `
         -ErrorAction Stop
      Start-Sleep -Seconds 3
   } catch {
      Write-Host -ForegroundColor Red `
         "[X] Unable to register winget automatically."
      Write-Host -ForegroundColor Yellow `
         "Please install App Installer from Microsoft Store."
      Exit 1
   }

   # Re-evaluate Winget availability after registration attempt
   $Winget = Get-Command winget -ErrorAction SilentlyContinue
}

if ($Winget) {
   Write-Host -ForegroundColor Green "[+] winget is available."
} else {
   Write-Host -ForegroundColor Red "[X] winget is still unavailable."
   Exit 1
}


# ==============================================================================
# Install or Update Latest PowerShell 7
# ==============================================================================

$PowerShellInstalled = Get-Command pwsh -ErrorAction SilentlyContinue

if (-not $PowerShellInstalled) {
   Write-Host -ForegroundColor Yellow "[+] Installing PowerShell 7..."

   # Install quietly using winget
   winget install --id Microsoft.PowerShell --exact --silent `
      --accept-package-agreements --accept-source-agreements
 
   Start-Sleep -Seconds 5
} else {
   Write-Host -ForegroundColor Green `
      "[+] PowerShell 7 detected. Checking updates..."

   # Upgrade quietly, discarding standard error stream (2>$null)
   winget upgrade --id Microsoft.PowerShell --silent `
      --accept-package-agreements --accept-source-agreements 2>$null
}


# ==============================================================================
# Install Hack Font if missing
# ==============================================================================

$FontName = "Hack"

# Search for the font in the Windows Registry
$FontInstalled = Get-ItemProperty `
   -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" |
   Select-Object -Property * |
   Out-String |
   Select-String $FontName

if (-not $FontInstalled) {
   Write-Host -ForegroundColor Yellow "[+] Hack font not found. Installing..."

   winget install --id SourceFoundry.HackFonts --exact --silent `
      --accept-package-agreements --accept-source-agreements
} else {
   Write-Host -ForegroundColor Green "[+] Hack font already installed."
}


# ==============================================================================
# PowerShell Prompt Customization
# ==============================================================================

# Allow execution of local scripts to prevent profile loading errors
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine `
   -Force -ErrorAction SilentlyContinue

# Define the custom prompt function as a string to be written to profiles
$PromptCode = @'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$global:isAdmin = $principal.IsInRole(
   [Security.Principal.WindowsBuiltInRole]::Administrator
)

function prompt
{
   if ($global:isAdmin) {
      $symbol = "#"
      $userColor = "Red"
      $symbolColor = "Red"
      $pathColor = "DarkYellow"
   } else {
      $symbol = '$'
      $userColor = "Green"
      $symbolColor = "Green"
      $pathColor = "Blue"
   }

   Write-Host "$env:USERNAME@$env:COMPUTERNAME " -NoNewline `
      -ForegroundColor $userColor
   Write-Host "$PWD " -NoNewline `
      -ForegroundColor $pathColor
   Write-Host $symbol -NoNewline `
      -ForegroundColor $symbolColor

   return " "
}
'@


# ==============================================================================
# Install Prompt Profiles
# ==============================================================================

$Profiles = @( $PROFILE.AllUsersAllHosts )
$PowerShell7Profile = "C:\Program Files\PowerShell\7\profile.ps1"

if (Test-Path "C:\Program Files\PowerShell\7") {
   $Profiles += $PowerShell7Profile
}

# Unique markers to identify and replace our block in the future
$MarkerStart = "# === CUSTOM TERMINAL PROMPT START ==="
$MarkerEnd   = "# === CUSTOM TERMINAL PROMPT END ==="

foreach ($ProfilePath in $Profiles) {
   $ProfileDir = Split-Path $ProfilePath

   # Ensure the directory exists
   if (-not (Test-Path $ProfileDir)) {
      New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
   }

   # Ensure the file exists
   if (-not (Test-Path $ProfilePath)) {
      New-Item -Path $ProfilePath -ItemType File -Force | Out-Null
   }

   # Read existing content
   $CurrentProfile = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue

   if ($null -eq $CurrentProfile) {
       $CurrentProfile = ""
   }

   if ($Force) {
      # Overrides the old profile
      $NewContent = "$MarkerStart`n$PromptCode`n$MarkerEnd`n"
      Write-Host -ForegroundColor Yellow `
         "[!] Force switch used. Recreating profile from scratch..."
   } else {
      # Remove old custom prompt block if it exists (using Regex)
      $Pattern = "(?s)\r?\n?$([regex]::Escape($MarkerStart)).*?" +
                 "$([regex]::Escape($MarkerEnd))\r?\n?"

      $CurrentProfile = $CurrentProfile -replace $Pattern, ""

      # Append the new prompt block safely to the end
      $NewContent = $CurrentProfile.TrimEnd() +
                    "`n`n$MarkerStart`n$PromptCode`n$MarkerEnd`n"
   }

   # Write back the new configuration
   Set-Content -Path $ProfilePath -Value $NewContent -Force

   Write-Host -ForegroundColor Green "[+] Prompt updated: $ProfilePath"
}


# ==============================================================================
# Console Registry Settings (Catppuccin Macchiato Theme)
# ==============================================================================

$ConsoleColors = @{
   "ColorTable00" = 0x302424
   "ColorTable01" = 0xa6573b
   "ColorTable02" = 0x83c0a6
   "ColorTable03" = 0xdac88a
   "ColorTable04" = 0x7162ed
   "ColorTable05" = 0xd17ecb
   "ColorTable06" = 0x6ce0ee
   "ColorTable07" = 0xcad1b8
   "ColorTable08" = 0x524349
   "ColorTable09" = 0xdd8880
   "ColorTable10" = 0x83c0a6
   "ColorTable11" = 0xdac88a
   "ColorTable12" = 0x7162ed
   "ColorTable13" = 0xd17ecb
   "ColorTable14" = 0x6ce0ee
   "ColorTable15" = 0xe8f0ca
}

function Set-ConsoleTheme {
   param ([string]$Path)

   # Create the base console key if it doesn't exist
   if (-not (Test-Path $Path)) {
      New-Item -Path $Path -Force | Out-Null
   }

   # Apply color values
   foreach ($Color in $ConsoleColors.GetEnumerator()) {
      Set-ItemProperty -Path $Path -Name $Color.Key -Value $Color.Value `
         -Type DWord -ErrorAction SilentlyContinue
   }

   # Apply font settings
   Set-ItemProperty -Path $Path -Name "FaceName" -Value "Hack" `
      -Type String -ErrorAction SilentlyContinue

   Set-ItemProperty -Path $Path -Name "FontFamily" -Value 0x36 `
      -Type DWord -ErrorAction SilentlyContinue

   # Remove specific shortcut subkeys that override the global theme
   $Pwsh5Subkey =
      "$Path\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe"
   $Pwsh7Subkey = "$Path\pwsh.exe"

   if (Test-Path $Pwsh5Subkey){
      Remove-Item -Path $Pwsh5Subkey -Force -Recurse `
         -ErrorAction SilentlyContinue
   }

   if (Test-Path $Pwsh7Subkey){
      Remove-Item -Path $Pwsh7Subkey -Force -Recurse `
         -ErrorAction SilentlyContinue
   }
}


# ==============================================================================
# Apply Theme To Existing Users
# ==============================================================================

# Filter valid standard user SIDs (ignores system/service accounts and _Classes)
$LoadedUsers = Get-ChildItem Registry::HKEY_USERS |
   Where-Object { $_.PSChildName -match "^S-1-5-21-[\d\-]+$" }

foreach ($User in $LoadedUsers) {
   try {
      $ConsolePath = "Registry::HKEY_USERS\$($User.PSChildName)\Console"
      Set-ConsoleTheme -Path $ConsolePath
      Write-Host -ForegroundColor Green `
         "[+] Console theme applied: $($User.PSChildName)"
   } catch {
      Write-Host -ForegroundColor Yellow `
         ("[!] Skipped profile (might be locked or incomplete): " +
         $User.PSChildName)
   }
}


# ==============================================================================
# Apply Theme To Default User Profile
# ==============================================================================

$DefaultHive = "C:\Users\Default\NTUSER.DAT"

if (Test-Path $DefaultHive) {
   # Load the default user hive temporarily
   reg load HKU\DefaultUser $DefaultHive 2>$null

   if ($LASTEXITCODE -eq 0) {
      Set-ConsoleTheme -Path "Registry::HKEY_USERS\DefaultUser\Console"

      # Force garbage collection to release file lock on NTUSER.DAT
      [GC]::Collect()
      Start-Sleep -Milliseconds 200

      # Unload the hive
      reg unload HKU\DefaultUser 2>$null
      Write-Host -ForegroundColor Green "[+] Default user profile updated."
   }
}


# ==============================================================================
# Completed
# ==============================================================================

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host " Terminal customization completed!" -ForegroundColor Cyan
Write-Host " Restart terminal to apply changes." -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan

