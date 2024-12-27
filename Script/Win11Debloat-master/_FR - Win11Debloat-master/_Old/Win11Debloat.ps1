#Nécessite -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$Silencieux,
    [switch]$Sysprep,
    [switch]$ExecuterConfigurationApps,
    [switch]$ExecuterDefauts, [switch]$ExecuterDefautsWin11,
    [switch]$SupprimerApps, 
    [switch]$SupprimerAppsPersonnalise,
    [switch]$SupprimerAppsJeux,
    [switch]$SupprimerAppsCommunication,
    [switch]$SupprimerAppsDev,
    [switch]$SupprimerOutlookW11,
    [switch]$ForcerSuppressionEdge,
    [switch]$DesactiverDVR,
    [switch]$DesactiverTelemetrie,
    [switch]$DesactiverRecherchesBing, [switch]$DesactiverBing,
    [switch]$DesactiverAstuceVerrou, [switch]$DesactiverAstucesEcranVerrouillage,
    [switch]$DesactiverSuggestionsWindows, [switch]$DesactiverSuggestions,
    [switch]$AfficherDossiersCache,
    [switch]$AfficherExtensionsFichiers,
    [switch]$MasquerLecteursDupliques,
    [switch]$AlignementBarreGauche,
    [switch]$MasquerRechercheBarre, [switch]$AfficherIconeRecherche, [switch]$AfficherLabelRecherche, [switch]$AfficherBarreRecherche,
    [switch]$MasquerVueTaches,
    [switch]$DesactiverCopilot,
    [switch]$DesactiverRappel,
    [switch]$DesactiverWidgets,
    [switch]$MasquerWidgets,
    [switch]$DesactiverChat,
    [switch]$MasquerChat,
    [switch]$EffacerDemarrer,
    [switch]$EffacerDemarrerTousUtilisateurs,
    [switch]$RestaurerMenuContextuel,
    [switch]$MasquerAccueil,
    [switch]$MasquerGalerie,
    [switch]$ExplorateurVersAccueil,
    [switch]$ExplorateurVersCePC,
    [switch]$ExplorateurVersTelechargements,
    [switch]$ExplorateurVersOneDrive,
    [switch]$DesactiverOnedrive, [switch]$MasquerOnedrive,
    [switch]$Desactiver3dObjects, [switch]$Masquer3dObjects,
    [switch]$DesactiverMusique, [switch]$MasquerMusique,
    [switch]$DesactiverInclueBibliotheque, [switch]$MasquerInclueBibliotheque,
    [switch]$DesactiverDonnerAcces, [switch]$MasquerDonnerAcces,
    [switch]$DesactiverPartage, [switch]$MasquerPartage
)

# Afficher une erreur si l'environnement PowerShell actuel n'a pas LanguageMode défini sur FullLanguage
if ($ExecutionContext.SessionState.LanguageMode -ne "FullLanguage") {
    Write-Host "Erreur : Win11Debloat ne peut pas s'exécuter sur votre système, l'exécution PowerShell est restreinte par les politiques de sécurité" -ForegroundColor Red
    Write-Output ""
    Write-Output "Appuyez sur Entrée pour quitter..."
    Read-Host | Out-Null
    Exit
}

