File: README.TXT for Windows 11 Debloater Tool (Version 2.0.6) from www.FreeTimeTech.com
Based on 2 PowerShell Scripts (1) Chris Titus Tech GitHub PowerShell Scripts (2020-24): https://github.com/ChrisTitusTech/win10script
and (2) farag2 Sophia Script for Windows GitHub PowerShell Scripts (2024): https://github.com/farag2/Sophia-Script-for-Windows

►Link: https://freetimetech.com/windows-11-debloater-tool-debloat-gui/
►YouTube: Coming Soon! But similar to: https://www.youtube.com/watch?v=3KTRS1RpBmg

Check our Windows 10 Debloater from www.FreeTimeTech.com website: 
►Link: http://freetimetech.com/windows-10-clean-up-debloat-tool-by-ftt/

Check our full GUI (C#+WPF) version called 'SophiApp' on GitHub:
►Link: https://github.com/Sophia-Community/SophiApp
This other version is made in collaboration with farag2 (Dmitry Nefedov) and Inestic (Dmitry Demin).

Check our other version of Windows 10/11 Debloater called 'Sophia Script for Windows' on BenchTweakGaming.com website: 
►Link: https://benchtweakgaming.com/2020/10/27/windows-10-debloat-tool/
This other version is made in collaboration with farag2 (Dmitry Nefedov) and Inestic (Dmitry Demin).

UPDATE v2.0.6
-------------
Added ToolTips for Windows Apps in English, Fixed bugs

UPDATE v2.0.5
-------------
Added UA, CZ, TH and ID languages

UPDATE v2.0.4
-------------
Fixed bugs

UPDATE v2.0.3
-------------
Added more 3rd Party. Fixed bugs

UPDATE v2.0.2
-------------
Added Search tab for Fine-Tuning Debloater. Search now searches ToolTips too including radiobutton name. ToolTips for Advanced
Debloater. Fixed bugs

UPDATE v2.0.1
-------------
Added 'Fix Winget' menu item in 'Extra' menu to fix Winget not working runs (Config/extra/fixwinget.ps1), Fixed bugs

UPDATE v2.0.0
-------------
Redesign using https://github.com/Kinnara/ModernWpf, More 3rd Party and Search 3rd Party, Updated Fine-Tuning Debloater radiobuttons

UPDATE v1.9.1
-------------
Add more option for Fine-Tuning Debloater, added Edit mode for Advanced Debloater and fixed some bugs

UPDATE v1.9
-----------
Open PS1 files for Fine-Tuning Debloater selections

UPDATE v1.8
-----------
Advanced Debloater tab for basic fine-tuning, Removed O&O Shutup, fixed bugs in V1.7, Rearranged files and folders

UPDATE v1.7 (Removed)
-----------
Added list counter to summary and output for EZ Debloater, Added more 3rd Party radiobuttons, Added Install radiobuttons for 
Windows UWP Apps, Update functions, Cleaned up code

UPDATE v1.6
-----------
Added UI translation for 17 languages, EZ Debloater is now has two modes: 'Normal' and 'Edit'. 'Normal' shows the summarised 
selected script and 'Edit' is the PowerShell script

UPDATE v1.5
-----------
Added ToolTip languages: Dutch, Greek, Arabic and Turkish

UPDATE v1.4
-----------
Added ToolTip languages: German, Italian, and Romanian. Folder called 'Localizations' created to store all tooltips.txt files

UPDATE v1.3
-----------
Added ToolTip languages: Portuguese, Japanese and Korean, Fixed some bugs

UPDATE v1.2
-----------
Added ToolTip languages: Russian, Spanish, French, Chinese, Polish and Vietnamese

UPDATE v1.1
-----------
Toggle mode added to hide 'Read/Edit' button beside each radiobutton, Update EZ Debloater - Essential Tweaks, More 3rd 
Party, Updates and Fixes

INTRODUCTION
------------
Please read this document to understand how to use this program.

There is a 'EZ Debloater' tab page as main front of the program. It allows you to run common 
PowerShell scripts to debloat Windows 11. There are several restore/undo scripts you can choose
from after if you choose. Some buttons in the 'EZ Debloater' tab page has ToolTips (message popups)
for more information.

Each button has a script you can see to modify if you want before running.

There is a 'Advanced Debloater' tab page to basic fine-tuning debloating from 4 presets. There is
also a 'Undo All' to reset back to defaults. You can 'See Script' to see your selections.

The 'Fine-Tuning Debloater' tab allows you to create a PowerShell script file that you can run to finely
tweak/debloat Windows 11. A restore point is created in the beginning so you can safely use this tool.

The options are arranged in different tabs and there is a preset 'Debloat Preset' in the 'Options'
menu. You can choose a preset first and add your own choices. There is a 'Windows Default Preset' to 
revert back to original Windows Default settings. You can also create your own radiobutton presets and 
share. There is also a 'Opposite' menu choice to select the alternate radiobutton choices. This is good
to revert the changes in a script to run.

In 'Normal' mode, the 'EZ Debloater' textbox that shows the script summarized. Switch to 'Edit' mode 
to see the full PowerShell script.

In 'Edit' mode for 'Advanced Debloater', you get a 'RE' button beside each checkbox selection to 
'Read/Edit' the PowerShell script for each checkbox.

Also in 'Edit' mode for 'Fine-Tuning Debloater', you can have a button beside each radiobutton 
(labeled with a first single letter of the radiobutton) to 'Read/Edit' the PowerShell script for each 
radiobutton.

You can directly run the PowerShell script from the program after creating your script.
Click the 'Run Powershell' button after you fill in the radiobutton choices and click the 
'Output PowerShell' button. The "Run PowerShell" button creates a PowerShell script called
'runpsscript.ps1' in the same directory and runs it.

OR save the PowerShell script as whatever you wish and run it using the following commands.

But first, launch PowerShell (Run as administrator) and navigate to where your script is.

1. Set-ExecutionPolicy Unrestricted 
2. ./YOUR_SCRIPT_NAME.ps1

YOUR_SCRIPT_NAME is the name of the PowerShell script you just saved.

FILES
-----
►Windows11Debloater.exe : The GUI program.

EZ Debloater Folder
-------------------
►ezdebloater.txt : 	contains the PowerShell scripts for the 'EZDebloater' tab page.

Advanced Debloater Folder
-------------------------
►advanceddebloater.txt : contains the PowerShell scripts for the ‘Advanced Debloater’ tab page.
►desktoppreset.txt : 	contains the ‘Desktop’ preset for ‘Advanced Debloater’.
►laptoppreset.txt : 	contains the ‘Laptop’ preset for ‘Advanced Debloater’.
►minimalpreset.txt : 	contains the ‘Minimal’ preset for ‘Advanced Debloater’.
►vmpreset.txt : 	contains the ‘Virtual Machine’ preset for ‘Advanced Debloater’.

Fine-Tuning Debloater Folder
----------------------------
►data.txt : 	contains the options(function names) to select from (usually only 2 
		options that something is Enable or Disable). Notice the sections 
		and how a comma and double quotes separate them. The last option in 
		each section does not have a comma. Add or substract from the set.
►functions.txt : contains the complete functions named from data.txt. These are the 
		commands that get run. Add or substract from the set.
►debloatpreset.txt : contains debloat preset. Click this option from the menu in program.
►defaultpreset.txt : contains default preset. Click this option from the menu in program.

Extra Folder
------------
►fixwinget.ps1 : contains the PowerShell script to fix winget.

Localizations – Translations
----------------------------
►tooltips.txt :	Contains ToolTips for each radiobutton option. Many languages so far.
►ui.txt :	Contains UI text for each UI element/control. Many languages so far.

►README.txt : This text file for information and link resources.