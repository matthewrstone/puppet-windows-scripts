# Puppet-Windows-Scripts

Powershell scripts to make some puppet on Windows stuff work a little less annoying.

## PuppetExecDebug.ps1

**Description** 

This script will watch your temp directory while Puppet runs and copy any PS1 scripts to a debug folder for review once the run has completed. Why make this? If you've ever had some interpolation issues with Puppet sending PowerShell commands or scripts, this will park them so you can review if there are any mistakes.  Pretty much just a simple "I'm not crazy, right?" insurance policy.

**Usage** 
	
	.\PuppetExecDebug.ps1 -TempFolder <your_temp_folder> -DebugFolder <your_debug_folder>

*Note: The Debug folder will be created if it does not exist.*

## puppet-enterprise-installer.ps1

**Description**

Grab the Puppet Enterprise agent MSI from a specified source (Puppet Labs @ AWS, by default) and install the agent.

**Usage**

Coming Soon...

## puppet-4-installer.ps1

Grab the Puppet open source agent MSI from a specified source (Puppet Labs @ AWS, by default) and install the agent

**Usage**

Coming Soon...


