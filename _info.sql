/* ****************************************** */
/* ********** DBA Function Manager ********** */
/* ****************************************** */

/*
This is a small TextUI application written in PowerShell and TSQL which works 
with most SQL Server 2008 and later versions (none of the code is dependent on 
a specific Version or Edition).

Requirements for this application/utility/script originated from DBAs having to
be available fro menial tasks, such as running or re-running multiple jobs, 
taking manual backups, etc. which are a huge time-waster when you're trying to 
prevent things from falling over.

A method to allow Developers to carry out functions which are normally run by a
DBA, or a member of the sysadmin fixed server role, had to be found. The 
solution would not have to compromise security by granting Developers elevated 
rights, and it would not have to be susceptible to SQL Injection.

In this regard, the solution was designed with security in mind, not as an 
afterthought. And because we didn't want to allow Developers the opportunity to
hack the code and change the functionality (they can still do this) permissions
have been limited to EXECUTE on the only two stored procedures required for 
basic functionality.

The solution elevates permissions using WITH EXECUTE AS OWNER within the stored 
procedure, then execution outside the database (at server level) is done by 
enabling the TRUSTWORTHY database option.

This application is composed of the following files:
    > _info.sql (this file)
    > Community_Functions.ps1
    > DBAFunMan.ps1
    > Settings.xml

The database deployment is contained within the "DBAFunMan.sql" file.  The 
script will create some sample configuration however this can be cleared and 
defined according to your requirements using the below scripts.
*/

-- grant access to the database
-- OPTION 1: a single AD User
USE [master];
CREATE LOGIN [AD\Login1] FROM WINDOWS;
USE [DBAToolbox];
CREATE USER [AD\Login1] FOR LOGIN [AD\Login1];
ALTER ROLE [ManagerApp] ADD MEMBER [AD\Login1];

-- OPTION 2: an AD Group (easier)
USE [master];
CREATE LOGIN [AD\MyAdGroup] FROM WINDOWS;
USE [DBAToolbox];
CREATE USER [AD\MyAdGroup] FOR LOGIN [AD\MyAdGroup];
ALTER ROLE [ManagerApp] ADD MEMBER [AD\MyAdGroup];

-- create an application user
INSERT INTO [Manager].[SystemUsers] ([UserName],[RecordStatus],[RecordCreated])
VALUES ('AD\Login1', DEFAULT, DEFAULT);

-- create an application group
INSERT INTO [Manager].[SystemGroups]([GroupName],[RecordStatus],[RecordCreated])
VALUES ('My New Group', DEFAULT, DEFAULT);

-- add an application user to an application group
DECLARE @UserName nvarchar(128) = N'AD\Login1';
DECLARE @GroupName nvarchar(128) = N'My New Group';
INSERT INTO [Manager].[UserGroups]([UserID],[GroupID],[RecordStatus],[RecordCreated])
VALUES (
    (SELECT [UserID] FROM [Manager].[SystemUsers] WHERE [UserName] = @UserName), 
    (SELECT [GroupID] FROM [Manager].[SystemGroups] WHERE [GroupName] = @GroupName), 
    DEFAULT, DEFAULT
);

-- create a new command
-- NOTES:   The [ScriptName] column will be what will be shown to the end-user in the Menu items
--          The [ScriptReference] column is an auto-generated GUID which is used to identify the command/script
INSERT INTO [Manager].[Command]([ScriptName],[ScriptReference],[ExecuteScript],[RecordStatus],[RecordCreated])
VALUES ('Command Friendly Name', DEFAULT, N'-- Valid and Tested TSQL Command/s', DEFAULT, DEFAULT);

-- grant an application group permissions to run a command
DECLARE @GroupName nvarchar(128) = N'My New Group';
DECLARE @CommandName nvarchar(255) = N'Command Friendly Name';
INSERT INTO [Manager].[GroupCommands]([GroupID],[CommandID],[RecordStatus],[RecordCreated])
VALUES (
    (SELECT [GroupID] FROM [Manager].[SystemGroups] WHERE [GroupName] = @GroupName), 
    (SELECT [CommandID] FROM [Manager].[Command] WHERE [ScriptName] = @CommandName), 
    DEFAULT, DEFAULT
);

/*
Once the above has been set up just modify the "ServerInstance" value in the 
"Settings.xml" file, open a PowerShell window, then run the "DBAFunMan.ps1" 
script.  The Menu items will be built dynamically according to the what the 
Windows account was granted, if everything was set up correctly.

Please do not hesitate to contact me for assistance, to report bugs, or for 
potential enhancements or improvements.

Thank you.
*/