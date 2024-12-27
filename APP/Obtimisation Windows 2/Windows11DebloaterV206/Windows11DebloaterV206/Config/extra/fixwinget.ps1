Write-Output "###### Fix Winget Script: Running 'Config/extra/fixwinget.ps1' ######"
Write-Output "Downloading latest Winget installer package from Microsoft to install"
Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile winget.msixbundle
Add-AppPackage -ForceApplicationShutdown .\winget.msixbundle
del .\winget.msixbundle
Read-Host -Prompt "Done! Press Enter to exit"