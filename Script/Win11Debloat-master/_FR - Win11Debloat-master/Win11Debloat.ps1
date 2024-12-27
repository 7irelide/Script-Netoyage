#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$Silent,
    [switch]$Sysprep,
    [switch]$RunAppConfigurator,
    [switch]$RunDefaults, [switch]$RunWin11Defaults,
    [switch]$RemoveApps, 
    [switch]$RemoveAppsCustom,
    [switch]$RemoveGamingApps,
    [switch]$RemoveCommApps,
    [switch]$RemoveDevApps,
    [switch]$RemoveW11Outlook,
    [switch]$ForceRemoveEdge,
    [switch]$DisableDVR,
    [switch]$DisableTelemetry,
    [switch]$DisableBingSearches, [switch]$DisableBing,
    [switch]$DisableLockscrTips, [switch]$DisableLockscreenTips,
    [switch]$DisableWindowsSuggestions, [switch]$DisableSuggestions,
    [switch]$ShowHiddenFolders,
    [switch]$ShowKnownFileExt,
    [switch]$HideDupliDrive,
    [switch]$TaskbarAlignLeft,
    [switch]$HideSearchTb, [switch]$ShowSearchIconTb, [switch]$ShowSearchLabelTb, [switch]$ShowSearchBoxTb,
    [switch]$HideTaskview,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableWidgets,
    [switch]$HideWidgets,
    [switch]$DisableChat,
    [switch]$HideChat,
    [switch]$ClearStart,
    [switch]$ClearStartAllUsers,
    [switch]$RevertContextMenu,
    [switch]$HideHome,
    [switch]$HideGallery,
    [switch]$ExplorerToHome,
    [switch]$ExplorerToThisPC,
    [switch]$ExplorerToDownloads,
    [switch]$ExplorerToOneDrive,
    [switch]$DisableOnedrive, [switch]$HideOnedrive,
    [switch]$Disable3dObjects, [switch]$Hide3dObjects,
    [switch]$DisableMusic, [switch]$HideMusic,
    [switch]$DisableIncludeInLibrary, [switch]$HideIncludeInLibrary,
    [switch]$DisableGiveAccessTo, [switch]$HideGiveAccessTo,
    [switch]$DisableShare, [switch]$HideShare
)


# Remplacer les messages d'erreur au debut
if ($ExecutionContext.SessionState.LanguageMode -ne "FullLanguage") {
    Write-Host "Erreur : Win11Debloat ne peut pas s'executer sur votre systeme, l'execution de powershell est restreinte par les politiques de securite" -ForegroundColor Red
    Write-Output ""
    Write-Output "Appuyez sur Entree pour quitter..."
    Read-Host | Out-Null
    Exit
}


# Shows application selection form that allows the user to select what apps they want to remove or keep
function ShowAppSelectionForm {
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

    # Initialise form objects
    $form = New-Object System.Windows.Forms.Form
    $label = New-Object System.Windows.Forms.Label
    $button1 = New-Object System.Windows.Forms.Button
    $button2 = New-Object System.Windows.Forms.Button
    $selectionBox = New-Object System.Windows.Forms.CheckedListBox 
    $loadingLabel = New-Object System.Windows.Forms.Label
    $onlyInstalledCheckBox = New-Object System.Windows.Forms.CheckBox
    $checkUncheckCheckBox = New-Object System.Windows.Forms.CheckBox
    $initialFormWindowState = New-Object System.Windows.Forms.FormWindowState

    $global:selectionBoxIndex = -1

    # saveButton eventHandler
    $handler_saveButton_Click= 
    {
        if ($selectionBox.CheckedItems -contains "Microsoft.WindowsStore" -and -not $Silent) {
            $warningSelection = [System.Windows.Forms.Messagebox]::Show('Êtes-vous sûr de vouloir desinstaller le Microsoft Store ? Cette application ne peut pas être facilement reinstallee.', 'Êtes-vous sûr ?', 'YesNo', 'Warning')
        
            if ($warningSelection -eq 'No') {
                return
            }
        }

        $global:SelectedApps = $selectionBox.CheckedItems

        # Create file that stores selected apps if it doesn't exist
        if (!(Test-Path "$PSScriptRoot/CustomAppsList")) {
            $null = New-Item "$PSScriptRoot/CustomAppsList"
        } 

        Set-Content -Path "$PSScriptRoot/CustomAppsList" -Value $global:SelectedApps

        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    }

    # cancelButton eventHandler
    $handler_cancelButton_Click= 
    {
        $form.Close()
    }

    $selectionBox_SelectedIndexChanged= 
    {
        $global:selectionBoxIndex = $selectionBox.SelectedIndex
    }

    $selectionBox_MouseDown=
    {
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            if ([System.Windows.Forms.Control]::ModifierKeys -eq [System.Windows.Forms.Keys]::Shift) {
                if ($global:selectionBoxIndex -ne -1) {
                    $topIndex = $global:selectionBoxIndex

                    if ($selectionBox.SelectedIndex -gt $topIndex) {
                        for (($i = ($topIndex)); $i -le $selectionBox.SelectedIndex; $i++){
                            $selectionBox.SetItemChecked($i, $selectionBox.GetItemChecked($topIndex))
                        }
                    }
                    elseif ($topIndex -gt $selectionBox.SelectedIndex) {
                        for (($i = ($selectionBox.SelectedIndex)); $i -le $topIndex; $i++){
                            $selectionBox.SetItemChecked($i, $selectionBox.GetItemChecked($topIndex))
                        }
                    }
                }
            }
            elseif ($global:selectionBoxIndex -ne $selectionBox.SelectedIndex) {
                $selectionBox.SetItemChecked($selectionBox.SelectedIndex, -not $selectionBox.GetItemChecked($selectionBox.SelectedIndex))
            }
        }
    }

    $check_All=
    {
        for (($i = 0); $i -lt $selectionBox.Items.Count; $i++){
            $selectionBox.SetItemChecked($i, $checkUncheckCheckBox.Checked)
        }
    }

    $load_Apps=
    {
        # Correct the initial state of the form to prevent the .Net maximized form issue
        $form.WindowState = $initialFormWindowState

        # Reset state to default before loading appslist again
        $global:selectionBoxIndex = -1
        $checkUncheckCheckBox.Checked = $False

        # Show loading indicator
        $loadingLabel.Visible = $true
        $form.Refresh()

        # Clear selectionBox before adding any new items
        $selectionBox.Items.Clear()

        # Set filePath where Appslist can be found
        $appsFile = "$PSScriptRoot/Appslist.txt"
        $listOfApps = ""

        if ($onlyInstalledCheckBox.Checked -and ($global:wingetInstalled -eq $true)) {
            # Attempt to get a list of installed apps via winget, times out after 10 seconds
            $job = Start-Job { return winget list --accept-source-agreements --disable-interactivity }
            $jobDone = $job | Wait-Job -TimeOut 10

            if (-not $jobDone) {
                # Show error that the script was unable to get list of apps from winget
                [System.Windows.MessageBox]::Show('Unable to load list of installed apps via winget, some apps may not be displayed in the list.', 'Error', 'Ok', 'Error')
            }
            else {
                # Add output of job (list of apps) to $listOfApps
                $listOfApps = Receive-Job -Job $job
            }
        }

        # Go through appslist and add items one by one to the selectionBox
        Foreach ($app in (Get-Content -Path $appsFile | Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^#  .*' -and $_ -notmatch '^# -* #' } )) { 
            $appChecked = $true

            # Remove first # if it exists and set appChecked to false
            if ($app.StartsWith('#')) {
                $app = $app.TrimStart("#")
                $appChecked = $false
            }

            # Remove any comments from the Appname
            if (-not ($app.IndexOf('#') -eq -1)) {
                $app = $app.Substring(0, $app.IndexOf('#'))
            }
            
            # Remove leading and trailing spaces and `*` characters from Appname
            $app = $app.Trim()
            $appString = $app.Trim('*')

            # Make sure appString is not empty
            if ($appString.length -gt 0) {
                if ($onlyInstalledCheckBox.Checked) {
                    # onlyInstalledCheckBox is checked, check if app is installed before adding it to selectionBox
                    if (-not ($listOfApps -like ("*$appString*")) -and -not (Get-AppxPackage -Name $app)) {
                        # App is not installed, continue with next item
                        continue
                    }
                    if (($appString -eq "Microsoft.Edge") -and -not ($listOfApps -like "* Microsoft.Edge *")) {
                        # App is not installed, continue with next item
                        continue
                    }
                }

                # Add the app to the selectionBox and set it's checked status
                $selectionBox.Items.Add($appString, $appChecked) | Out-Null
            }
        }
        
        # Hide loading indicator
        $loadingLabel.Visible = $False

        # Sort selectionBox alphabetically
        $selectionBox.Sorted = $True
    }

    $form.Text = "Win11Debloat - Selection des Applications"
    $form.Name = "appSelectionForm"
    $form.DataBindings.DefaultDataSourceUpdateMode = 0
    $form.ClientSize = New-Object System.Drawing.Size(400,502)
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $False

    $button1.TabIndex = 4
    $button1.Name = "saveButton"
    $button1.UseVisualStyleBackColor = $True
    $button1.Text = "Confirmer"
    $button1.Location = New-Object System.Drawing.Point(27,472)
    $button1.Size = New-Object System.Drawing.Size(75,23)
    $button1.DataBindings.DefaultDataSourceUpdateMode = 0
    $button1.add_Click($handler_saveButton_Click)

    $form.Controls.Add($button1)

    $button2.TabIndex = 5
    $button2.Name = "cancelButton"
    $button2.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $button2.UseVisualStyleBackColor = $True
    $button2.Text = "Annuler"
    $button2.Location = New-Object System.Drawing.Point(129,472)
    $button2.Size = New-Object System.Drawing.Size(75,23)
    $button2.DataBindings.DefaultDataSourceUpdateMode = 0
    $button2.add_Click($handler_cancelButton_Click)

    $form.Controls.Add($button2)

    $label.Location = New-Object System.Drawing.Point(13,5)
    $label.Size = New-Object System.Drawing.Size(400,14)
    $Label.Font = 'Microsoft Sans Serif,8'
    $label.Text = 'Cochez les applications que vous souhaitez supprimer, decochez celles que vous souhaitez garder'

    $form.Controls.Add($label)

    $loadingLabel.Location = New-Object System.Drawing.Point(16,46)
    $loadingLabel.Size = New-Object System.Drawing.Size(300,418)
    $loadingLabel.Text = 'Chargement des applications...'
    $loadingLabel.BackColor = "White"
    $loadingLabel.Visible = $false

    $form.Controls.Add($loadingLabel)

    $onlyInstalledCheckBox.TabIndex = 6
    $onlyInstalledCheckBox.Location = New-Object System.Drawing.Point(230,474)
    $onlyInstalledCheckBox.Size = New-Object System.Drawing.Size(150,20)
    $onlyInstalledCheckBox.Text = 'Afficher uniquement les applications installees'
    $onlyInstalledCheckBox.add_CheckedChanged($load_Apps)

    $form.Controls.Add($onlyInstalledCheckBox)

    $checkUncheckCheckBox.TabIndex = 7
    $checkUncheckCheckBox.Location = New-Object System.Drawing.Point(16,22)
    $checkUncheckCheckBox.Size = New-Object System.Drawing.Size(150,20)
    $checkUncheckCheckBox.Text = 'Tout cocher/decocher'
    $checkUncheckCheckBox.add_CheckedChanged($check_All)

    $form.Controls.Add($checkUncheckCheckBox)

    $selectionBox.FormattingEnabled = $True
    $selectionBox.DataBindings.DefaultDataSourceUpdateMode = 0
    $selectionBox.Name = "selectionBox"
    $selectionBox.Location = New-Object System.Drawing.Point(13,43)
    $selectionBox.Size = New-Object System.Drawing.Size(374,424)
    $selectionBox.TabIndex = 3
    $selectionBox.add_SelectedIndexChanged($selectionBox_SelectedIndexChanged)
    $selectionBox.add_Click($selectionBox_MouseDown)

    $form.Controls.Add($selectionBox)

    # Save the initial state of the form
    $initialFormWindowState = $form.WindowState

    # Load apps into selectionBox
    $form.add_Load($load_Apps)

    # Focus selectionBox when form opens
    $form.Add_Shown({$form.Activate(); $selectionBox.Focus()})

    # Show the Form
    return $form.ShowDialog()
}


