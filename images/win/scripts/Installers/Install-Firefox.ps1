################################################################################
##  File:  Install-Firefox.ps1
##  Desc:  Install Mozilla Firefox
################################################################################

Import-Module -Name ImageHelpers -Force
Import-Module -Name PathHelpers -Force

$temp_install_dir = 'C:\Windows\Installer'
New-Item -Path $temp_install_dir -ItemType Directory -Force

$versionsJson = Invoke-WebRequest  "https://product-details.mozilla.org/1.0/firefox_versions.json" | ConvertFrom-Json
$latestVersion = $($versionsJson.LATEST_FIREFOX_VERSION)
Write-Host "Firefox latest version: $latestVersion"

# url for latest version of firefox
$urlLatestVersion = "https://download.mozilla.org/?product=firefox-${latestVersion}&os=win64&lang=en-US"
Install-EXE -Url $urlLatestVersion -Name "Firefox Setup $latestVersion.exe" -ArgumentList ("/silent", "/install")

# Disable autoupdate
$firefoxDirectoryPath = Join-Path $env:SystemDrive "Program Files\Mozilla Firefox"
New-Item -path $firefoxDirectoryPath -Name 'mozilla.cfg' -Value '//
pref("browser.shell.checkDefaultBrowser", false);
pref("app.update.enabled", false);' -ItemType file -force

$firefoxPreferencesFolder = Join-Path $firefoxDirectoryPath "defaults\pref"
New-Item -path $firefoxPreferencesFolder -Name 'local-settings.js' -Value 'pref("general.config.obscure_value", 0);
pref("general.config.filename", "mozilla.cfg");' -ItemType file -force

Write-Host "Install Firefox WebDriver"

$geckodriverJson = Invoke-RestMethod "https://api.github.com/repos/mozilla/geckodriver/releases/latest"
$geckodriverWindowsAsset = $geckodriverJson.assets | Where-Object { $_.name -Match "win64" } | Select-Object -First 1

Write-Host "Geckodriver version: $($geckodriverJson.tag_name)"


$DriversZipFile = $geckodriverWindowsAsset.name
Write-Host "Selenium drivers download and install..."

$FirefoxDriverPath = Join-Path $env:SystemDrive "SeleniumWebDrivers\GeckoDriver"

# Install Firefox Web Driver
Write-Host "FireFox driver download...."
if (-not (Test-Path -Path $FireFoxDriverPath)) {
    New-Item -Path $FireFoxDriverPath -ItemType "directory"
}

$DestFile = "$FireFoxDriverPath\$name"
$EdgeDriverDownloadUrl = $geckodriverWindowsAsset.browser_download_url
try{
    Invoke-WebRequest -Uri $EdgeDriverDownloadUrl -OutFile $DestFile
} catch {
    Write-Error "[!] Failed to download $name"
    exit 1
}

Write-Host "FireFox driver install...."
Expand-Archive -Path $DestFile -DestinationPath $FireFoxDriverPath -Force
Remove-Item -Path $DestFile -Force


Write-Host "Setting the environment variables"
Add-MachinePathItem -PathItem $FireFoxDriverPath

exit 0