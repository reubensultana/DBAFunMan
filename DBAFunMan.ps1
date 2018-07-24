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
[xml]$ConfigFile = Get-Content "$($CurrentPath)\Settings.xml"
# Note to self: Modify to allow for "Settings.xml" file as a script parameter

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
#Pause

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
$size = $console.WindowSize
$size.Width = 100
$size.Height = 40
$console.WindowSize = $size

$buffer = $console.BufferSize
$buffer.Width = 100
$buffer.Height = 2000
$console.BufferSize = $buffer
# end console window properties

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
    Write-host "Command = $Command"

    # fetch list from the database
    $ExecuteCommand = $("EXEC [Manager].[usp_ExecuteCommand] '{0}';" -f $Command)

    # populate array by converting the DataTable output from Invoke-Sqlcmd2 and piping the result to the array
    Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Database $Database -Query $ExecuteCommand -Verbose -QueryTimeout $QueryTimeout
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
    $answer = Read-Host "Please choose an option"

    if     ($answer -eq 0) {AreYouSure}
    elseif (($answer -gt 0) -and ($answer -le $ItemCount)) {Execute-Command($answer); Pause; Main-Menu}
    else { Write-Warning "Invalid item selected"; Pause; Main-Menu }
}

#------------------------------------------------------------# 

Main-Menu