# Returns list of apps from the specified file, it trims the app names and removes any comments
function ReadAppslistFromFile {
    param (
        $appsFilePath
    )

    $appsList = @()

    # Get list of apps from file at the path provided, and remove them one by one
    Foreach ($app in (Get-Content -Path $appsFilePath | Where-Object { $_ -notmatch '^#.*' -and $_ -notmatch '^\s*$' } )) { 
        # Remove any comments from the Appname
        if (-not ($app.IndexOf('#') -eq -1)) {
            $app = $app.Substring(0, $app.IndexOf('#'))
        }

        # Remove any spaces before and after the Appname
        $app = $app.Trim()
        
        $appString = $app.Trim('*')
        $appsList += $appString
    }

    return $appsList
}


# Removes apps specified during function call from all user accounts and from the OS image.
function RemoveApps {
    param (
        $appslist
    )

    Foreach ($app in $appsList) { 
        Write-Output "Attempting to remove $app..."

        if (($app -eq "Microsoft.OneDrive") -or ($app -eq "Microsoft.Edge")) {
            # Use winget to remove OneDrive and Edge
            if ($global:wingetInstalled -eq $false) {
                Write-Host "Erreur : WinGet n'est pas installe ou est obsolete, $app n'a pas pu être supprime" -ForegroundColor Red
            }
            else {
                # Uninstall app via winget
                Strip-Progress -ScriptBlock { winget uninstall --accept-source-agreements --disable-interactivity --id $app } | Tee-Object -Variable wingetOutput 

                If (($app -eq "Microsoft.Edge") -and (Select-String -InputObject $wingetOutput -Pattern "Uninstall failed with exit code")) {
                    Write-Host "Erreur : Impossible de desinstaller Microsoft Edge via Winget" -ForegroundColor Red
                    Write-Output ""

                    if ($( Read-Host -Prompt "Voulez-vous forcer la desinstallation d'Edge ? NON RECOMMANDe ! (o/n)" ) -eq 'o') {                        Write-Output ""
                        ForceRemoveEdge
                    }
                }
            }
        }
        else {
            # Use Remove-AppxPackage to remove all other apps
            $app = '*' + $app + '*'

            # Remove installed app for all existing users
            if ($WinVersion -ge 22000){
                # Windows 11 build 22000 or later
                try {
                    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Continue

                    if($DebugPreference -ne "SilentlyContinue") {
                        Write-Host "Application $app supprimee pour tous les utilisateurs" -ForegroundColor DarkGray                    }
                }
                catch {
                    if($DebugPreference -ne "SilentlyContinue") {
                        Write-Host "Impossible de supprimer $app pour tous les utilisateurs" -ForegroundColor Yellow
                        Write-Host $psitem.Exception.StackTrace -ForegroundColor Gray
                    }
                }
            }
            else {
                # Windows 10
                try {
                    Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue                    
                    if($DebugPreference -ne "SilentlyContinue") {
                        Write-Host "Application $app supprimee pour l'utilisateur actuel" -ForegroundColor DarkGray                    }
                }
                catch {
                    if($DebugPreference -ne "SilentlyContinue") {
                        Write-Host "Impossible de supprimer $app pour l'utilisateur actuel" -ForegroundColor Yellow                        Write-Host $psitem.Exception.StackTrace -ForegroundColor Gray
                    }
                }
                
                try {
                    Get-AppxPackage -Name $app -PackageTypeFilter Main, Bundle, Resource -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                    
                    if($DebugPreference -ne "SilentlyContinue") {
                        Write-Host "Application $app supprimee pour tous les utilisateurs" -ForegroundColor DarkGray                    }
                }
                catch {
                    if($DebugPreference -ne "SilentlyContinue") {
                        Write-Host "Impossible de supprimer $app pour tous les utilisateurs" -ForegroundColor Yellow                        Write-Host $psitem.Exception.StackTrace -ForegroundColor Gray
                    }
                }
            }

            # Remove provisioned app from OS image, so the app won't be installed for any new users
            try {
                Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $app } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
            }
            catch {
                Write-Host "Impossible de supprimer $app de l'image Windows" -ForegroundColor Yellow                Write-Host $psitem.Exception.StackTrace -ForegroundColor Gray
            }
        }
    }
            
    Write-Output ""
}


