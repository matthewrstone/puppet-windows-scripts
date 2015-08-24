Param(
  [string]$InstallDir,
  [string]$MasterServer,
  [string]$CAServer,
  [string]$CertName,
  [string]$Environment,
  [string]$StartupMode,
  [string]$User,
  [string]$Password,
  [string]$Domain,
  [string]$Source,
  [string]$Version,
  [string]$WorkDirectory,
  [switch]$Watch
)

[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[array]$installOptions = @()

If ($InstallDir) { $installOptions += "INSTALLDIR=$InstallDir"}
If ($MasterServer) { $installOptions += "PUPPET_MASTER_SERVER=$MasterServer"}
If ($CAServer) { $installOptions += "PUPPET_CA_SERVER=$CAServer "}
If ($CertName) { $installOptions += "PUPPET_AGENT_CERTNAME=$CertName "}
If ($Environment) { $installOptions += "PUPPET_AGENT_ENVIRONMENT=$Environment "}
If ($StartupMode) { $installOptions += "PUPPET_AGENT_STARTUP_MODE=$StartupMode "}
If ($User) { $installOptions += "PUPPET_AGENT_ACCOUNT_USER=$User "}
If ($Password) { $installOptions += "PUPPET_AGENT_ACCOUNT_PASSWORD=$Password "}
If ($Domain) { $installOptions += "PUPPET_AGENT_ACCOUNT_DOMAIN=$Domain "}
If (!($WorkDirectory)) { $WorkDirectory = 'c:\temp' }
If (!($Version)) { $Version = '3.7.2' }
If (!($Source)) { $Source = "https://s3.amazonaws.com/pe-builds/released/$Version" }
If ($Source -match ('http://|https://')) { $isUrl = 'True' } else { $isURL = 'False' }

function setWorkDirectory() {
  If ((Test-Path $WorkDirectory) -match 'False') {
    Write-Host "Creating Work Directory at $WorkDirectory..."
    New-Item -ItemType Directory -Path $WorkDirectory
  } 
    Write-Host "Changing to Work Directory $WorkDirectory..."
    Set-Location $WorkDirectory
}

function validateSource() {
  If ($isUrl -match 'True') {
    getInstaller
  } else {
    If ((Test-Path $Source/$packageName) -match 'True') {
      installPuppetViaFile
    } else {
      Write-Host "I don't know what to do with source $Source"
      break
    }
  }
}

function getInstaller() {
  $packageName = "puppet-enterprise-$Version-x64.msi"
  Write-Host "Getting $Source/$packageName"
  $uri = "$Source/$packageName"
  $obj = New-Object System.Net.WebClient
  $link = $obj.DownloadString($uri)
  Write-Host "Downloading Puppet Enterprise $Version"
  Write-Host "Saving Installer to $WorkDirectory\$packageName"
  Invoke-WebRequest $uri -OutFile $WorkDirectory\$packageName
  installPuppetViaWeb
}

function installPuppetViaWeb() {
  Write-Host "Installing Puppet Enterprise $Version"
  Invoke-Command -ScriptBlock { msiexec.exe /qn /i $WorkDirectory\$packageName $installOptions }
}

function installPuppetViaFile() {
    Write-Host "Installing Puppet Enterprise $Version"
    Invoke-Command -ScriptBlock { msiexec.exe /qn /i $Source\$packageName $installOptions }
}  
  
setWorkDirectory
validateSource

If ($Watch) {
 Write-Host "Waiting for initial Puppet run..."
  While (!(Get-EventLog -LogName Application -Source Puppet -Newest 10 -ErrorAction SilentlyContinue)) {Sleep -milliseconds 5}
  $logOld = Get-EventLog -LogName Application -Source Puppet -Newest 1
  $time = $logOld.TimeWritten
  $info = $logOld.EntryType
  $msg = $logOld.Message
  Write-Host "$time - $info - $msg"

  while ((Get-EventLog -LogName Application -Source Puppet -Newest 1).Message -notmatch 'Finished catalog run|Could not request certificate') {  
    $logNew = Get-EventLog -LogName Application -Source Puppet -Newest 1
    If (($logNew.Index) -notmatch $logOld.Index) {
      $time = $logNew.TimeWritten
      $info = $logNew.EntryType
      $msg = $logNew.Message
      Switch ($info) {
        "Error" { $fgColor = 'red' }
        "Information" { $fgColor = 'green' }
        "Warning" { $fgColor = 'yellow' } 
      }
      Write-Host "$time - $msg" -ForegroundColor $fgColor
    }
    $logOld = $logNew
  }
}