# Affiche le formulaire de sélection d'applications permettant à l'utilisateur de choisir les applications à supprimer ou à conserver
function AfficherFormulaireSelectionApps {
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

    # Initialisation des objets du formulaire
    $formulaire = New-Object System.Windows.Forms.Form
    $etiquette = New-Object System.Windows.Forms.Label
    $bouton1 = New-Object System.Windows.Forms.Button
    $bouton2 = New-Object System.Windows.Forms.Button
    $boiteSelection = New-Object System.Windows.Forms.CheckedListBox 
    $etiquetteChargement = New-Object System.Windows.Forms.Label
    $caseAppsInstallees = New-Object System.Windows.Forms.CheckBox
    $caseToutCocherDecocher = New-Object System.Windows.Forms.CheckBox
    $etatInitialFenetre = New-Object System.Windows.Forms.FormWindowState

    $global:indexBoiteSelection = -1

    # Gestionnaire d'événements du bouton Enregistrer
    $gestionnaire_boutonEnregistrer_Clic= 
    {
        if ($boiteSelection.CheckedItems -contains "Microsoft.WindowsStore" -and -not $Silencieux) {
            $selectionAvertissement = [System.Windows.Forms.Messagebox]::Show('Êtes-vous sûr de vouloir désinstaller le Microsoft Store ? Cette application ne peut pas être facilement réinstallée.', 'Êtes-vous sûr ?', 'YesNo', 'Warning')
        
            if ($selectionAvertissement -eq 'No') {
                return
            }
        }

        $global:AppsSelectionnees = $boiteSelection.CheckedItems

        # Créer le fichier qui stocke les applications sélectionnées s'il n'existe pas
        if (!(Test-Path "$PSScriptRoot/ListeAppsPersonnalisee")) {
            $null = New-Item "$PSScriptRoot/ListeAppsPersonnalisee"
        } 

        Set-Content -Path "$PSScriptRoot/ListeAppsPersonnalisee" -Value $global:AppsSelectionnees

        $formulaire.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $formulaire.Close()
    }

    # Gestionnaire d'événements du bouton Annuler
    $gestionnaire_boutonAnnuler_Clic= 
    {
        $formulaire.Close()
    }

    $boiteSelection_IndexSelectionneChange= 
    {
        $global:indexBoiteSelection = $boiteSelection.SelectedIndex
    }

    $boiteSelection_SourisBas=
    {
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            if ([System.Windows.Forms.Control]::ModifierKeys -eq [System.Windows.Forms.Keys]::Shift) {
                if ($global:indexBoiteSelection -ne -1) {
                    $indexHaut = $global:indexBoiteSelection

                    if ($boiteSelection.SelectedIndex -gt $indexHaut) {
                        for (($i = ($indexHaut)); $i -le $boiteSelection.SelectedIndex; $i++){
                            $boiteSelection.SetItemChecked($i, $boiteSelection.GetItemChecked($indexHaut))
                        }
                    }
                    elseif ($indexHaut -gt $boiteSelection.SelectedIndex) {
                        for (($i = ($boiteSelection.SelectedIndex)); $i -le $indexHaut; $i++){
                            $boiteSelection.SetItemChecked($i, $boiteSelection.GetItemChecked($indexHaut))
                        }
                    }
                }
            }
            elseif ($global:indexBoiteSelection -ne $boiteSelection.SelectedIndex) {
                $boiteSelection.SetItemChecked($boiteSelection.SelectedIndex, -not $boiteSelection.GetItemChecked($boiteSelection.SelectedIndex))
            }
        }
    }

    $formulaire.Text = "Win11Debloat - Sélection des Applications"
    $formulaire.Name = "formulaireSelectionApps"
    $formulaire.DataBindings.DefaultDataSourceUpdateMode = 0
    $formulaire.ClientSize = New-Object System.Drawing.Size(400,502)
    $formulaire.FormBorderStyle = 'FixedDialog'
    $formulaire.MaximizeBox = $False

    $bouton1.TabIndex = 4
    $bouton1.Name = "boutonEnregistrer"
    $bouton1.UseVisualStyleBackColor = $True
    $bouton1.Text = "Confirmer"
    $bouton1.Location = New-Object System.Drawing.Point(27,472)
    $bouton1.Size = New-Object System.Drawing.Size(75,23)
    $bouton1.DataBindings.DefaultDataSourceUpdateMode = 0
    $bouton1.add_Click($gestionnaire_boutonEnregistrer_Clic)

    $formulaire.Controls.Add($bouton1)

    $bouton2.TabIndex = 5
    $bouton2.Name = "boutonAnnuler"
    $bouton2.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $bouton2.UseVisualStyleBackColor = $True
    $bouton2.Text = "Annuler"
    $bouton2.Location = New-Object System.Drawing.Point(129,472)
    $bouton2.Size = New-Object System.Drawing.Size(75,23)
    $bouton2.DataBindings.DefaultDataSourceUpdateMode = 0
    $bouton2.add_Click($gestionnaire_boutonAnnuler_Clic)

    $formulaire.Controls.Add($bouton2)

    $etiquette.Location = New-Object System.Drawing.Point(13,5)
    $etiquette.Size = New-Object System.Drawing.Size(400,14)
    $etiquette.Font = 'Microsoft Sans Serif,8'
    $etiquette.Text = 'Cochez les applications que vous souhaitez supprimer, décochez celles que vous souhaitez conserver'

    $formulaire.Controls.Add($etiquette)

    $etiquetteChargement.Location = New-Object System.Drawing.Point(16,46)
    $etiquetteChargement.Size = New-Object System.Drawing.Size(300,418)
    $etiquetteChargement.Text = 'Chargement des applications...'
    $etiquetteChargement.BackColor = "White"
    $etiquetteChargement.Visible = $false

    $formulaire.Controls.Add($etiquetteChargement)

    $caseAppsInstallees.TabIndex = 6
    $caseAppsInstallees.Location = New-Object System.Drawing.Point(230,474)
    $caseAppsInstallees.Size = New-Object System.Drawing.Size(150,20)
    $caseAppsInstallees.Text = 'Afficher uniquement les apps installées'
    $caseAppsInstallees.add_CheckedChanged($charger_Apps)

    $formulaire.Controls.Add($caseAppsInstallees)

    $caseToutCocherDecocher.TabIndex = 7
    $caseToutCocherDecocher.Location = New-Object System.Drawing.Point(16,22)
    $caseToutCocherDecocher.Size = New-Object System.Drawing.Size(150,20)
    $caseToutCocherDecocher.Text = 'Tout cocher/décocher'
    $caseToutCocherDecocher.add_CheckedChanged($cocher_Tout)

    $formulaire.Controls.Add($caseToutCocherDecocher)

    $boiteSelection.FormattingEnabled = $True
    $boiteSelection.DataBindings.DefaultDataSourceUpdateMode = 0
    $boiteSelection.Name = "boiteSelection"
    $boiteSelection.Location = New-Object System.Drawing.Point(13,43)
    $boiteSelection.Size = New-Object System.Drawing.Size(374,424)
    $boiteSelection.TabIndex = 3
    $boiteSelection.add_SelectedIndexChanged($boiteSelection_IndexSelectionneChange)
    $boiteSelection.add_Click($boiteSelection_SourisBas)

    $formulaire.Controls.Add($boiteSelection)

    # Sauvegarder l'état initial du formulaire
    $etatInitialFenetre = $formulaire.WindowState

    # Charger les applications dans la boîte de sélection
    $formulaire.add_Load($charger_Apps)

    # Focus sur la boîte de sélection à l'ouverture du formulaire
    $formulaire.Add_Shown({$formulaire.Activate(); $boiteSelection.Focus()})

    # Afficher le formulaire
    return $formulaire.ShowDialog()
}

# Force la suppression de Microsoft Edge en utilisant son désinstalleur
function ForcerSuppressionEdge {
    # Basé sur le travail de loadstring1 & ave9858
    Write-Output "> Désinstallation forcée de Microsoft Edge..."

    $vueRegistre = [Microsoft.Win32.RegistryView]::Registry32
    $hklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $vueRegistre)
    $hklm.CreateSubKey('SOFTWARE\Microsoft\EdgeUpdateDev').SetValue('AllowUninstall', '')

    # Créer un stub (La création de celui-ci permet d'une manière ou d'une autre de désinstaller Edge)
    $stubEdge = "$env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
    New-Item $stubEdge -ItemType Directory | Out-Null
    New-Item "$stubEdge\MicrosoftEdge.exe" | Out-Null

    # Supprimer Edge
    $cleDesinstallation = $hklm.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge')
    if ($null -ne $cleDesinstallation) {
        Write-Output "Exécution du désinstalleur..."
        $chaineDesinstallation = $cleDesinstallation.GetValue('UninstallString') + ' --force-uninstall'
        Start-Process cmd.exe "/c $chaineDesinstallation" -WindowStyle Hidden -Wait

        Write-Output "Suppression des fichiers restants..."

        $cheminsEdge = @(
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk",
            "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk",
            "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk",
            "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Tombstones\Microsoft Edge.lnk",
            "$env:PUBLIC\Desktop\Microsoft Edge.lnk",
            "$env:USERPROFILE\Desktop\Microsoft Edge.lnk",
            "$stubEdge"
        )

        foreach ($chemin in $cheminsEdge){
            if (Test-Path -Path $chemin) {
                Remove-Item -Path $chemin -Force -Recurse -ErrorAction SilentlyContinue
                Write-Host "  Supprimé $chemin" -ForegroundColor DarkGray
            }
        }

        Write-Output "Nettoyage du registre..."

        # Supprimer MS Edge du démarrage automatique
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "MicrosoftEdgeAutoLaunch_A9F6DCE4ABADF4F51CF45CD7129E3C6C" /f *>$null
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "Microsoft Edge Update" /f *>$null
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "MicrosoftEdgeAutoLaunch_A9F6DCE4ABADF4F51CF45CD7129E3C6C" /f *>$null
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "Microsoft Edge Update" /f *>$null

        Write-Output "Microsoft Edge a été désinstallé"
    }
    else {
        Write-Output ""
        Write-Host "Erreur : Impossible de forcer la désinstallation de Microsoft Edge, le désinstalleur n'a pas été trouvé" -ForegroundColor Red
    }
    
    Write-Output ""
}