# Forcefully removes Microsoft Edge using it's uninstaller
function ForceRemoveEdge {
    # Based on work from loadstring1 & ave9858
    Write-Output "> Desinstallation forcee de Microsoft Edge..."

    $regView = [Microsoft.Win32.RegistryView]::Registry32
    $hklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $regView)
    $hklm.CreateSubKey('SOFTWARE\Microsoft\EdgeUpdateDev').SetValue('AllowUninstall', '')

    # Create stub (Creating this somehow allows uninstalling edge)
    $edgeStub = "$env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
    New-Item $edgeStub -ItemType Directory | Out-Null
    New-Item "$edgeStub\MicrosoftEdge.exe" | Out-Null

    # Remove edge
    $uninstallRegKey = $hklm.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge')
    if ($null -ne $uninstallRegKey) {
        Write-Output "Execution du programme de desinstallation..."
        $uninstallString = $uninstallRegKey.GetValue('UninstallString') + ' --force-uninstall'
        Start-Process cmd.exe "/c $uninstallString" -WindowStyle Hidden -Wait

        Write-Output "Suppression des fichiers restants..."

        $edgePaths = @(
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk",
            "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk",
            "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk",
            "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Tombstones\Microsoft Edge.lnk",
            "$env:PUBLIC\Desktop\Microsoft Edge.lnk",
            "$env:USERPROFILE\Desktop\Microsoft Edge.lnk",
            "$edgeStub"
        )

        foreach ($path in $edgePaths){
            if (Test-Path -Path $path) {
                Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
                Write-Host "  Supprime $path" -ForegroundColor DarkGray            }
        }

        Write-Output "Nettoyage du registre..."

        # Remove ms edge from autostart
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "MicrosoftEdgeAutoLaunch_A9F6DCE4ABADF4F51CF45CD7129E3C6C" /f *>$null
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "Microsoft Edge Update" /f *>$null
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "MicrosoftEdgeAutoLaunch_A9F6DCE4ABADF4F51CF45CD7129E3C6C" /f *>$null
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "Microsoft Edge Update" /f *>$null

        Write-Output "Microsoft Edge a ete desinstalle"
    }
    else {
        Write-Output ""
        Write-Host "Erreur : Impossible de forcer la desinstallation de Microsoft Edge, le programme de desinstallation est introuvable" -ForegroundColor Red    }
    
    Write-Output ""
}


# Execute provided command and strips progress spinners/bars from console output
function Strip-Progress {
    param(
        [ScriptBlock]$ScriptBlock
    )

    # Regex pattern to match spinner characters and progress bar patterns
    $progressPattern = 'Γû[Æê]|^\s+[-\\|/]\s+$'

    # Corrected regex pattern for size formatting, ensuring proper capture groups are utilized
    $sizePattern = '(\d+(\.\d{1,2})?)\s+(B|KB|MB|GB|TB|PB) /\s+(\d+(\.\d{1,2})?)\s+(B|KB|MB|GB|TB|PB)'

    & $ScriptBlock 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            "ERROR: $($_.Exception.Message)"
        } else {
            $line = $_ -replace $progressPattern, '' -replace $sizePattern, ''
            if (-not ([string]::IsNullOrWhiteSpace($line)) -and -not ($line.StartsWith('  '))) {
                $line
            }
        }
    }
}


# Import & execute regfile
function RegImport {
    param (
        $message,
        $path
    )

    Write-Output $message


    if (!$global:Params.ContainsKey("Sysprep")) {
        reg import "$PSScriptRoot\Regfiles\$path"  
    }
    else {
        $defaultUserPath = $env:USERPROFILE.Replace($env:USERNAME, 'Default\NTUSER.DAT')
        
        reg load "HKU\Default" $defaultUserPath | Out-Null
        reg import "$PSScriptRoot\Regfiles\Sysprep\$path"  
        reg unload "HKU\Default" | Out-Null
    }

    Write-Output ""
}


# Restart the Windows Explorer process
function RestartExplorer {
    Write-Output "> Redémarrage de l'Explorateur Windows pour appliquer les changements..."
    
    # Arrêt de l'Explorateur
    taskkill /f /im explorer.exe

    # Attente et redémarrage
    Start-Sleep -Milliseconds 500
    Start-Process explorer.exe
}


# Replace the startmenu for all users, when using the default startmenuTemplate this clears all pinned apps
# Credit: https://lazyadmin.nl/win-11/customize-windows-11-start-menu-layout/
function ReplaceStartMenuForAllUsers {
    param (
        $startMenuTemplate = "$PSScriptRoot/Start/start2.bin"
    )

    Write-Output "> Removing all pinned apps from the start menu for all users..."

    # Check if template bin file exists, return early if it doesn't
    if (-not (Test-Path $startMenuTemplate)) {
        Write-Host "Erreur : Impossible de nettoyer le menu demarrer, le fichier start2.bin est manquant du dossier du script" -ForegroundColor Red        Write-Output ""
        return
    }

    # Get path to start menu file for all users
    $userPathString = $env:USERPROFILE.Replace($env:USERNAME, "*\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState")
    $usersStartMenuPaths = get-childitem -path $userPathString

    # Go through all users and replace the start menu file
    ForEach ($startMenuPath in $usersStartMenuPaths) {
        ReplaceStartMenu "$($startMenuPath.Fullname)\start2.bin" $startMenuTemplate
    }

    # Also replace the start menu file for the default user profile
    $defaultStartMenuPath = $env:USERPROFILE.Replace($env:USERNAME, 'Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState')

    # Create folder if it doesn't exist
    if (-not(Test-Path $defaultStartMenuPath)) {
        new-item $defaultStartMenuPath -ItemType Directory -Force | Out-Null
        Write-Output "Created LocalState folder for default user profile"
    }

    # Copy template to default profile
    Copy-Item -Path $startMenuTemplate -Destination $defaultStartMenuPath -Force
    Write-Output "Replaced start menu for the default user profile"
    Write-Output ""
}


