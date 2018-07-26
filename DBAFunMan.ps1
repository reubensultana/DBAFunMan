param([String]$SettingsXMLFile = '')

# **************************************************
# DBA Function Manager
# **************************************************

<#
Options:
0. Exit
...
...
The rest are retrieved from the database
...
...
#>

# Global params
#$CurrentPath = $PSScriptRoot
$CurrentPath = Get-Location
. "$($CurrentPath)\Community_Functions.ps1"

# Import settings from config file
# Modified to allow for "Settings.xml" file as a script parameter
if ($SettingsXMLFile -eq "") {$SettingsXMLFile = "$CurrentPath\Settings.xml"}
if (Test-Path($SettingsXMLFile)) { [xml]$ConfigFile = Get-Content $SettingsXMLFile }
else {
    Write-Warning "Settings file could not be found in current location."
    Write-Warning "Kindly ensure that the current folder contains a valid ""Settings.xml"" file."
}

# UI
$WindowTitle = $ConfigFile.Settings.UI.WindowTitle
$Version = $ConfigFile.Settings.UI.Version
$BackgroundColor = $ConfigFile.Settings.UI.BackgroundColor
$ForegroundColor = $ConfigFile.Settings.UI.ForegroundColor
# DatabaseConnection
$ServerInstance = $ConfigFile.Settings.DatabaseConnection.ServerInstance
$Database = $ConfigFile.Settings.DatabaseConnection.Database
$BackupRoot = $ConfigFile.Settings.DatabaseConnection.BackupRoot
$QueryTimeout = $ConfigFile.Settings.DatabaseConnection.QueryTimeout
#Write-Output "WindowTitle={0}" -f $WindowTitle
#Write-Output "ServerInstance={0};Database={1};BackupRoot={2}" -f $ServerInstance,$Database,$BackupRoot
#Write-Output "BackgroundColor={0};ForegroundColor={1}" -f $BackgroundColor,$ForegroundColor
#Read-Host "Press any key to continue... "

$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$HostName = [System.Environment]::MachineName

# set properties on the console window
$console = $host.UI.RawUI

$console.WindowTitle = "$WindowTitle (v$Version) - $ServerInstance"
$console.BackgroundColor = $BackgroundColor
$console.ForegroundColor = $ForegroundColor
<#
# random colours :-)
$random = New-Object System.Random
switch ($random.Next(4)) {
0 {$console.BackgroundColor = "DarkMagenta"; $console.ForegroundColor = "White"}
1 {$console.BackgroundColor = "Black"; 	     $console.ForegroundColor = "Green"}
2 {$console.BackgroundColor = "Gray";        $console.ForegroundColor = "DarkBlue"}
3 {$console.BackgroundColor = "DarkGray";    $console.ForegroundColor = "DarkRed"}
4 {$console.BackgroundColor = "DarkCyan";    $console.ForegroundColor = "DarkYellow"}
}   #end switch
#>
$buffer = $console.BufferSize
$buffer.Width = 100
$buffer.Height = 2000
$console.BufferSize = $buffer

$size = $console.WindowSize
$size.Width = 100
$size.Height = 40
$console.WindowSize = $size
# end console window properties

#Exception setting "WindowSize": "Window cannot be wider than the screen buffer.

# array that will store the dynamic options
$script:ObjectArray = @()

Clear-Host

#------------------------------------------------------------# 

#AreYouSure function. Alows user to select y or n when asked to exit. Y exits and N returns to main menu.  
function AreYouSure {
    $areyousure = Read-Host "Are you sure you want to exit? (y/n)"
    if     ($areyousure -eq "y"){Clear-Host; Exit}
    elseif ($areyousure -eq "n"){Main-Menu}
    else {Write-Host -ForegroundColor Red "Invalid selection";
          AreYouSure
         }
}

#------------------------------------------------------------# 

function Write-Header {
    Write-Host "---------------------------------------------------------"
    Write-Host "    $WindowTitle - $ServerInstance"
    Write-Host ""
}

#------------------------------------------------------------# 

function Write-Footer {
    Write-Host ""
    Write-Host "    Running as $CurrentUser from $HostName"
    Write-Host "---------------------------------------------------------"
}

#------------------------------------------------------------# 

function Get-CommandList {
    # check if the array has been populated; the array is only filled and the database query executed once
    if ($script:ObjectArray.Count -eq 0) {
        # fetch list from the database
        $GetCommandList = "EXEC [Manager].[usp_GetCommandList];"

        # populate array by converting the DataTable output from Invoke-Sqlcmd2 and piping the result to the array
        $DBResults = @($(Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $GetCommandList -As DataTable -QueryTimeout $QueryTimeout) | SELECT RowNumber, CommandName, CommandRef)

        # build the object array
        foreach ($ArrayItem in $DBResults) { 
            # create an array of objects
            $Object1 = New-Object System.Object
            
            $Object1 | Add-Member -type NoteProperty -name Number -Value $($ArrayItem.RowNumber)
            $Object1 | Add-Member -type NoteProperty -name Name -Value $($ArrayItem.CommandName)
            $Object1 | Add-Member -type NoteProperty -name Value -Value $($ArrayItem.CommandRef)

            $script:ObjectArray += $Object1
        }
    }
    # output array contents to screen
    [int]$ObjectNumber = 0
    [string]$ObjectName = ""
    [string]$ObjectValue = ""

    foreach ($Object in $script:ObjectArray) {
        $ObjectNumber = $Object.Number
        $ObjectName = $Object.Name
        $ObjectValue = $Object.Value
        Write-Host "    $ObjectNumber. $ObjectName"
    }
}

#------------------------------------------------------------# 

function Execute-Command( [string] $CommandRef ) {
    $Command = $script:ObjectArray.Get($($CommandRef-1)).Value
    #Write-host "Command = $Command"

    # fetch list from the database
    $ExecuteCommand = $("EXEC [Manager].[usp_ExecuteCommand] '{0}';" -f $Command)

    try {
        # populate array by converting the DataTable output from Invoke-Sqlcmd2 and piping the result to the array
        Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $ExecuteCommand -Verbose -QueryTimeout $QueryTimeout
    }
    catch {
        $ex = $_.Exception 
        Write-Error "$ex.Message" 
    }
}

#------------------------------------------------------------# 

#Main-Menu function. Contains the screen output for the menu and waits for and handles user input.  
function Main-Menu {
    Clear-Host
    Write-Header
    
    Write-Host "    0. Exit"
    
    Get-CommandList
    $ItemCount = $script:ObjectArray.Count

    Write-Footer
    [int]$answer = Read-Host "Please choose an option"

    if     ($answer -eq 0) {AreYouSure}
    elseif (($answer -gt 0) -and ($answer -le $ItemCount)) {Execute-Command($answer); Read-Host "Press any key to continue... " ; Main-Menu}
    else { Write-Warning "Invalid item selected"; Read-Host "Press any key to continue... " ; Main-Menu }
}

#------------------------------------------------------------# 

if ($SettingsXMLFile -ne "") { Main-Menu }
