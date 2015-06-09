Param(
  [string]$Version = "latest",
  [string]$Source = "https://downloads.puppetlabs.com/windows",
  [string]$Master,
  [string]$CAServer,
  [string]$WorkDirectory = 'C:\temp',
  [switch]$x86, # You must specify X86 if you want the 32 bit mode.  Nobody should want this.
  [switch]$FirstRun
)


# Gather all installation options from command line.
[System.Collections.ArrayList]$installOptions = @()
If ($InstallDir) { $installOptions += "INSTALLDIR=$InstallDir"}
If ($MasterServer) { $installOptions += "PUPPET_MASTER_SERVER=$MasterServer"}
If ($CAServer) { $installOptions += "PUPPET_CA_SERVER=$CAServer "}
If ($CertName) { $installOptions += "PUPPET_AGENT_CERTNAME=$CertName "}
If ($Environment) { $installOptions += "PUPPET_AGENT_ENVIRONMENT=$Environment "}
If ($StartupMode) { $installOptions += "PUPPET_AGENT_STARTUP_MODE=$StartupMode "}
If ($User) { $installOptions += "PUPPET_AGENT_ACCOUNT_USER=$User "}
If ($Password) { $installOptions += "PUPPET_AGENT_ACCOUNT_PASSWORD=$Password "}
If ($Domain) { $installOptions += "PUPPET_AGENT_ACCOUNT_DOMAIN=$Domain "}

# Setup the work directory
  If ((Test-Path $WorkDirectory) -match 'False') {
    Write-Host "Creating Work Directory at $WorkDirectory..."
    New-Item -ItemType Directory -Path $WorkDirectory
  } 

# Set the package name based on Puppet Labs current naming convention for the Windows agent.
switch($Version) {
  "latest" { 
    If ($x86) { $package = "puppet-latest.msi" } else { $package = "puppet-x64-latest.msi" }
   }
   default {
     If ($x86) { $package = "puppet-agent-$Version-x86.msi" } else { $package = "puppet-agent-$Version-x64.msi" }
   }
}

# Setup the rest of our variables
$installPuppet = "${WorkDirectory}\${package}"
$installArguments = '/burp'
$runPuppet = 'C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat -agent -t'

# Download Puppet from Puppet Labs
try {
  Write-Host "Downloading Puppet 4 package - ${package}..."
  Invoke-WebRequest ${source}/${package} -OutFile ${WorkDirectory}\${package}
} catch {
  Write-Host "ERROR - MSI Could not be downloaded.  Please check version and try again."
}
# Install the Puppet agent MSI
Write-Host "Installing Puppet Open Source 4.0 Windows Agent from ${installPuppet}..."
$installOptions.Insert(0,$installArguments)
Start-Process $installPuppet $installOptions -Wait

# Run Puppet for the first time if given the -FirstRun commandline switch
If ($FirstRun) { 
  Write-Host "Starting initial Puppet run..."
  Start-Process $runPuppet -wait
}