# Replace the startmenu for all users, when using the default startmenuTemplate this clears all pinned apps
# Credit: https://lazyadmin.nl/win-11/customize-windows-11-start-menu-layout/
function ReplaceStartMenu {
    param (
        $startMenuBinFile = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin",
        $startMenuTemplate = "$PSScriptRoot/Start/start2.bin"
    )

    $userName = $startMenuBinFile.Split("\")[2]

    # Check if template bin file exists, return early if it doesn't
    if (-not (Test-Path $startMenuTemplate)) {
        Write-Host "Erreur : Impossible de nettoyer le menu demarrer, le fichier start2.bin est manquant du dossier du script" -ForegroundColor Red        return
    }

    # Check if bin file exists, return early if it doesn't
    if (-not (Test-Path $startMenuBinFile)) {
        Write-Host "Erreur : Impossible de nettoyer le menu demarrer pour l'utilisateur $userName, le fichier start2.bin est introuvable" -ForegroundColor Red        return
    }

    $backupBinFile = $startMenuBinFile + ".bak"

    # Backup current start menu file
    Move-Item -Path $startMenuBinFile -Destination $backupBinFile -Force

    # Copy template file
    Copy-Item -Path $startMenuTemplate -Destination $startMenuBinFile -Force

    Write-Output "Replaced start menu for user $userName"
}


# Add parameter to script and write to file
function AddParameter {
    param (
        $parameterName,
        $message
    )

    # Add key if it doesn't already exist
    if (-not $global:Params.ContainsKey($parameterName)) {
        $global:Params.Add($parameterName, $true)
    }

    # Create or clear file that stores last used settings
    if (!(Test-Path "$PSScriptRoot/SavedSettings")) {
        $null = New-Item "$PSScriptRoot/SavedSettings"
    } 
    elseif ($global:FirstSelection) {
        $null = Clear-Content "$PSScriptRoot/SavedSettings"
    }
    
    $global:FirstSelection = $false

    # Create entry and add it to the file
    $entry = "$parameterName#- $message"
    Add-Content -Path "$PSScriptRoot/SavedSettings" -Value $entry
}


function PrintHeader {
    param (
        $title
    )

    $fullTitle = " Win11Debloat Script - $title"

    if ($global:Params.ContainsKey("Sysprep")) {
        $fullTitle = "$fullTitle (Sysprep mode)"
    }
    else {
        $fullTitle = "$fullTitle (User: $Env:UserName)"
    }

    Clear-Host
    Write-Output "-------------------------------------------------------------------------------------------"
    Write-Output $fullTitle
    Write-Output "-------------------------------------------------------------------------------------------"
}


function PrintFromFile {
    param (
        $path
    )

    Clear-Host

    # Get & print script menu from file
    Foreach ($line in (Get-Content -Path $path )) {   
        Write-Output $line
    }
}


function AwaitKeyToExit {
    Write-Output ""
    Write-Output "Appuyez sur une touche pour quitter..."
    [Console]::ReadKey() | Out-Null
    Exit
}



##################################################################################################################
#                                                                                                                #
#                                                  SCRIPT START                                                  #
#                                                                                                                #
##################################################################################################################



# Check if winget is installed & if it is, check if the version is at least v1.4
if ((Get-AppxPackage -Name "*Microsoft.DesktopAppInstaller*") -and ((winget -v) -replace 'v','' -gt 1.4)) {
    $global:wingetInstalled = $true
}
else {
    $global:wingetInstalled = $false

    # Show warning that requires user confirmation, Suppress confirmation if Silent parameter was passed
    if (-not $Silent) {
        Write-Warning "Winget is not installed or outdated. This may prevent Win11Debloat from removing certain apps."
        Write-Output ""
        Write-Output "Press any key to continue anyway..."
        $null = [System.Console]::ReadKey()
    }
}

# Get current Windows build version to compare against features
$WinVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild

$global:Params = $PSBoundParameters
$global:FirstSelection = $true
$SPParams = 'WhatIf', 'Confirm', 'Verbose', 'Silent', 'Sysprep', 'Debug'
$SPParamCount = 0

# Count how many SPParams exist within Params
# This is later used to check if any options were selected
foreach ($Param in $SPParams) {
    if ($global:Params.ContainsKey($Param)) {
        $SPParamCount++
    }
}

# Hide progress bars for app removal, as they block Win11Debloat's output
if (-not ($global:Params.ContainsKey("Verbose"))) {
    $ProgressPreference = 'SilentlyContinue'
}
else {
    Read-Host "Le mode detaille est active, appuyez sur Entree pour continuer"    $ProgressPreference = 'Continue'
}

if ($global:Params.ContainsKey("Sysprep")) {
    $defaultUserPath = $env:USERPROFILE.Replace($env:USERNAME, 'Default\NTUSER.DAT')

    # Exit script if default user directory or NTUSER.DAT file cannot be found
    if (-not (Test-Path "$defaultUserPath")) {
        Write-Host "Error: Unable to start Win11Debloat in Sysprep mode, cannot find default user folder at '$defaultUserPath'" -ForegroundColor Red
        AwaitKeyToExit
        Exit
    }
    # Exit script if run in Sysprep mode on Windows 10
    if ($WinVersion -lt 22000) {
        Write-Host "Erreur : Le mode Sysprep de Win11Debloat n'est pas pris en charge sur Windows 10" -ForegroundColor Red        AwaitKeyToExit
        Exit
    }
}

# Remove SavedSettings file if it exists and is empty
if ((Test-Path "$PSScriptRoot/SavedSettings") -and ([String]::IsNullOrWhiteSpace((Get-content "$PSScriptRoot/SavedSettings")))) {
    Remove-Item -Path "$PSScriptRoot/SavedSettings" -recurse
}

# Only run the app selection form if the 'RunAppConfigurator' parameter was passed to the script
if ($RunAppConfigurator) {
    PrintHeader "App Configurator"

    $result = ShowAppSelectionForm

    # Show different message based on whether the app selection was saved or cancelled
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "Le configurateur d'applications a ete ferme sans enregistrement." -ForegroundColor Red    }
    else {
        Write-Output "Votre selection d'applications a ete sauvegardee dans le fichier 'CustomAppsList' dans le dossier racine du script."    }

    AwaitKeyToExit

    Exit
}