# Exécute la commande fournie et supprime les indicateurs de progression/barres de la sortie console
function Supprimer-Progression {
    param(
        [ScriptBlock]$BlocScript
    )

    # Modèle regex pour correspondre aux caractères de rotation et aux motifs de barre de progression
    $modeleProgression = 'Γû[Æê]|^\s+[-\\|/]\s+$'

    # Modèle regex corrigé pour le formatage de la taille, assurant l'utilisation correcte des groupes de capture
    $modeleTaille = '(\d+(\.\d{1,2})?)\s+(B|KB|MB|GB|TB|PB) /\s+(\d+(\.\d{1,2})?)\s+(B|KB|MB|GB|TB|PB)'

    & $BlocScript 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            "ERREUR : $($_.Exception.Message)"
        } else {
            $ligne = $_ -replace $modeleProgression, '' -replace $modeleTaille, ''
            if (-not ([string]::IsNullOrWhiteSpace($ligne)) -and -not ($ligne.StartsWith('  '))) {
                $ligne
            }
        }
    }
}

# Importer et exécuter le fichier reg
function ImporterRegistre {
    param (
        $message,
        $chemin
    )

    Write-Output $message

    if (!$global:Params.ContainsKey("Sysprep")) {
        reg import "$PSScriptRoot\Regfiles\$chemin"  
    }
    else {
        $cheminUtilisateurDefaut = $env:USERPROFILE.Replace($env:USERNAME, 'Default\NTUSER.DAT')
        
        reg load "HKU\Default" $cheminUtilisateurDefaut | Out-Null
        reg import "$PSScriptRoot\Regfiles\Sysprep\$chemin"  
        reg unload "HKU\Default" | Out-Null
    }

    Write-Output ""
}

# Redémarrer le processus Windows Explorer
function RedemarrerExplorateur {
    Write-Output "> Redémarrage du processus Windows Explorer pour appliquer tous les changements... (Cela peut causer quelques scintillements)"

    # Redémarrer uniquement si l'architecture du processus powershell correspond à celle du système d'exploitation
    # Le redémarrage d'explorer depuis une fenêtre PowerShell 32 bits échouera sur un système d'exploitation 64 bits
    if ([Environment]::Is64BitProcess -eq [Environment]::Is64BitOperatingSystem)
    {
        Stop-Process -processName: Explorer -Force
    }
    else {
        Write-Warning "Impossible de redémarrer le processus Windows Explorer, veuillez redémarrer manuellement votre PC pour appliquer tous les changements."
    }
}

