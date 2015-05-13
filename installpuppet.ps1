Param(
  [string]$InstallDir,
  [string]$Master,
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
  [switch]$UseMasterAsSource
)

[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[array]$installOptions = @()

If ($InstallDir) { $installOptions += "INSTALLDIR=$InstallDir"}
If ($Master) { $installOptions += "PUPPET_MASTER_SERVER=$Master"}
If ($CAServer) { $installOptions += "PUPPET_CA_SERVER=$CAServer "}
If ($CertName) { $installOptions += "PUPPET_AGENT_CERTNAME=$CertName "}
If ($Environment) { $installOptions += "PUPPET_AGENT_ENVIRONMENT=$Environment "}
If ($StartupMode) { $installOptions += "PUPPET_AGENT_STARTUP_MODE=$StartupMode "}
If ($User) { $installOptions += "PUPPET_AGENT_ACCOUNT_USER=$User "}
If ($Password) { $installOptions += "PUPPET_AGENT_ACCOUNT_PASSWORD=$Password "}
If ($Domain) { $installOptions += "PUPPET_AGENT_ACCOUNT_DOMAIN=$Domain "}
If (!($WorkDirectory)) { $WorkDirectory = 'c:\temp' }
If (!($Version)) { $Version = '3.8.0' }
Write-Host $Master
Write-Host $UseMasterAsSource
If (!($Source)) { 
  If ($UseMasterAsSource -match 'True') {
    $Source = "https://$Master`:8041/packages/current/$packageName"
  } else { 
    $Source = "https://s3.amazonaws.com/pe-builds/released/$Version"
  }
}

# Validate $Source as URL or Other.
If ($Source -match ('http://|https://')) {
  $isUrl = 'True'
  # Check for Server Core
  If ((Get-WindowsFeature Server-Gui-Shell).Installed -match 'False') {
    Write-Host "You are running Server Core."
    $webCmd = "Invoke-WebRequest $uri -OutFile $WorkDirectory\$packageName -UseBasicParsing"
  } else {
    Write-Host "You are running Windows with a GUI."
    $webCmd = "Invoke-WebRequest $uri -OutFile $WorkDirectory\$packageName"
  }
} else {
  $isURL = 'False'
}


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
  Invoke-Command -ScriptBlock { msiexec.exe /qn $WorkDirectory\$packageName $installOptions }
}

function installPuppetViaFile() {
    Write-Host "Installing Puppet Enterprise $Version"
    Invoke-Command -ScriptBlock { msiexec.exe /qn $Source\$packageName $installOptions }
}  
  
setWorkDirectory
validateSource