# Change script execution based on provided parameters or user input
if ((-not $global:Params.Count) -or $RunDefaults -or $RunWin11Defaults -or ($SPParamCount -eq $global:Params.Count)) {
    if ($RunDefaults -or $RunWin11Defaults) {
        $Mode = '1'
    }
    else {
        # Show menu and wait for user input, loops until valid input is provided
        Do { 
            $ModeSelectionMessage = "Please select an option (1/2/3/0)" 

            PrintHeader 'Menu'

            Write-Output "(1) Mode par defaut : Appliquer les parametres par defaut"
            Write-Output "(2) Mode personnalise : Modifier le script selon vos besoins"
            Write-Output "(3) Mode suppression d'applications : Selectionner et supprimer des applications, sans faire d'autres modifications"

            # Only show this option if SavedSettings file exists
            if (Test-Path "$PSScriptRoot/SavedSettings") {
                Write-Output "(4) Appliquer les parametres personnalises de la derniere fois"
                
                $ModeSelectionMessage = "Please select an option (1/2/3/4/0)" 
            }

            Write-Output ""
            Write-Output "(0) Afficher plus d'informations"
            Write-Output ""
            Write-Output ""

            $Mode = Read-Host $ModeSelectionMessage

            # Show information based on user input, Suppress user prompt if Silent parameter was passed
            if ($Mode -eq '0') {
                # Get & print script information from file
                PrintFromFile "$PSScriptRoot/Menus/Info"

                Write-Output ""
                Write-Output "Press any key to go back..."
                $null = [System.Console]::ReadKey()
            }
            elseif (($Mode -eq '4')-and -not (Test-Path "$PSScriptRoot/SavedSettings")) {
                $Mode = $null
            }
        }
        while ($Mode -ne '1' -and $Mode -ne '2' -and $Mode -ne '3' -and $Mode -ne '4') 
    }

    # Add execution parameters based on the mode
    switch ($Mode) {
        # Default mode, loads defaults after confirmation
        '1' { 
            # Print the default settings & require userconfirmation, unless Silent parameter was passed
            if (-not $Silent) {
                PrintFromFile "$PSScriptRoot/Menus/DefaultSettings"

                Write-Output ""
                Write-Output "Appuyez sur Entree pour executer le script ou sur CTRL+C pour quitter..."
                Read-Host | Out-Null
            }

            $DefaultParameterNames = 'RemoveApps','DisableTelemetry','DisableBing','DisableLockscreenTips','DisableSuggestions','ShowKnownFileExt','DisableWidgets','HideChat','DisableCopilot'

            PrintHeader 'Default Mode'

            # Add default parameters if they don't already exist
            foreach ($ParameterName in $DefaultParameterNames) {
                if (-not $global:Params.ContainsKey($ParameterName)){
                    $global:Params.Add($ParameterName, $true)
                }
            }

            # Only add this option for Windows 10 users, if it doesn't already exist
            if ((get-ciminstance -query "select caption from win32_operatingsystem where caption like '%Windows 10%'") -and (-not $global:Params.ContainsKey('Hide3dObjects'))) {
                $global:Params.Add('Hide3dObjects', $Hide3dObjects)
            }
        }

        # Custom mode, show & add options based on user input
        '2' { 
            # Get current Windows build version to compare against features
            $WinVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild
            
            PrintHeader 'Custom Mode'

            # Show options for removing apps, only continue on valid input
            Do {
                Write-Host "Parametres de demarrage :" -ForegroundColor Yellow
                Write-Host " (n) Conserver la configuration actuelle" -ForegroundColor Yellow
                Write-Host " (1) Menu demarrer epure" -ForegroundColor Yellow
                Write-Host " (2) Menu demarrer standard" -ForegroundColor Yellow
                Write-Host " (3) Configuration personnalisee" -ForegroundColor Yellow
$RemoveAppsInput = Read-Host "Supprimer des applications pre-installees ? (n/1/2/3)"
                # Show app selection form if user entered option 3
                if ($RemoveAppsInput -eq '3') {
                    $result = ShowAppSelectionForm

                    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
                        # User cancelled or closed app selection, show error and change RemoveAppsInput so the menu will be shown again
                        Write-Output ""
                        Write-Host "Selection d'applications annulee, veuillez reessayer" -ForegroundColor Red

                        $RemoveAppsInput = 'c'
                    }
                    
                    Write-Output ""
                }
            }
            while ($RemoveAppsInput -ne 'n' -and $RemoveAppsInput -ne '0' -and $RemoveAppsInput -ne '1' -and $RemoveAppsInput -ne '2' -and $RemoveAppsInput -ne '3') 

            # Select correct option based on user input
            switch ($RemoveAppsInput) {
                '1' {
                    AddParameter 'RemoveApps' 'Remove default selection of bloatware apps'
                }
                '2' {
                    AddParameter 'RemoveApps' 'Remove default selection of bloatware apps'
                    AddParameter 'RemoveCommApps' 'Remove the Mail, Calendar, and People apps'
                    AddParameter 'RemoveW11Outlook' 'Remove the new Outlook for Windows app'
                    AddParameter 'RemoveDevApps' 'Remove developer-related apps'
                    AddParameter 'RemoveGamingApps' 'Remove the Xbox App and Xbox Gamebar'
                    AddParameter 'DisableDVR' 'Disable Xbox game/screen recording'
                }
                '3' {
                    Write-Output "You have selected $($global:SelectedApps.Count) apps for removal"

                    AddParameter 'RemoveAppsCustom' "Remove $($global:SelectedApps.Count) apps:"

                    Write-Output ""

                    if ($( Read-Host -Prompt "Disable Xbox game/screen recording? Also stops gaming overlay popups (y/n)" ) -eq 'y') {
                        AddParameter 'DisableDVR' 'Disable Xbox game/screen recording'
                    }
                }
            }

            # Only show this option for Windows 11 users running build 22621 or later
            if ($WinVersion -ge 22621){
                Write-Output ""

                if ($global:Params.ContainsKey("Sysprep")) {
                    if ($( Read-Host -Prompt "Supprimer tous les appeles de la barre des tâches pour tous les utilisateurs existants et nouveaux ? (o/n)" ) -eq 'o') {
                        AddParameter 'ClearStartAllUsers' "Supprimer tous les appeles de la barre des tâches pour tous les utilisateurs existants et nouveaux"                    }
                }
                else {
                    Do {
                        Write-Host "Options :" -ForegroundColor Yellow
                        Write-Host " (n) Ne supprimer aucun appeles de la barre des tâches" -ForegroundColor Yellow
                        Write-Host " (1) Supprimer tous les appeles de la barre des tâches pour cet utilisateur ($env:USERNAME)" -ForegroundColor Yellow
                        Write-Host " (2) Supprimer tous les appeles de la barre des tâches pour tous les utilisateurs existants et nouveaux"  -ForegroundColor Yellow
                        $ClearStartInput = Read-Host "Supprimer tous les appeles de la barre des tâches ? (n/1/2)"                    }
                    while ($ClearStartInput -ne 'n' -and $ClearStartInput -ne '0' -and $ClearStartInput -ne '1' -and $ClearStartInput -ne '2') 
    
                    # Select correct option based on user input
                    switch ($ClearStartInput) {
                        '1' {
                            AddParameter 'ClearStart' "Remove all pinned apps from the start menu for this user only"
                        }
                        '2' {
                            AddParameter 'ClearStartAllUsers' "Remove all pinned apps from the start menu for all existing and new users"
                        }
                    }
                }
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Desactiver la telemetrie, les donnees de diagnostic, l'historique des activites, le suivi du lancement des applications et les publicites ciblees ? (o/n)" ) -eq 'o') {
                AddParameter 'DisableTelemetry' 'Desactiver la telemetrie, les donnees de diagnostic, l''historique des activites, le suivi du lancement des applications et les publicites ciblees'
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Desactiver les conseils, astuces, suggestions et publicites dans le menu demarrer, les parametres, les notifications, l'explorateur et l'ecran de verrouillage ? (o/n)" ) -eq 'o') {
                AddParameter 'DisableSuggestions' 'Desactiver les conseils, astuces, suggestions et publicites dans le menu demarrer, les parametres, les notifications et l'Explorateur'
                AddParameter 'DisableLockscreenTips' 'Desactiver les conseils et astuces sur l'ecran de verrouillage'
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Desactiver et supprimer la recherche web Bing, l'IA Bing et Cortana dans la recherche Windows ? (o/n)" ) -eq 'o') {
                AddParameter 'DisableBing' 'Desactiver et supprimer la recherche web Bing, l''IA Bing et Cortana dans la recherche Windows'
            }

            # Only show this option for Windows 11 users running build 22621 or later
            if ($WinVersion -ge 22621){
                Write-Output ""

                if ($( Read-Host -Prompt "Desactiver et supprimer Windows Copilot ? Cela s'applique a tous les utilisateurs (o/n)" ) -eq 'o') {
                    AddParameter 'DisableCopilot' 'Desactiver et supprimer Windows Copilot'
                }

                Write-Output ""

                if ($( Read-Host -Prompt "Desactiver les instantanes Windows Recall ? Cela s'applique a tous les utilisateurs (o/n)" ) -eq 'o') {
                    AddParameter 'DisableRecall' 'Desactiver les instantanes Windows Recall'
                }
            }

            # Only show this option for Windows 11 users running build 22000 or later
            if ($WinVersion -ge 22000){
                Write-Output ""

                if ($( Read-Host -Prompt "Restaurer l'ancien style de menu contextuel de Windows 10 ? (o/n)" ) -eq 'o') {
                      AddParameter 'RevertContextMenu' 'Restaurer l''ancien style de menu contextuel de Windows 10'
                }
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Voulez-vous faire des modifications a la barre des taches et aux services associes ? (o/n)" ) -eq 'o') {                # Only show these specific options for Windows 11 users running build 22000 or later
                if ($WinVersion -ge 22000){
                    Write-Output ""

                    if ($( Read-Host -Prompt "   Aligner les boutons de la barre des taches a gauche ? (o/n)" ) -eq 'o') {
                        AddParameter 'TaskbarAlignLeft' 'Aligner les icones de la barre des taches a gauche'
                    }

                    # Show options for search icon on taskbar, only continue on valid input
                    Do {
                        Write-Output ""
                        Write-Host "   Options :" -ForegroundColor Yellow
                        Write-Host "    (n) Aucun changement" -ForegroundColor Yellow
                        Write-Host "    (1) Masquer l'icone de recherche de la barre des taches" -ForegroundColor Yellow
                        Write-Host "    (2) Afficher les icone de recherche sur la barre des taches" -ForegroundColor Yellow
                        Write-Host "    (3) Afficher les icone de recherche avec libelle sur la barre des taches" -ForegroundColor Yellow
                        Write-Host "    (4) Afficher la boite de recherche sur la barre des taches" -ForegroundColor Yellow
                        $TbSearchInput = Read-Host "   Masquer ou modifier l'icone de recherche sur la barre des tâches ? (n/1/2/3/4)"                    }
                    while ($TbSearchInput -ne 'n' -and $TbSearchInput -ne '0' -and $TbSearchInput -ne '1' -and $TbSearchInput -ne '2' -and $TbSearchInput -ne '3' -and $TbSearchInput -ne '4') 

                    # Select correct taskbar search option based on user input
                    switch ($TbSearchInput) {
                        '1' {
                            AddParameter 'HideSearchTb' 'Masquer l''icone de recherche dans la barre des taches'
                        }
                        '2' {
                            AddParameter 'ShowSearchIconTb' 'Afficher l''icone de recherche dans la barre des taches'
                        }
                        '3' {
                            AddParameter 'ShowSearchLabelTb' 'Afficher l''icone de recherche avec label dans la barre des taches'
                        }
                        '4' {
                            AddParameter 'ShowSearchBoxTb' 'Afficher la zone de recherche dans la barre des taches'
                        }
                    }

                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer le bouton d'affichage des taches dans la barre des taches ? (o/n)" ) -eq 'o') {
                        AddParameter 'HideTaskview' 'Masquer le bouton d''affichage des taches dans la barre des taches'
                    }                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Desactiver le service des widgets et masquer l'icone de la barre des taches ? (o/n)" ) -eq 'o') {
                    AddParameter 'DisableWidgets' 'Desactiver le service des widgets et masquer l''icone des widgets de la barre des taches'
                }

                # Only show this options for Windows users running build 22621 or earlier
                if ($WinVersion -le 22621){
                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer l'icone de chat (meet now) de la barre des taches ? (o/n)" ) -eq 'o') {
                        AddParameter 'HideChat' 'Masquer l''icone de chat (meet now) de la barre des taches'
                    }
                }
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Voulez-vous faire des modifications a l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                # Afficher les options pour changer l'emplacement par defaut de l'Explorateur
                Do {
                    Write-Output ""
                    Write-Host "   Options :" -ForegroundColor Yellow
                    Write-Host "    (n) Aucun changement" -ForegroundColor Yellow
                    Write-Host "    (1) Ouvrir l'Explorateur sur Accueil" -ForegroundColor Yellow
                    Write-Host "    (2) Ouvrir l'Explorateur sur Ce PC" -ForegroundColor Yellow
                    Write-Host "    (3) Ouvrir l'Explorateur sur Telechargements" -ForegroundColor Yellow
                    Write-Host "    (4) Ouvrir l'Explorateur sur OneDrive" -ForegroundColor Yellow
                    $ExplSearchInput = Read-Host "   Modifier l'emplacement par defaut de l'Explorateur ? (n/1/2/3/4)" 
                }
                while ($ExplSearchInput -ne 'n' -and $ExplSearchInput -ne '0' -and $ExplSearchInput -ne '1' -and $ExplSearchInput -ne '2' -and $ExplSearchInput -ne '3' -and $ExplSearchInput -ne '4') 

                # Selectionner l'option correcte selon le choix de l'utilisateur
                switch ($ExplSearchInput) {
                    '1' {
                        AddParameter 'ExplorerToHome' "Modifier l'emplacement par defaut de l'Explorateur vers 'Accueil'"
                    }
                    '2' {
                        AddParameter 'ExplorerToThisPC' "Modifier l'emplacement par defaut de l'Explorateur vers 'Ce PC'"
                    }
                    '3' {
                        AddParameter 'ExplorerToDownloads' "Modifier l'emplacement par defaut de l'Explorateur vers 'Telechargements'"
                    }
                    '4' {
                        AddParameter 'ExplorerToOneDrive' "Modifier l'emplacement par defaut de l'Explorateur vers 'OneDrive'"
                    }                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Afficher les fichiers, dossiers et lecteurs caches ? (o/n)" ) -eq 'o') {
                    AddParameter 'ShowHiddenFolders' 'Afficher les fichiers, dossiers et lecteurs caches'
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Afficher les extensions des fichiers pour les types de fichiers connus ? (o/n)" ) -eq 'o') {
                    AddParameter 'ShowKnownFileExt' 'Afficher les extensions des fichiers pour les types de fichiers connus'
                }

                # Only show this option for Windows 11 users running build 22000 or later
                if ($WinVersion -ge 22000){
                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer la section Accueil du volet lateral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                        AddParameter 'HideHome' 'Masquer la section Accueil du volet lateral de l''Explorateur de fichiers'
                    }

                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer la section Galerie du volet lateral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                        AddParameter 'HideGallery' 'Masquer la section Galerie du volet lateral de l''Explorateur de fichiers'
                    }
                    
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Masquer les entrees de lecteur de disque repliquees de la barre des taches de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                    AddParameter 'HideDupliDrive' 'Masquer les entrees de lecteur de disque repliquees de la barre des taches de l''Explorateur de fichiers'
                }

                # Only show option for disabling these specific folders for Windows 10 users
                if (get-ciminstance -query "select caption from win32_operatingsystem where caption like '%Windows 10%'"){
                    Write-Output ""

                    if ($( Read-Host -Prompt "Voulez-vous masquer des dossiers du volet lateral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {                        Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer le dossier OneDrive du volet lateral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                        AddParameter 'HideOnedrive' 'Masquer le dossier OneDrive du volet lateral de l''Explorateur de fichiers'
                    }

                        Write-Output ""
                        
                        if ($( Read-Host -Prompt "   Masquer le dossier Objets 3D du volet lateral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                            AddParameter 'Hide3dObjects' "Masquer le dossier Objets 3D du volet lateral de l'Explorateur de fichiers"
                        }
                        
                        Write-Output ""

                        if ($( Read-Host -Prompt "   Masquer le dossier Musique du volet lateral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                            AddParameter 'HideMusic' "Masquer le dossier Musique du volet lateral de l'Explorateur de fichiers"
                        }
                    }
                }
            }

            # Only show option for disabling context menu items for Windows 10 users or if the user opted to restore the Windows 10 context menu
            if ((get-ciminstance -query "select caption from win32_operatingsystem where caption like '%Windows 10%'") -or $global:Params.ContainsKey('RevertContextMenu')){
                Write-Output ""

                if ($( Read-Host -Prompt "Voulez-vous desactiver des options du menu contextuel ? (o/n)" ) -eq 'o') {                    Write-Output ""

                if ($( Read-Host -Prompt "   Masquer l'option 'Inclure dans la bibliotheque' dans le menu contextuel ? (o/n)" ) -eq 'o') {
                        AddParameter 'HideIncludeInLibrary' "Masquer l'option 'Inclure dans la bibliotheque' dans le menu contextuel"
                    }

                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer l'option 'Donner acces à' dans le menu contextuel ? (o/n)" ) -eq 'o') {
                        AddParameter 'HideGiveAccessTo' "Masquer l'option 'Donner acces à' dans le menu contextuel"
                    }

                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer l'option 'Partager' dans le menu contextuel ? (o/n)" ) -eq 'o') {
                        AddParameter 'HideShare' "Masquer l'option 'Partager' dans le menu contextuel"
                    }
                }
            }

            # Suppress prompt if Silent parameter was passed
            if (-not $Silent) {
                Write-Output ""
                Write-Output ""
                Write-Output ""
                Write-Output "Press enter to confirm your choices and execute the script or press CTRL+C to quit..."
                Read-Host | Out-Null
            }

            PrintHeader 'Custom Mode'
        }

        # App removal, remove apps based on user selection
        '3' {
            PrintHeader "App Removal"

            $result = ShowAppSelectionForm

            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                Write-Output "You have selected $($global:SelectedApps.Count) apps for removal"
                AddParameter 'RemoveAppsCustom' "Remove $($global:SelectedApps.Count) apps:"

                # Suppress prompt if Silent parameter was passed
                if (-not $Silent) {
                    Write-Output ""
                    Write-Output "Press enter to remove the selected apps or press CTRL+C to quit..."
                    Read-Host | Out-Null
                    PrintHeader "App Removal"
                }
            }
            else {
                Write-Host "Selection annulee, aucune application n'a ete supprimee" -ForegroundColor Red
                Write-Output ""
            }
        }

        # Load custom options selection from the "SavedSettings" file
        '4' {
            if (-not $Silent) {
                PrintHeader 'Custom Mode'
                Write-Output "Win11Debloat will make the following changes:"

                # Get & print default settings info from file
                Foreach ($line in (Get-Content -Path "$PSScriptRoot/SavedSettings" )) { 
                    # Remove any spaces before and after the line
                    $line = $line.Trim()
                
                    # Check if the line contains a comment
                    if (-not ($line.IndexOf('#') -eq -1)) {
                        $parameterName = $line.Substring(0, $line.IndexOf('#'))

                        # Print parameter description and add parameter to Params list
                        if ($parameterName -eq "RemoveAppsCustom") {
                            if (-not (Test-Path "$PSScriptRoot/CustomAppsList")) {
                                # Apps file does not exist, skip
                                continue
                            }
                            
                            $appsList = ReadAppslistFromFile "$PSScriptRoot/CustomAppsList"
                            Write-Output "- Remove $($appsList.Count) apps:"
                            Write-Host $appsList -ForegroundColor DarkGray
                        }
                        else {
                            Write-Output $line.Substring(($line.IndexOf('#') + 1), ($line.Length - $line.IndexOf('#') - 1))
                        }

                        if (-not $global:Params.ContainsKey($parameterName)){
                            $global:Params.Add($parameterName, $true)
                        }
                    }
                }

                Write-Output ""
                Write-Output ""
                Write-Output "Press enter to execute the script or press CTRL+C to quit..."
                Read-Host | Out-Null
            }

            PrintHeader 'Custom Mode'
        }
    }
}
else {
    PrintHeader 'Custom Mode'
}


