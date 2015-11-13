Param(
  [Parameter(Mandatory=$true)] $TempFolder,
  [String] $DebugFolder = "${TempFolder}\Debug"
)

$ErrorActionPreference = 'SilentlyContinue'

If (!(Test-Path $DebugFolder)) { New-Item $DebugFolder -ItemType Directory -Force }

#$TempFolder     = "C:\Users\vagrant\AppData\Local\Temp\1"
$PsQuery   = "${TempFolder}\*.ps1"
$PsList    = (Get-Item $PsQuery).Name
$LastLog   = Get-EventLog -LogName Application -Source Puppet -Newest 1 -ErrorAction SilentlyContinue

Write-Host "Starting Puppet Agent run..."

$puppetJob = Start-Job -Name RunPuppetAgent -ScriptBlock { puppet agent -td }; $puppetJob

Write-Host ""
Write-Host "Puppet run has begun!" -ForegroundColor Green

while ($puppetJob.State -eq 'Running') {
  $CurrentLog = Get-EventLog -LogName Application -Source Puppet -Newest 1 -ErrorAction SilentlyContinue
  If (!($CurrentLog.TimeGenerated -eq $LastLog.TimeGenerated)) {
    $CurrentLog.Message
    $LastLog = $CurrentLog
  }
  $PsOutput = (Get-Item $PsQuery).Name
  If ($PsOutput) {
    Foreach ( $file in $PsOutput ) {
      $DebugFile = "${DebugFolder}\${file}"
      If (!(Get-Item $DebugFile)) {
        Copy-Item "${TempFolder}\${file}" $DebugFile -Force
        Write-Host "Wrote $DebugFile..." -ForegroundColor Yellow
      }
    }
  }
  Sleep -Milliseconds 10
  $puppetStatus = (Get-Item $lockFile).Name
}

Write-Host "Puppet run has ended.  Opening Debug Folder." -ForegroundColor Green
Invoke-Item C:\Windows\explorer.exe $DebugFolder