# Remplacer le menu démarrer pour tous les utilisateurs, en utilisant le modèle de menu démarrer par défaut, cela efface toutes les applications épinglées
# Crédit: https://lazyadmin.nl/win-11/customize-windows-11-start-menu-layout/
function RemplacerMenuDemarrerPourTousUtilisateurs {
    param (
        $modeleMenuDemarrer = "$PSScriptRoot/Start/start2.bin"
    )

    Write-Output "> Suppression de toutes les applications épinglées du menu démarrer pour tous les utilisateurs..."

    # Vérifier si le fichier modèle bin existe, retourner tôt s'il n'existe pas
    if (-not (Test-Path $modeleMenuDemarrer)) {
        Write-Host "Erreur : Impossible de nettoyer le menu démarrer, fichier start2.bin manquant dans le dossier du script" -ForegroundColor Red
        Write-Output ""
        return
    }

    # Obtenir le chemin du fichier de mise en page du menu démarrer pour l'utilisateur par défaut
    $cheminDefautMenuDemarrer = "$env:SystemDrive\Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"

    # Créer le dossier s'il n'existe pas
    if (-not (Test-Path $cheminDefautMenuDemarrer)) {
        New-Item -Path $cheminDefautMenuDemarrer -ItemType Directory -Force | Out-Null
    }

    try {
        # Copier le modèle de menu démarrer vers le profil utilisateur par défaut
        Copy-Item -Path $modeleMenuDemarrer -Destination "$cheminDefautMenuDemarrer\start2.bin" -Force

        # Obtenir tous les profils utilisateurs
        $profilsUtilisateurs = Get-ChildItem -Path "$env:SystemDrive\Users" -Directory | Where-Object { $_.Name -notin @("Public", "Default", "Default User", "All Users") }

        # Copier le modèle de menu démarrer vers chaque profil utilisateur
        foreach ($profil in $profilsUtilisateurs) {
            $cheminMenuDemarrer = "$($profil.FullName)\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"

            # Créer le dossier s'il n'existe pas
            if (-not (Test-Path $cheminMenuDemarrer)) {
                New-Item -Path $cheminMenuDemarrer -ItemType Directory -Force | Out-Null
            }

            # Copier le modèle de menu démarrer
            Copy-Item -Path $modeleMenuDemarrer -Destination "$cheminMenuDemarrer\start2.bin" -Force
            Write-Host "  Menu démarrer nettoyé pour l'utilisateur $($profil.Name)" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "Erreur : Impossible de nettoyer le menu démarrer pour tous les utilisateurs" -ForegroundColor Red
        Write-Host $psitem.Exception.StackTrace -ForegroundColor Gray
    }

    Write-Output ""
}

# Remplacer le menu démarrer pour l'utilisateur actuel, en utilisant le modèle de menu démarrer par défaut, cela efface toutes les applications épinglées
function RemplacerMenuDemarrer {
    param (
        $modeleMenuDemarrer = "$PSScriptRoot/Start/start2.bin"
    )

    # Vérifier si le fichier modèle bin existe, retourner tôt s'il n'existe pas
    if (-not (Test-Path $modeleMenuDemarrer)) {
        Write-Host "Erreur : Impossible de nettoyer le menu démarrer, fichier start2.bin manquant dans le dossier du script" -ForegroundColor Red
        Write-Output ""
        return
    }

    try {
        # Obtenir le chemin du fichier de mise en page du menu démarrer
        $cheminMenuDemarrer = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"

        # Créer le dossier s'il n'existe pas
        if (-not (Test-Path $cheminMenuDemarrer)) {
            New-Item -Path $cheminMenuDemarrer -ItemType Directory -Force | Out-Null
        }

        # Copier le modèle de menu démarrer
        Copy-Item -Path $modeleMenuDemarrer -Destination "$cheminMenuDemarrer\start2.bin" -Force
    }
    catch {
        Write-Host "Erreur : Impossible de nettoyer le menu démarrer" -ForegroundColor Red
        Write-Host $psitem.Exception.StackTrace -ForegroundColor Gray
    }
}

# Attendre que l'utilisateur appuie sur une touche avant de quitter
function AttendreAppuiTouchePourQuitter {
    if (-not $Silencieux) {
        Write-Output "Appuyez sur une touche pour quitter..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

# Ajouter un paramètre à la liste des paramètres globaux
function AjouterParametre {
    param (
        $nomParametre,
        $description
    )

    if (-not $global:Params.ContainsKey($nomParametre)){
        $global:Params.Add($nomParametre, $true)
    }

    # Ajouter le paramètre au fichier des paramètres enregistrés
    Add-Content -Path "$PSScriptRoot/ParametresEnregistres" -Value "$nomParametre # $description"
}

# Afficher l'en-tête avec le titre spécifié
function AfficherEntete {
    param (
        $titre
    )

    Clear-Host
    Write-Output ""
    Write-Output "Win11Debloat - $titre"
    Write-Output "--------------------"
    Write-Output ""
}

# Initialiser les variables globales
$global:Params = @{}
$global:wingetInstalle = $false

# Vérifier si winget est installé
try {
    $null = & winget --version 2>&1
    $global:wingetInstalle = $true
}
catch {
    Write-Host "Avertissement : WinGet n'est pas installé ou est obsolète, certaines fonctionnalités peuvent ne pas fonctionner correctement" -ForegroundColor Yellow
    Write-Output ""
}

# Obtenir la version de Windows
$VersionWin = [System.Environment]::OSVersion.Version.Build

# Stocker le nombre initial de paramètres
$SPParamCount = $global:Params.Keys.Count

# Afficher le menu principal si aucun paramètre n'est fourni
if ($MyInvocation.BoundParameters.Count -eq 0) {
    AfficherEntete 'Menu Principal'
    Write-Output "Sélectionnez une option :"
    Write-Output ""
    Write-Output "1. Mode par défaut"
    Write-Output "   - Supprime les applications par défaut"
    Write-Output "   - Désactive la télémétrie"
    Write-Output "   - Désactive les suggestions Windows"
    Write-Output "   - Désactive les recherches Bing"
    Write-Output "   - Désactive les astuces de l'écran de verrouillage"
    Write-Output "   - Affiche les extensions de fichiers connues"
    Write-Output "   - Affiche les dossiers cachés"
    Write-Output ""
    Write-Output "2. Mode personnalisé"
    Write-Output "   - Sélectionnez les modifications à appliquer"
    Write-Output ""
    Write-Output "3. Suppression d'applications"
    Write-Output "   - Sélectionnez les applications à supprimer"
    Write-Output ""
    Write-Output "4. Charger les paramètres enregistrés"
    Write-Output "   - Exécute les modifications précédemment enregistrées"
    Write-Output ""
    Write-Output "5. Quitter"
    Write-Output ""

    Do {
        $choix = Read-Host "Entrez votre choix (1-5)"
    }
    while ($choix -ne '1' -and $choix -ne '2' -and $choix -ne '3' -and $choix -ne '4' -and $choix -ne '5')

    switch ($choix) {
        # Mode par défaut
        '1' {
            AfficherEntete 'Mode par défaut'

            # Ajouter les paramètres par défaut
            AjouterParametre 'SupprimerApps' "Supprimer la sélection par défaut d'applications"
            AjouterParametre 'DesactiverTelemetrie' "Désactiver la télémétrie, les données de diagnostic, l'historique d'activité, le suivi de lancement d'applications et les publicités ciblées"
            AjouterParametre 'DesactiverSuggestions' "Désactiver les astuces, conseils, suggestions et publicités dans Windows"
            AjouterParametre 'DesactiverBing' "Désactiver la recherche web Bing, l'IA Bing et Cortana dans la recherche Windows"
            AjouterParametre 'DesactiverAstucesEcranVerrouillage' "Désactiver les astuces et conseils sur l'écran de verrouillage"
            AjouterParametre 'AfficherExtensionsFichiers' "Afficher les extensions pour les types de fichiers connus"
            AjouterParametre 'AfficherDossiersCache' "Afficher les fichiers, dossiers et lecteurs cachés"

            # Supprimer l'invite si le paramètre Silencieux est passé
            if (-not $Silencieux) {
                Write-Output ""
                Write-Output "Appuyez sur Entrée pour exécuter le script ou appuyez sur CTRL+C pour quitter..."
                Read-Host | Out-Null
            }

            AfficherEntete 'Mode par défaut'
        }

        # Mode personnalisé
        '2' {
            AfficherEntete 'Mode personnalisé'
            Write-Output "Win11Debloat effectuera les modifications suivantes :"
            Write-Output ""

            if ($( Read-Host -Prompt "Voulez-vous supprimer des applications ? (o/n)" ) -eq 'o') {
                Write-Output ""

                if ($( Read-Host -Prompt "   Supprimer la sélection par défaut d'applications ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'SupprimerApps' "Supprimer la sélection par défaut d'applications"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Supprimer les applications de communication (Mail, Calendrier et Contacts) ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'SupprimerAppsCommunication' "Supprimer les applications Mail, Calendrier et Contacts"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Supprimer la nouvelle application Outlook pour Windows ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'SupprimerW11Outlook' "Supprimer la nouvelle application Outlook pour Windows"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Supprimer les applications liées au développement ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'SupprimerAppsDev' "Supprimer les applications liées au développement"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Supprimer les applications liées aux jeux ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'SupprimerAppsJeux' "Supprimer les applications liées aux jeux"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Forcer la suppression de Microsoft Edge ? NON RECOMMANDÉ ! (o/n)" ) -eq 'o') {
                    AjouterParametre 'ForcerSuppressionEdge' "Forcer la suppression de Microsoft Edge"
                }
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Voulez-vous désactiver des fonctionnalités de Windows ? (o/n)" ) -eq 'o') {
                Write-Output ""

                if ($( Read-Host -Prompt "   Désactiver l'enregistrement d'écran/jeu Xbox ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'DesactiverDVR' "Désactiver l'enregistrement d'écran/jeu Xbox"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Désactiver la télémétrie, les données de diagnostic et le suivi ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'DesactiverTelemetrie' "Désactiver la télémétrie, les données de diagnostic, l'historique d'activité, le suivi de lancement d'applications et les publicités ciblées"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Désactiver les recherches web Bing et Cortana dans la recherche Windows ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'DesactiverBing' "Désactiver la recherche web Bing, l'IA Bing et Cortana dans la recherche Windows"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Désactiver les astuces sur l'écran de verrouillage ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'DesactiverAstucesEcranVerrouillage' "Désactiver les astuces et conseils sur l'écran de verrouillage"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Désactiver les suggestions Windows ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'DesactiverSuggestions' "Désactiver les astuces, conseils, suggestions et publicités dans Windows"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Désactiver Windows Copilot ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'DesactiverCopilot' "Désactiver et supprimer Windows Copilot"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Désactiver les instantanés Windows Recall ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'DesactiverRappel' "Désactiver les instantanés Windows Recall"
                }
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Voulez-vous apporter des modifications au menu démarrer ? (o/n)" ) -eq 'o') {
                Write-Output ""

                if ($( Read-Host -Prompt "   Supprimer toutes les applications épinglées du menu démarrer ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'EffacerDemarrer' "Supprimer toutes les applications épinglées du menu démarrer"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Supprimer toutes les applications épinglées du menu démarrer pour tous les utilisateurs ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'EffacerDemarrerTousUtilisateurs' "Supprimer toutes les applications épinglées du menu démarrer pour tous les utilisateurs"
                }
            }

            # Uniquement pour Windows 11
            if ($VersionWin -ge 22000) {
                Write-Output ""

                if ($( Read-Host -Prompt "Voulez-vous restaurer le menu contextuel de Windows 10 ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'RestaurerMenuContextuel' "Restaurer l'ancien style de menu contextuel de Windows 10"
                }
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Voulez-vous apporter des modifications à la barre des tâches et aux services associés ? (o/n)" ) -eq 'o') {
                # Afficher ces options spécifiques uniquement pour les utilisateurs Windows 11 exécutant la build 22000 ou ultérieure
                if ($VersionWin -ge 22000) {
                    Write-Output ""

                    if ($( Read-Host -Prompt "   Aligner les boutons de la barre des tâches à gauche ? (o/n)" ) -eq 'o') {
                        AjouterParametre 'AlignementBarreGauche' "Aligner les icônes de la barre des tâches à gauche"
                    }

                    # Afficher les options pour l'icône de recherche sur la barre des tâches, continuer uniquement sur une entrée valide
                    Do {
                        Write-Output ""
                        Write-Host "   Options :" -ForegroundColor Yellow
                        Write-Host "    (n) Aucun changement" -ForegroundColor Yellow
                        Write-Host "    (1) Masquer l'icône de recherche de la barre des tâches" -ForegroundColor Yellow
                        Write-Host "    (2) Afficher l'icône de recherche sur la barre des tâches" -ForegroundColor Yellow
                        Write-Host "    (3) Afficher l'icône de recherche avec étiquette sur la barre des tâches" -ForegroundColor Yellow
                        Write-Host "    (4) Afficher la boîte de recherche sur la barre des tâches" -ForegroundColor Yellow
                        $EntreeRechercheBarreTaches = Read-Host "   Masquer ou modifier l'icône de recherche sur la barre des tâches ? (n/1/2/3/4)" 
                    }
                    while ($EntreeRechercheBarreTaches -ne 'n' -and $EntreeRechercheBarreTaches -ne '0' -and $EntreeRechercheBarreTaches -ne '1' -and $EntreeRechercheBarreTaches -ne '2' -and $EntreeRechercheBarreTaches -ne '3' -and $EntreeRechercheBarreTaches -ne '4') 

                    # Sélectionner l'option de recherche de la barre des tâches correcte en fonction de l'entrée utilisateur
                    switch ($EntreeRechercheBarreTaches) {
                        '1' {
                            AjouterParametre 'MasquerRechercheBarre' "Masquer l'icône de recherche de la barre des tâches"
                        }
                        '2' {
                            AjouterParametre 'AfficherIconeRecherche' "Afficher l'icône de recherche sur la barre des tâches"
                        }
                        '3' {
                            AjouterParametre 'AfficherLabelRecherche' "Afficher l'icône de recherche avec étiquette sur la barre des tâches"
                        }
                        '4' {
                            AjouterParametre 'AfficherBarreRecherche' "Afficher la boîte de recherche sur la barre des tâches"
                        }
                    }

                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer le bouton vue des tâches de la barre des tâches ? (o/n)" ) -eq 'o') {
                        AjouterParametre 'MasquerVueTaches' "Masquer le bouton vue des tâches de la barre des tâches"
                    }
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Désactiver le service des widgets et masquer l'icône de la barre des tâches ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'DesactiverWidgets' "Désactiver le service des widgets et masquer l'icône des widgets (actualités et centres d'intérêt) de la barre des tâches"
                }

                # Afficher cette option uniquement pour les utilisateurs Windows exécutant la build 22621 ou antérieure
                if ($VersionWin -le 22621) {
                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer l'icône de discussion (meet now) de la barre des tâches ? (o/n)" ) -eq 'o') {
                        AjouterParametre 'MasquerChat' "Masquer l'icône de discussion (meet now) de la barre des tâches"
                    }
                }
            }

            Write-Output ""

            if ($( Read-Host -Prompt "Voulez-vous apporter des modifications à l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                # Afficher les options pour changer l'emplacement par défaut de l'Explorateur de fichiers
                Do {
                    Write-Output ""
                    Write-Host "   Options :" -ForegroundColor Yellow
                    Write-Host "    (n) Aucun changement" -ForegroundColor Yellow
                    Write-Host "    (1) Ouvrir l'Explorateur de fichiers sur 'Accueil'" -ForegroundColor Yellow
                    Write-Host "    (2) Ouvrir l'Explorateur de fichiers sur 'Ce PC'" -ForegroundColor Yellow
                    Write-Host "    (3) Ouvrir l'Explorateur de fichiers sur 'Téléchargements'" -ForegroundColor Yellow
                    Write-Host "    (4) Ouvrir l'Explorateur de fichiers sur 'OneDrive'" -ForegroundColor Yellow
                    $EntreeRechercheExpl = Read-Host "   Changer l'emplacement par défaut d'ouverture de l'Explorateur de fichiers ? (n/1/2/3/4)" 
                }
                while ($EntreeRechercheExpl -ne 'n' -and $EntreeRechercheExpl -ne '0' -and $EntreeRechercheExpl -ne '1' -and $EntreeRechercheExpl -ne '2' -and $EntreeRechercheExpl -ne '3' -and $EntreeRechercheExpl -ne '4') 

                # Sélectionner l'option de recherche de la barre des tâches correcte en fonction de l'entrée utilisateur
                switch ($EntreeRechercheExpl) {
                    '1' {
                        AjouterParametre 'ExplorateurVersAccueil' "Changer l'emplacement par défaut d'ouverture de l'Explorateur de fichiers vers 'Accueil'"
                    }
                    '2' {
                        AjouterParametre 'ExplorateurVersCePC' "Changer l'emplacement par défaut d'ouverture de l'Explorateur de fichiers vers 'Ce PC'"
                    }
                    '3' {
                        AjouterParametre 'ExplorateurVersTelechargements' "Changer l'emplacement par défaut d'ouverture de l'Explorateur de fichiers vers 'Téléchargements'"
                    }
                    '4' {
                        AjouterParametre 'ExplorateurVersOneDrive' "Changer l'emplacement par défaut d'ouverture de l'Explorateur de fichiers vers 'OneDrive'"
                    }
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Afficher les fichiers, dossiers et lecteurs cachés ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'AfficherDossiersCache' "Afficher les fichiers, dossiers et lecteurs cachés"
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Afficher les extensions de fichiers pour les types connus ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'AfficherExtensionsFichiers' "Afficher les extensions de fichiers pour les types connus"
                }

                # Afficher cette option uniquement pour les utilisateurs Windows 11 exécutant la build 22000 ou ultérieure
                if ($VersionWin -ge 22000) {
                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer la section Accueil du panneau latéral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                        AjouterParametre 'MasquerAccueil' "Masquer la section Accueil du panneau latéral de l'Explorateur de fichiers"
                    }

                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer la section Galerie du panneau latéral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                        AjouterParametre 'MasquerGalerie' "Masquer la section Galerie du panneau latéral de l'Explorateur de fichiers"
                    }
                }

                Write-Output ""

                if ($( Read-Host -Prompt "   Masquer les entrées de lecteurs amovibles en double du panneau latéral de l'Explorateur de fichiers pour qu'ils n'apparaissent que sous Ce PC ? (o/n)" ) -eq 'o') {
                    AjouterParametre 'MasquerLecteursDupliques' "Masquer les entrées de lecteurs amovibles en double du panneau latéral de l'Explorateur de fichiers"
                }

                # Afficher l'option de désactivation de ces dossiers spécifiques uniquement pour les utilisateurs Windows 10
                if (get-ciminstance -query "select caption from win32_operatingsystem where caption like '%Windows 10%'") {
                    Write-Output ""

                    if ($( Read-Host -Prompt "Voulez-vous masquer des dossiers du panneau latéral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                        Write-Output ""

                        if ($( Read-Host -Prompt "   Masquer le dossier OneDrive du panneau latéral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                            AjouterParametre 'MasquerOnedrive' "Masquer le dossier OneDrive dans le panneau latéral de l'Explorateur de fichiers"
                        }

                        Write-Output ""
                        
                        if ($( Read-Host -Prompt "   Masquer le dossier Objets 3D du panneau latéral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                            AjouterParametre 'Masquer3dObjects' "Masquer le dossier Objets 3D sous 'Ce PC' dans l'Explorateur de fichiers" 
                        }
                        
                        Write-Output ""

                        if ($( Read-Host -Prompt "   Masquer le dossier Musique du panneau latéral de l'Explorateur de fichiers ? (o/n)" ) -eq 'o') {
                            AjouterParametre 'MasquerMusique' "Masquer le dossier Musique sous 'Ce PC' dans l'Explorateur de fichiers"
                        }
                    }
                }
            }

            # Afficher l'option de désactivation des éléments du menu contextuel uniquement pour les utilisateurs Windows 10 ou si l'utilisateur a choisi de restaurer le menu contextuel Windows 10
            if ((get-ciminstance -query "select caption from win32_operatingsystem where caption like '%Windows 10%'") -or $global:Params.ContainsKey('RestaurerMenuContextuel')) {
                Write-Output ""

                if ($( Read-Host -Prompt "Voulez-vous désactiver des options du menu contextuel ? (o/n)" ) -eq 'o') {
                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer l'option 'Inclure dans la bibliothèque' dans le menu contextuel ? (o/n)" ) -eq 'o') {
                        AjouterParametre 'MasquerInclueBibliotheque' "Masquer l'option 'Inclure dans la bibliothèque' dans le menu contextuel"
                    }

                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer l'option 'Donner l'accès à' dans le menu contextuel ? (o/n)" ) -eq 'o') {
                        AjouterParametre 'MasquerDonnerAcces' "Masquer l'option 'Donner l'accès à' dans le menu contextuel"
                    }

                    Write-Output ""

                    if ($( Read-Host -Prompt "   Masquer l'option 'Partager' dans le menu contextuel ? (o/n)" ) -eq 'o') {
                        AjouterParametre 'MasquerPartage' "Masquer l'option 'Partager' dans le menu contextuel"
                    }
                }
            }

            # Supprimer l'invite si le paramètre Silencieux est passé
            if (-not $Silencieux) {
                Write-Output ""
                Write-Output ""
                Write-Output ""
                Write-Output "Appuyez sur Entrée pour confirmer vos choix et exécuter le script ou appuyez sur CTRL+C pour quitter..."
                Read-Host | Out-Null
            }

            AfficherEntete 'Mode personnalisé'
        }

        # Suppression d'applications
        '3' {
            AfficherEntete "Suppression d'applications"

            $resultat = AfficherFormulaireSelectionApps

            if ($resultat -eq [System.Windows.Forms.DialogResult]::OK) {
                Write-Output "Vous avez sélectionné $($global:AppsSelectionnees.Count) applications à supprimer"
                AjouterParametre 'SupprimerAppsPersonnalise' "Supprimer $($global:AppsSelectionnees.Count) applications :"

                # Supprimer l'invite si le paramètre Silencieux est passé
                if (-not $Silencieux) {
                    Write-Output ""
                    Write-Output "Appuyez sur Entrée pour supprimer les applications sélectionnées ou appuyez sur CTRL+C pour quitter..."
                    Read-Host | Out-Null
                    AfficherEntete "Suppression d'applications"
                }
            }
            else {
                Write-Host "La sélection a été annulée, aucune application n'a été supprimée" -ForegroundColor Red
                Write-Output ""
            }
        }

        # Charger les paramètres personnalisés depuis le fichier "ParametresEnregistres"
        '4' {
            if (-not $Silencieux) {
                AfficherEntete 'Mode personnalisé'
                Write-Output "Win11Debloat effectuera les modifications suivantes :"

                # Obtenir et afficher les informations des paramètres par défaut depuis le fichier
                Foreach ($ligne in (Get-Content -Path "$PSScriptRoot/ParametresEnregistres" )) { 
                    # Supprimer les espaces avant et après la ligne
                    $ligne = $ligne.Trim()
                
                    # Vérifier si la ligne contient un commentaire
                    if (-not ($ligne.IndexOf('#') -eq -1)) {
                        $nomParametre = $ligne.Substring(0, $ligne.IndexOf('#'))

                        # Afficher la description du paramètre et ajouter le paramètre à la liste Params
                        if ($nomParametre -eq "SupprimerAppsPersonnalise") {
                            if (-not (Test-Path "$PSScriptRoot/ListeAppsPersonnalisee")) {
                                # Le fichier des applications n'existe pas, passer
                                continue
                            }
                            
                            $listeApps = LireListeAppsDepuisFichier "$PSScriptRoot/ListeAppsPersonnalisee"
                            Write-Output "- Supprimer $($listeApps.Count) applications :"
                            Write-Host $listeApps -ForegroundColor DarkGray
                        }
                        else {
                            Write-Output $ligne.Substring(($ligne.IndexOf('#') + 1), ($ligne.Length - $ligne.IndexOf('#') - 1))
                        }

                        if (-not $global:Params.ContainsKey($nomParametre)) {
                            $global:Params.Add($nomParametre, $true)
                        }
                    }
                }

                Write-Output ""
                Write-Output ""
                Write-Output "Appuyez sur Entrée pour exécuter le script ou appuyez sur CTRL+C pour quitter..."
                Read-Host | Out-Null
            }

            AfficherEntete 'Mode personnalisé'
        }

        # Quitter
        '5' {
            Exit
        }
    }
}
else {
    AfficherEntete 'Mode personnalisé'
}

# Si le nombre de clés dans SPParams est égal au nombre de clés dans Params alors aucune modification/changement n'a été sélectionné
# ou ajouté par l'utilisateur, et le script peut se terminer sans faire de changements.
if ($SPParamCount -eq $global:Params.Keys.Count) {
    Write-Output "Le script s'est terminé sans faire de changements."

    AttendreAppuiTouchePourQuitter
}
else {
    # Exécuter tous les paramètres sélectionnés/fournis
    switch ($global:Params.Keys) {
        'SupprimerApps' {
            $listeApps = LireListeAppsDepuisFichier "$PSScriptRoot/Appslist.txt" 
            Write-Output "> Suppression de la sélection par défaut de $($listeApps.Count) applications..."
            SupprimerApplications $listeApps
            continue
        }
        'SupprimerAppsPersonnalise' {
            if (-not (Test-Path "$PSScriptRoot/ListeAppsPersonnalisee")) {
                Write-Host "> Erreur : Impossible de charger la liste personnalisée d'applications depuis le fichier, aucune application n'a été supprimée" -ForegroundColor Red
                Write-Output ""
                continue
            }
            
            $listeApps = LireListeAppsDepuisFichier "$PSScriptRoot/ListeAppsPersonnalisee"
            Write-Output "> Suppression de $($listeApps.Count) applications..."
            SupprimerApplications $listeApps
            continue
        }
        'SupprimerAppsCommunication' {
            Write-Output "> Suppression des applications Mail, Calendrier et Contacts..."
            
            $listeApps = 'Microsoft.windowscommunicationsapps', 'Microsoft.People', 'microsoft.windowscommunicationsapps'
            SupprimerApplications $listeApps
            continue
        }
        'SupprimerW11Outlook' {
            Write-Output "> Suppression de la nouvelle application Outlook pour Windows..."
            
            $listeApps = 'Microsoft.OutlookForWindows'
            SupprimerApplications $listeApps
            continue
        }
        'SupprimerAppsDev' {
            Write-Output "> Suppression des applications liées au développement..."
            
            $listeApps = 'Microsoft.PowerAutomateDesktop', 'Microsoft.PowerShellPreview', 'Microsoft.WindowsTerminal', 'Microsoft.WindowsTerminalPreview', 'Microsoft.Windows.DevHome'
            SupprimerApplications $listeApps
            continue
        }
        'SupprimerAppsJeux' {
            Write-Output "> Suppression des applications liées aux jeux..."
            
            $listeApps = 'Microsoft.GamingApp', 'Microsoft.XboxApp', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxIdentityProvider', 'Microsoft.XboxSpeechToTextOverlay'
            SupprimerApplications $listeApps
            continue
        }
        'ForcerSuppressionEdge' {
            ForcerSuppressionEdge
            continue
        }
        'DesactiverDVR' {
            ImporterRegistre "> Désactivation de l'enregistrement d'écran/jeu Xbox..." "Disable_GameDVR.reg"
            continue
        }
        'EffacerDemarrer' {
            RemplacerMenuDemarrer
            continue
        }
        'EffacerDemarrerTousUtilisateurs' {
            RemplacerMenuDemarrerPourTousUtilisateurs
            continue
        }
        'DesactiverTelemetrie' {
            ImporterRegistre "> Désactivation de la télémétrie, des données de diagnostic, de l'historique d'activité, du suivi de lancement d'applications et des publicités ciblées..." "Disable_Telemetry.reg"
            continue
        }
        {$_ -in "DesactiverBing", "DesactiverRecherchesBing"} {
            ImporterRegistre "> Désactivation de la recherche web Bing, de l'IA Bing et de Cortana dans la recherche Windows..." "Disable_Bing_Cortana_In_Search.reg"
            
            # Supprimer aussi le package de l'application pour la recherche Bing
            $listeApps = 'Microsoft.BingSearch'
            SupprimerApplications $listeApps
            continue
        }
        {$_ -in "DesactiverAstucesEcranVerrouillage", "DesactiverAstuceVerrou"} {
            ImporterRegistre "> Désactivation des astuces et conseils sur l'écran de verrouillage..." "Disable_Lockscreen_Tips.reg"
            continue
        }
        {$_ -in "DesactiverSuggestions", "DesactiverSuggestionsWindows"} {
            ImporterRegistre "> Désactivation des astuces, conseils, suggestions et publicités dans Windows..." "Disable_Windows_Suggestions.reg"
            continue
        }
        'RestaurerMenuContextuel' {
            ImporterRegistre "> Restauration de l'ancien style de menu contextuel de Windows 10..." "Disable_Show_More_Options_Context_Menu.reg"
            continue
        }
        'AlignementBarreGauche' {
            ImporterRegistre "> Alignement des boutons de la barre des tâches à gauche..." "Align_Taskbar_Left.reg"
            continue
        }
        'MasquerRechercheBarre' {
            ImporterRegistre "> Masquage de l'icône de recherche de la barre des tâches..." "Hide_Search_Taskbar.reg"
            continue
        }
        'AfficherIconeRecherche' {
            ImporterRegistre "> Modification de la recherche de la barre des tâches en icône uniquement..." "Show_Search_Icon.reg"
            continue
        }
        'AfficherLabelRecherche' {
            ImporterRegistre "> Modification de la recherche de la barre des tâches en icône avec étiquette..." "Show_Search_Icon_And_Label.reg"
            continue
        }
        'AfficherBarreRecherche' {
            ImporterRegistre "> Modification de la recherche de la barre des tâches en boîte de recherche..." "Show_Search_Box.reg"
            continue
        }
        'MasquerVueTaches' {
            ImporterRegistre "> Masquage du bouton vue des tâches de la barre des tâches..." "Hide_Taskview_Taskbar.reg"
            continue
        }
        'DesactiverCopilot' {
            ImporterRegistre "> Désactivation et suppression de Windows Copilot..." "Disable_Copilot.reg"

            # Supprimer aussi le package de l'application pour Copilot
            $listeApps = 'Microsoft.Copilot'
            SupprimerApplications $listeApps
            continue
        }
        'DesactiverRappel' {
            ImporterRegistre "> Désactivation des instantanés Windows Recall..." "Disable_AI_Recall.reg"
            continue
        }
        {$_ -in "MasquerWidgets", "DesactiverWidgets"} {
            ImporterRegistre "> Désactivation du service des widgets et masquage de l'icône des widgets de la barre des tâches..." "Disable_Widgets_Taskbar.reg"
            continue
        }
        {$_ -in "MasquerChat", "DesactiverChat"} {
            ImporterRegistre "> Masquage de l'icône de discussion de la barre des tâches..." "Disable_Chat_Taskbar.reg"
            continue
        }
        'AfficherDossiersCache' {
            ImporterRegistre "> Affichage des fichiers, dossiers et lecteurs cachés..." "Show_Hidden_Folders.reg"
            continue
        }
        'AfficherExtensionsFichiers' {
            ImporterRegistre "> Activation des extensions de fichiers pour les types connus..." "Show_Extensions_For_Known_File_Types.reg"
            continue
        }
        'MasquerAccueil' {
            ImporterRegistre "> Masquage de la section Accueil du panneau latéral de l'Explorateur de fichiers..." "Hide_Home_from_Explorer.reg"
            continue
        }
        'MasquerGalerie' {
            ImporterRegistre "> Masquage de la section Galerie du panneau latéral de l'Explorateur de fichiers..." "Hide_Gallery_from_Explorer.reg"
            continue
        }
        'ExplorateurVersAccueil' {
            ImporterRegistre "> Modification de l'emplacement par défaut d'ouverture de l'Explorateur de fichiers vers 'Accueil..." "Launch_File_Explorer_To_Home.reg"
            continue
        }
        'ExplorateurVersCePC' {
            ImporterRegistre "> Modification de l'emplacement par défaut d'ouverture de l'Explorateur de fichiers vers 'Ce PC..." "Launch_File_Explorer_To_This_PC.reg"
            continue
        }
        'ExplorateurVersTelechargements' {
            ImporterRegistre "> Modification de l'emplacement par défaut d'ouverture de l'Explorateur de fichiers vers 'Téléchargements..." "Launch_File_Explorer_To_Downloads.reg"
            continue
        }
        'ExplorateurVersOneDrive' {
            ImporterRegistre "> Modification de l'emplacement par défaut d'ouverture de l'Explorateur de fichiers vers 'OneDrive..." "Launch_File_Explorer_To_OneDrive.reg"
            continue
        }
        'MasquerLecteursDupliques' {
            ImporterRegistre "> Masquage des entrées de lecteurs amovibles en double du panneau latéral de l'Explorateur de fichiers..." "Hide_duplicate_removable_drives_from_navigation_pane_of_File_Explorer.reg"
            continue
        }
        {$_ -in "MasquerOnedrive", "DesactiverOnedrive"} {
            ImporterRegistre "> Masquage du dossier OneDrive du panneau latéral de l'Explorateur de fichiers..." "Hide_Onedrive_Folder.reg"
            continue
        }
        {$_ -in "Masquer3dObjects", "Desactiver3dObjects"} {
            ImporterRegistre "> Masquage du dossier Objets 3D du panneau latéral de l'Explorateur de fichiers..." "Hide_3D_Objects_Folder.reg"
            continue
        }
        {$_ -in "MasquerMusique", "DesactiverMusique"} {
            ImporterRegistre "> Masquage du dossier Musique du panneau latéral de l'Explorateur de fichiers..." "Hide_Music_folder.reg"
            continue
        }
        {$_ -in "MasquerInclueBibliotheque", "DesactiverInclueBibliotheque"} {
            ImporterRegistre "> Masquage de 'Inclure dans la bibliothèque' dans le menu contextuel..." "Disable_Include_in_library_from_context_menu.reg"
            continue
        }
        {$_ -in "MasquerDonnerAcces", "DesactiverDonnerAcces"} {
            ImporterRegistre "> Masquage de 'Donner l'accès à' dans le menu contextuel..." "Disable_Give_access_to_context_menu.reg"
            continue
        }
        {$_ -in "MasquerPartage", "DesactiverPartage"} {
            ImporterRegistre "> Masquage de 'Partager' dans le menu contextuel..." "Disable_Share_from_context_menu.reg"
            continue
        }
    }

    RedemarrerExplorateur

    Write-Output ""
    Write-Output ""
    Write-Output ""
    Write-Output "Le script s'est terminé avec succès !"

    AttendreAppuiTouchePourQuitter
}