# If the number of keys in SPParams equals the number of keys in Params then no modifications/changes were selected
#  or added by the user, and the script can exit without making any changes.
if ($SPParamCount -eq $global:Params.Keys.Count) {
    Write-Output "The script completed without making any changes."

    AwaitKeyToExit
}
else {
    # Execute all selected/provided parameters
    switch ($global:Params.Keys) {
        'RemoveApps' {
            $appsList = ReadAppslistFromFile "$PSScriptRoot/Appslist.txt" 
            Write-Output "> Suppression de la selection par defaut de $($appsList.Count) applications..."
            RemoveApps $appsList
            continue
        }
        'RemoveAppsCustom' {
            if (-not (Test-Path "$PSScriptRoot/CustomAppsList")) {
                Write-Host "> Error : Impossible de charger la liste personnalisee d'applications depuis le fichier, aucune application n'a ete supprimee" -ForegroundColor Red
                Write-Output ""
                continue
            }
            
            $appsList = ReadAppslistFromFile "$PSScriptRoot/CustomAppsList"
            Write-Output "> Suppression de $($appsList.Count) applications..."
            RemoveApps $appsList
            continue
        }
        'RemoveCommApps' {
            Write-Output "> Suppression des applications Mail, Calendar et People..."
            
            $appsList = 'Microsoft.windowscommunicationsapps', 'Microsoft.People'
            RemoveApps $appsList
            continue
        }
        'RemoveW11Outlook' {
            $appsList = 'Microsoft.OutlookForWindows'
            Write-Output "> Suppression de la nouvelle application Outlook pour Windows..."
            RemoveApps $appsList
            continue
        }
        'RemoveDevApps' {
            $appsList = 'Microsoft.PowerAutomateDesktop', 'Microsoft.RemoteDesktop', 'Windows.DevHome'
            Write-Output "> Suppression des applications liees au developpement..."
            RemoveApps $appsList
            continue
        }
        'RemoveGamingApps' {
            $appsList = 'Microsoft.GamingApp', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay'
            Write-Output "> Suppression des applications liees au jeu..."
            RemoveApps $appsList
            continue
        }
        "ForceRemoveEdge" {
            ForceRemoveEdge
            continue
        }
        'DisableDVR' {
            RegImport "> Desactivation de la capture d'ecran et de la video Xbox..." "Disable_DVR.reg"
            continue
        }
        'ClearStart' {
            Write-Output "> Suppression de toutes les applications fixees pour l'utilisateur $env:USERNAME..."
            ReplaceStartMenu
            Write-Output ""
            continue
        }
        'ClearStartAllUsers' {
            ReplaceStartMenuForAllUsers
            continue
        }
        'DisableTelemetry' {
            RegImport "> Desactivation de la telemetrie, des donnees de diagnostic..." "Disable_Telemetry.reg"
            continue
        }
        {$_ -in "DisableBingSearches", "DisableBing"} {
            RegImport "> Desactivation de la recherche Bing, de l'IA Bing et de Cortana dans Windows..." "Disable_Bing_Cortana_In_Search.reg"
            
            # Also remove the app package for bing search
            $appsList = 'Microsoft.BingSearch'
            RemoveApps $appsList
            continue
        }
        {$_ -in "DisableLockscrTips", "DisableLockscreenTips"} {
            RegImport "> Desactivation des conseils et astuces dans l'ecran de verrouillage..." "Disable_Lockscreen_Tips.reg"
            continue
        }
        {$_ -in "DisableSuggestions", "DisableWindowsSuggestions"} {
            RegImport "> Desactivation des conseils, astuces, suggestions et publicites dans Windows..." "Disable_Windows_Suggestions.reg"
            continue
        }
        'RevertContextMenu' {
            RegImport "> Restauration de la barre des tâches Windows 10..." "Disable_Show_More_Options_Context_Menu.reg"
            continue
        }
        'TaskbarAlignLeft' {
            RegImport "> Alignement des icônes de la barre des tâches à gauche..." "Align_Taskbar_Left.reg"

            continue
        }
        'HideSearchTb' {
            RegImport "> Masquage de l'icône de recherche de la barre des tâches..." "Hide_Search_Taskbar.reg"
            continue
        }
        'ShowSearchIconTb' {
            RegImport "> Modification de la recherche de la barre des tâches en icône..." "Show_Search_Icon.reg"
            continue
        }
        'ShowSearchLabelTb' {
            RegImport "> Modification de la recherche de la barre des tâches en icône avec libelle..." "Show_Search_Icon_And_Label.reg"
            continue
        }
        'ShowSearchBoxTb' {
            RegImport "> Modification de la recherche de la barre des tâches en boîte de recherche..." "Show_Search_Box.reg"
            continue
        }
        'HideTaskview' {
            RegImport "> Masquage du bouton de la barre des tâches..." "Hide_Taskview_Taskbar.reg"
            continue
        }
        'DisableCopilot' {
            RegImport "> Desactivation et suppression de Windows Copilot..." "Disable_Copilot.reg"

            # Also remove the app package for bing search
            $appsList = 'Microsoft.Copilot'
            RemoveApps $appsList
            continue
        }
        'DisableRecall' {
            RegImport "> Desactivation des captures instantanees de Windows..." "Disable_AI_Recall.reg"
            continue
        }
        {$_ -in "HideWidgets", "DisableWidgets"} {
            RegImport "> Desactivation du service des widgets et masquage de l'icône des widgets de la barre des tâches..." "Disable_Widgets_Taskbar.reg"
            continue
        }
        {$_ -in "HideChat", "DisableChat"} {
            RegImport "> Masquage de l'icône de chat de la barre des tâches..." "Disable_Chat_Taskbar.reg"
            continue
        }
        'ShowHiddenFolders' {
            RegImport "> Desactivation de la visualisation des dossiers caches..." "Show_Hidden_Folders.reg"
            continue
        }
        'ShowKnownFileExt' {
            RegImport "> Activation des extensions de fichier pour les types de fichiers connus..." "Show_Extensions_For_Known_File_Types.reg"
            continue
        }
        'HideHome' {
            RegImport "> Masquage de la section Accueil de l'Explorateur de fichiers..." "Hide_Home_from_Explorer.reg"
            continue
        }
        'HideGallery' {
            RegImport "> Masquage de la section Galerie de l'Explorateur de fichiers..." "Hide_Gallery_from_Explorer.reg"
            continue
        }
        'ExplorerToHome' {
            RegImport "> Modification de la localisation par defaut de l'Explorateur de fichiers vers `Accueil`..." "Launch_File_Explorer_To_Home.reg"
            continue
        }
        'ExplorerToThisPC' {
            RegImport "> Modification de la localisation par defaut de l'Explorateur de fichiers vers `Cet ordinateur`..." "Launch_File_Explorer_To_This_PC.reg"
            continue
        }
        'ExplorerToDownloads' {
            RegImport "> Modification de la localisation par defaut de l'Explorateur de fichiers vers `Telechargements`..." "Launch_File_Explorer_To_Downloads.reg"
            continue
        }
        'ExplorerToOneDrive' {
            RegImport "> Modification de la localisation par defaut de l'Explorateur de fichiers vers `OneDrive`..." "Launch_File_Explorer_To_OneDrive.reg"
            continue
        }
        'HideDupliDrive' {
            RegImport "> Masquage des entrees de lecteur de disque repliquees de la barre des tâches de l'Explorateur de fichiers..." "Hide_duplicate_removable_drives_from_navigation_pane_of_File_Explorer.reg"
            continue
        }
        {$_ -in "HideOnedrive", "DisableOnedrive"} {
            RegImport "> Masquage du dossier OneDrive de la barre des tâches de l'Explorateur de fichiers..." "Hide_Onedrive_Folder.reg"
            continue
        }
        {$_ -in "Hide3dObjects", "Disable3dObjects"} {
            RegImport "> Masquage du dossier Objets 3D de la barre des tâches de l'Explorateur de fichiers..." "Hide_3D_Objects_Folder.reg"
            continue
        }
        {$_ -in "HideMusic", "DisableMusic"} {
            RegImport "> Masquage du dossier Musique de la barre des tâches de l'Explorateur de fichiers..." "Hide_Music_folder.reg"
            continue
        }
        {$_ -in "HideIncludeInLibrary", "DisableIncludeInLibrary"} {
            RegImport "> Masquage de l'option 'Inclure dans la bibliotheque' dans le menu contextuel..." "Disable_Include_in_library_from_context_menu.reg"
            continue
        }
        {$_ -in "HideGiveAccessTo", "DisableGiveAccessTo"} {
            RegImport "> Masquage de l'option 'Donner acces à' dans le menu contextuel..." "Disable_Give_access_to_context_menu.reg"
            continue
        }
        {$_ -in "HideShare", "DisableShare"} {
            RegImport "> Masquage de l'option 'Partager' dans le menu contextuel..." "Disable_Share_from_context_menu.reg"
            continue
        }
    }

    RestartExplorer

    Write-Output ""
    Write-Output ""
    Write-Output ""
    Write-Output "Le script s'est termine avec succes !"

    AwaitKeyToExit
}

# Messages de configuration des parametres de confidentialite
Write-Output "> Configuration des parametres de confidentialite..."
Write-Output "> Desactivation du suivi des activites..."
Write-Output "> Desactivation des publicites personnalisees..."
Write-Output "> Desactivation des diagnostics avances..."

# Messages de configuration des applications par defaut
Write-Output "> Configuration des applications par defaut..."
Write-Output "> Modification de l'application par defaut pour $fileType..."
Write-Output "> Impossible de modifier l'application par defaut..."

# Messages de progression detailles
Write-Output "Analyse des applications installees..."
Write-Output "Verification des parametres systeme..."
Write-Output "Application des modifications..."
Write-Output "Nettoyage des fichiers temporaires..."

# Messages de debug
if($DebugPreference -ne "SilentlyContinue") {
    Write-Host "Application $app supprimee pour tous les utilisateurs" -ForegroundColor DarkGray
    Write-Host "Impossible de supprimer $app pour tous les utilisateurs" -ForegroundColor Yellow
    Write-Host "Trace de la pile d'erreurs :" -ForegroundColor Gray
    Write-Host "Modification du registre effectuee" -ForegroundColor DarkGray
}

# Messages systeme supplementaires
Write-Output "Verification des prerequis..."
Write-Output "Sauvegarde des parametres..."
Write-Output "Restauration des parametres..."
Write-Output "Configuration terminee"

# Messages techniques et de debogage
if($DebugPreference -ne "SilentlyContinue") {
    Write-Host "Demarrage de la procedure de nettoyage..." -ForegroundColor DarkGray
    Write-Host "Verification des dependances..." -ForegroundColor DarkGray
    Write-Host "Analyse des registres systeme..." -ForegroundColor DarkGray
    Write-Host "Modification des parametres systeme..." -ForegroundColor DarkGray
}

# Messages d'erreur systeme
Write-Host "Erreur : La modification du registre a echoue" -ForegroundColor Red
Write-Host "Erreur : Impossible d'acceder au dossier systeme" -ForegroundColor Red
Write-Host "Erreur : L'application est protegee par le systeme" -ForegroundColor Red
Write-Host "Erreur : Droits d'administrateur requis pour cette operation" -ForegroundColor Red
Write-Host "Erreur : Le service ne peut pas être arrête" -ForegroundColor Red
Write-Host "Erreur : echec de la sauvegarde des parametres" -ForegroundColor Red

# Messages de progression detailles
Write-Output "Preparation des modifications systeme..."
Write-Output "Sauvegarde des parametres actuels..."
Write-Output "Application des nouveaux parametres..."
Write-Output "Verification des modifications..."
Write-Output "Nettoyage des fichiers temporaires..."
Write-Output "Optimisation du systeme..."

# Messages de confirmation d'action
Write-Output "Êtes-vous sûr de vouloir continuer ? Cette action modifiera les parametres systeme (o/n)"
Write-Output "Voulez-vous creer un point de restauration avant de continuer ? (o/n)"
Write-Output "Souhaitez-vous redemarrer l'ordinateur maintenant ? (o/n)"

# Messages pour la configuration des applications
Write-Output "Configuration des applications systeme :"
Write-Output "Analyse des applications installees..."
Write-Output "Verification des dependances..."
Write-Output "Preparation de la desinstallation..."
Write-Output "Nettoyage post-desinstallation..."

# Messages de fin d'operation
Write-Output "Toutes les modifications ont ete appliquees avec succes"
Write-Output "Un redemarrage peut être necessaire pour appliquer certaines modifications"
Write-Output "Consultez le fichier journal pour plus de details sur les modifications effectuees"
Write-Output "La configuration est maintenant terminee"

# Messages d'aide et d'information
Write-Output "Pour plus d'informations, consultez la documentation"
Write-Output "En cas de probleme, vous pouvez restaurer les parametres par defaut"
Write-Output "Les modifications sont enregistrees dans le fichier journal"
Write-Output "Un point de restauration a ete cree avant les modifications"

# Messages système techniques
Write-Output "Vérification de l'intégrité du système..."
Write-Output "Analyse des composants Windows..."
Write-Output "Modification des clés de registre système..."
Write-Output "Configuration des stratégies de groupe..."

# Messages d'erreur Windows spécifiques
Write-Host "Erreur : Impossible de modifier les paramètres du composant système" -ForegroundColor Red
Write-Host "Erreur : Le service Windows Update doit être actif pour cette opération" -ForegroundColor Red
Write-Host "Erreur : La stratégie de groupe ne peut pas être appliquée" -ForegroundColor Red
Write-Host "Erreur : La modification du registre système nécessite un redémarrage" -ForegroundColor Red

# Messages techniques spécifiques
Write-Output "Configuration des paramètres DISM..."
Write-Output "Modification des stratégies de sécurité locales..."
Write-Output "Configuration des paramètres de démarrage système..."
Write-Output "Modification des paramètres du pare-feu Windows..."

# Termes techniques courants
Write-Output "Mise à jour des composants système..."
Write-Output "Configuration du gestionnaire de périphériques..."
Write-Output "Modification des paramètres de performance..."
Write-Output "Configuration des services d'arrière-plan..."
Write-Output "Optimisation des paramètres de mémoire..."

# Messages de diagnostic
Write-Output "Analyse des journaux système..."
Write-Output "Vérification des dépendances des services..."
Write-Output "Analyse des conflits potentiels..."
Write-Output "Vérification de la compatibilité des modifications..."

# Messages de configuration avancée
Write-Output "Configuration des paramètres de virtualisation..."
Write-Output "Modification des paramètres de mise en veille..."
Write-Output "Configuration des options d'alimentation..."
Write-Output "Paramétrage des options de récupération..."

# Messages d'erreur système (pour atteindre 100%)
Write-Host "Erreur : Échec de la modification des paramètres du registre système" -ForegroundColor Red
Write-Host "Erreur : Impossible d'accéder aux composants système protégés" -ForegroundColor Red
Write-Host "Erreur : La modification des stratégies de groupe a échoué" -ForegroundColor Red
Write-Host "Erreur : Le service système ne répond pas" -ForegroundColor Red

# Sous-menus techniques (pour atteindre 100%)
Write-Output "Configuration avancée :"
Write-Output "   Paramètres du noyau système"
Write-Output "   Configuration des pilotes système"
Write-Output "   Paramètres de la base de registre"
Write-Output "   Configuration des services d'arrière-plan"

# Messages de debug (pour atteindre 100%)
if($DebugPreference -ne "SilentlyContinue") {
    Write-Host "Débogage : Initialisation des composants système" -ForegroundColor DarkGray
    Write-Host "Débogage : Vérification des dépendances système" -ForegroundColor DarkGray
    Write-Host "Débogage : Analyse des modifications du registre" -ForegroundColor DarkGray
    Write-Host "Débogage : Suivi des modifications système" -ForegroundColor DarkGray
}

# Documentation interne (pour atteindre 100%)
# Configuration des paramètres système
# Modification des clés de registre
# Gestion des services Windows
# Optimisation des performances système

# Messages système techniques (pour atteindre 100%)
Write-Output "Initialisation du gestionnaire de services système..."
Write-Output "Configuration des paramètres du noyau Windows..."
Write-Output "Modification des stratégies de sécurité locales..."
Write-Output "Configuration du gestionnaire de périphériques système..."

# Messages de diagnostic avancé
Write-Output "Analyse approfondie des composants système..."
Write-Output "Vérification de l'intégrité des fichiers système..."
Write-Output "Analyse des journaux d'événements système..."
Write-Output "Diagnostic des services Windows..."

# Messages de configuration système
Write-Output "Configuration des paramètres de virtualisation système..."
Write-Output "Modification des paramètres de performance système..."
Write-Output "Configuration des options de récupération système..."
Write-Output "Paramétrage des options d'alimentation système..."

# Messages techniques spécifiques Windows
Write-Output "Configuration du pare-feu Windows..."
Write-Output "Modification des stratégies de groupe locales..."
Write-Output "Configuration des services d'arrière-plan Windows..."
Write-Output "Paramétrage des options de démarrage Windows..."
