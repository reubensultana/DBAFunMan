USE [DBAToolbox]
GO

--------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE [name] = 'Manager')
    EXEC sp_executesql N'CREATE SCHEMA [Manager] AUTHORIZATION [dbo];'
GO

--------------------------------------------------
-- Reset Objects
/*
ALTER TABLE [Manager].[UserGroups] DROP CONSTRAINT FK_ManagerUserGroups_ManagerSystemUsers;
ALTER TABLE [Manager].[UserGroups] DROP CONSTRAINT FK_ManagerUserGroups_SystemGroups;
ALTER TABLE [Manager].[GroupCommands] DROP CONSTRAINT FK_ManagerGroupCommands_ManagerSystemGroups;
ALTER TABLE [Manager].[GroupCommands] DROP CONSTRAINT FK_ManagerGroupCommands_ManagerCommand;
GO

DROP PROCEDURE [Manager].[usp_GetCommandList];
DROP PROCEDURE [Manager].[usp_ExecuteCommand];
DROP FUNCTION [Manager].[ufn_UserHasAccess]

DROP TABLE [Manager].[UserGroups];
DROP TABLE [Manager].[GroupCommands];

DROP TABLE [Manager].[SystemUsers];
DROP TABLE [Manager].[SystemGroups];

DROP TABLE [Manager].[Command];
DROP TABLE [Manager].[CommandLog];
*/

--------------------------------------------------
-- TABLE: Users
IF OBJECT_ID('[Manager].[SystemUsers]') IS NOT NULL
DROP TABLE [Manager].[SystemUsers]
GO

CREATE TABLE [Manager].[SystemUsers] (
    [UserID] int IDENTITY (1,1) NOT NULL,
    [UserName] nvarchar(128) NOT NULL,
    [RecordStatus] char(1) NOT NULL,
    [RecordCreated] datetime2(0) NOT NULL
);
GO

-- clustered index on [UserID]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Manager].[SystemUsers]') AND name = N'PK_ManagerSystemUsers')
ALTER TABLE [Manager].[SystemUsers]
ADD  CONSTRAINT [PK_ManagerSystemUsers] PRIMARY KEY CLUSTERED ([UserID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = OFF, 
    ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100)
GO

-- default constraint on [RecordStatus] = "A"
ALTER TABLE [Manager].[SystemUsers] ADD CONSTRAINT
	DF_ManagerSystemUsers_RecordStatus DEFAULT 'A' FOR [RecordStatus]
GO
-- check constraint on [RecordStatus] - allowed values "A", "D", "H"
ALTER TABLE [Manager].[SystemUsers] ADD CONSTRAINT
	CK_ManagerSystemUsers_RecordStatus CHECK ([RecordStatus] LIKE '[ADH]')
GO

-- default constraint on [RecordCreated] = CURRENT_TIMESTAMP
ALTER TABLE [Manager].[SystemUsers] ADD CONSTRAINT
	DF_ManagerSystemUsers_RecordCreated DEFAULT CURRENT_TIMESTAMP FOR [RecordCreated]
GO

--------------------------------------------------
-- TABLE: Groups (Permissions Sets)
IF OBJECT_ID('[Manager].[SystemGroups]') IS NOT NULL
DROP TABLE [Manager].[SystemGroups]
GO

CREATE TABLE [Manager].[SystemGroups] (
    [GroupID] int IDENTITY (1,1) NOT NULL,
    [GroupName] nvarchar(128) NOT NULL, -- groups are collections of permissions; linking multiple Users to Commands
    [RecordStatus] char(1) NOT NULL,
    [RecordCreated] datetime2(0) NOT NULL
);
GO

-- clustered index on [GroupsID]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Manager].[SystemGroups]') AND name = N'PK_ManagerSystemGroups')
ALTER TABLE [Manager].[SystemGroups]
ADD  CONSTRAINT [PK_ManagerSystemGroups] PRIMARY KEY CLUSTERED ([GroupID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = OFF, 
    ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100)
GO

-- default constraint on [RecordStatus] = "A"
ALTER TABLE [Manager].[SystemGroups] ADD CONSTRAINT
	DF_ManagerSystemGroups_RecordStatus DEFAULT 'A' FOR [RecordStatus]
GO
-- check constraint on [RecordStatus] - allowed values "A", "D", "H"
ALTER TABLE [Manager].[SystemGroups] ADD CONSTRAINT
	CK_ManagerSystemGroups_RecordStatus CHECK ([RecordStatus] LIKE '[ADH]')
GO

-- default constraint on [RecordCreated] = CURRENT_TIMESTAMP
ALTER TABLE [Manager].[SystemGroups] ADD CONSTRAINT
	DF_ManagerSystemGroups_RecordCreated DEFAULT CURRENT_TIMESTAMP FOR [RecordCreated]
GO

--------------------------------------------------
-- TABLE: User-Groups (Memebership); allows many-to-many relationship
IF OBJECT_ID('[Manager].[UserGroups]') IS NOT NULL
DROP TABLE [Manager].[UserGroups]
GO

CREATE TABLE [Manager].[UserGroups] (
    [UserGroupID] int IDENTITY (1,1) NOT NULL,
    [UserID] int NOT NULL,
    [GroupID] int NOT NULL,
    [RecordStatus] char(1) NOT NULL,
    [RecordCreated] datetime2(0) NOT NULL
);
GO

-- clustered index on [UserGroupID]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Manager].[UserGroups]') AND name = N'PK_ManagerUserGroups')
ALTER TABLE [Manager].[UserGroups]
ADD  CONSTRAINT [PK_ManagerUserGroups] PRIMARY KEY CLUSTERED ([UserGroupID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = OFF, 
    ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100)
GO

-- default constraint on [RecordStatus] = "A"
ALTER TABLE [Manager].[UserGroups] ADD CONSTRAINT
	DF_ManagerUserGroups_RecordStatus DEFAULT 'A' FOR [RecordStatus]
GO
-- check constraint on [RecordStatus] - allowed values "A", "D", "H"
ALTER TABLE [Manager].[UserGroups] ADD CONSTRAINT
	CK_ManagerUserGroups_RecordStatus CHECK ([RecordStatus] LIKE '[ADH]')
GO

-- default constraint on [RecordCreated] = CURRENT_TIMESTAMP
ALTER TABLE [Manager].[UserGroups] ADD CONSTRAINT
	DF_ManagerUserGroups_RecordCreated DEFAULT CURRENT_TIMESTAMP FOR [RecordCreated]
GO

-- foreign keys linking [Manager].[UserGroups] to [Manager].[SystemUsers] and [Manager].[SystemGroups]
ALTER TABLE [Manager].[UserGroups] ADD CONSTRAINT 
    FK_ManagerUserGroups_ManagerSystemUsers FOREIGN KEY([UserID]) REFERENCES [Manager].[SystemUsers] ([UserID])
GO
ALTER TABLE [Manager].[UserGroups] ADD CONSTRAINT 
    FK_ManagerUserGroups_SystemGroups FOREIGN KEY([GroupID]) REFERENCES [Manager].[SystemGroups] ([GroupID])
GO

--------------------------------------------------
-- TABLE: Commands (which can be executed)
IF OBJECT_ID('[Manager].[Command]') IS NOT NULL
DROP TABLE [Manager].[Command]
GO

CREATE TABLE [Manager].[Command] (
    [CommandID] int IDENTITY (1,1) NOT NULL,
    [ScriptName] nvarchar(255) NOT NULL,
    [ScriptReference] uniqueidentifier NOT NULL,
    [ExecuteScript] nvarchar(max) NOT NULL,
    [RecordStatus] char(1) NOT NULL,
    [RecordCreated] datetime2(0) NOT NULL
);
GO

-- clustered index on [CommandID]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Manager].[Command]') AND name = N'PK_ManagerCommand')
ALTER TABLE [Manager].[Command]
ADD  CONSTRAINT [PK_ManagerCommand] PRIMARY KEY CLUSTERED ([CommandID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = OFF, 
    ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100)
GO

-- default constraint on [RecordStatus] = "A"
ALTER TABLE [Manager].[Command] ADD CONSTRAINT
	DF_ManagerCommand_RecordStatus DEFAULT 'A' FOR [RecordStatus]
GO
-- check constraint on [RecordStatus] - allowed values "A", "D", "H"
ALTER TABLE [Manager].[Command] ADD CONSTRAINT
	CK_ManagerCommand_RecordStatus CHECK ([RecordStatus] LIKE '[ADH]')
GO

-- default constraint on [RecordCreated] = CURRENT_TIMESTAMP
ALTER TABLE [Manager].[Command] ADD CONSTRAINT
	DF_ManagerCommand_RecordCreated DEFAULT CURRENT_TIMESTAMP FOR [RecordCreated]
GO

-- default constraint on [ScriptReference] = NEWID()
ALTER TABLE [Manager].[Command] ADD CONSTRAINT
	DF_ManagerCommand_ScriptReference DEFAULT NEWID() FOR [ScriptReference]
GO

-- nonclustered index on [ScriptReference] to enforce uniqueness
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Manager].[Command]') AND name = N'IDX_ManagerCommand_ScriptReference')
CREATE UNIQUE NONCLUSTERED INDEX [IDX_ManagerCommand_ScriptReference]
    ON [Manager].[Command] ( [ScriptReference] ASC )
WITH (
    PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, 
    ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100)
GO

--------------------------------------------------
-- TABLE: Group-Commands (which Group can execute which Command/s); allows many-to-many relationship
IF OBJECT_ID('[Manager].[GroupCommands]') IS NOT NULL
DROP TABLE [Manager].[GroupCommands]
GO

CREATE TABLE [Manager].[GroupCommands] (
    [GroupCommandID] int IDENTITY (1,1) NOT NULL,
    [GroupID] int NOT NULL,
    [CommandID] int NOT NULL,
    [RecordStatus] char(1) NOT NULL,
    [RecordCreated] datetime2(0) NOT NULL
);
GO

-- clustered index on [CommandID]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Manager].[GroupCommands]') AND name = N'PK_ManagerGroupCommands')
ALTER TABLE [Manager].[GroupCommands]
ADD  CONSTRAINT [PK_ManagerGroupCommands] PRIMARY KEY CLUSTERED ([GroupCommandID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = OFF, 
    ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100)
GO

-- default constraint on [RecordStatus] = "A"
ALTER TABLE [Manager].[GroupCommands] ADD CONSTRAINT
	DF_ManagerGroupCommands_RecordStatus DEFAULT 'A' FOR [RecordStatus]
GO
-- check constraint on [RecordStatus] - allowed values "A", "D", "H"
ALTER TABLE [Manager].[GroupCommands] ADD CONSTRAINT
	CK_ManagerGroupCommands_RecordStatus CHECK ([RecordStatus] LIKE '[ADH]')
GO

-- default constraint on [RecordCreated] = CURRENT_TIMESTAMP
ALTER TABLE [Manager].[GroupCommands] ADD CONSTRAINT
	DF_ManagerGroupCommands_RecordCreated DEFAULT CURRENT_TIMESTAMP FOR [RecordCreated]
GO

-- foreign keys linking [Manager].[GroupCommands] to [Manager].[SystemGroups] and [Manager].[Command]
ALTER TABLE [Manager].[GroupCommands] ADD CONSTRAINT 
    FK_ManagerGroupCommands_ManagerSystemGroups FOREIGN KEY([GroupID]) REFERENCES [Manager].[SystemGroups] ([GroupID])
GO
ALTER TABLE [Manager].[GroupCommands] ADD CONSTRAINT 
    FK_ManagerGroupCommands_ManagerCommand FOREIGN KEY([CommandID]) REFERENCES [Manager].[Command] ([CommandID])
GO

--------------------------------------------------
-- TABLE: Command Log (logging the who, when and which of commands that have been executed)
IF OBJECT_ID('[Manager].[CommandLog]') IS NOT NULL
DROP TABLE [Manager].[CommandLog]
GO

CREATE TABLE [Manager].[CommandLog] (
    [CommandLogID] int IDENTITY (1,1) NOT NULL,
    [CommandID] int NOT NULL, -- copied from the source table as reference
    [ScriptName] nvarchar(255) NOT NULL,
    [ScriptReference] uniqueidentifier NOT NULL,
    [ExecuteScript] nvarchar(max) NOT NULL, -- the actual script executed
    [UserName] nvarchar(128) NOT NULL, -- who executed the command
    [StartTime] datetime2(0) NOT NULL, -- script execution started
    [EndTime] datetime2(0) NOT NULL, -- script execution ended (in the case of SQL Agent jobs this will be same as [StartTime] due to queing mechanism)
    [RecordStatus] char(1) NOT NULL,
    [RecordCreated] datetime2(0) NOT NULL
);
GO

-- clustered index on [CommandID]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Manager].[CommandLog]') AND name = N'PK_ManagerCommandLog')
ALTER TABLE [Manager].[CommandLog]
ADD  CONSTRAINT [PK_ManagerCommandLog] PRIMARY KEY CLUSTERED ([CommandLogID] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = OFF, 
    ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100)
GO

-- default constraint on [RecordStatus] = "A"
ALTER TABLE [Manager].[CommandLog] ADD CONSTRAINT
	DF_ManagerCommandLog_RecordStatus DEFAULT 'A' FOR [RecordStatus]
GO
-- check constraint on [RecordStatus] - allowed values "A", "D", "H"
ALTER TABLE [Manager].[CommandLog] ADD CONSTRAINT
	CK_ManagerCommandLog_RecordStatus CHECK ([RecordStatus] LIKE '[ADH]')
GO

-- default constraint on [RecordCreated] = CURRENT_TIMESTAMP
ALTER TABLE [Manager].[CommandLog] ADD CONSTRAINT
	DF_ManagerCommandLog_RecordCreated DEFAULT CURRENT_TIMESTAMP FOR [RecordCreated]
GO

--------------------------------------------------
-- Sample Data
SET NOCOUNT ON;

INSERT INTO [Manager].[SystemUsers] ([UserName],[RecordStatus],[RecordCreated])
VALUES
    ('AD\Login1', DEFAULT, DEFAULT),
    ('AD\Login2', DEFAULT, DEFAULT)
GO

INSERT INTO [Manager].[SystemGroups]([GroupName],[RecordStatus],[RecordCreated])
VALUES
    ('Admin Group', DEFAULT, DEFAULT),
    ('Less-privileged Group', DEFAULT, DEFAULT)
GO

INSERT INTO [Manager].[UserGroups]([UserID],[GroupID],[RecordStatus],[RecordCreated])
VALUES
    (1, 1, DEFAULT, DEFAULT),
    (2, 2, DEFAULT, DEFAULT),
    (1, 2, DEFAULT, DEFAULT)
GO

INSERT INTO [Manager].[Command]([ScriptName],[ScriptReference],[ExecuteScript],[RecordStatus],[RecordCreated])
VALUES
    ('Get Current Timestamp', DEFAULT, N'PRINT CURRENT_TIMESTAMP;', DEFAULT, DEFAULT),
    ('Get Current User', DEFAULT, N'PRINT ORIGINAL_LOGIN();', DEFAULT, DEFAULT),
    ('Get Current Timestamp with Delay', DEFAULT, N'WAITFOR DELAY ''00:00:05''; PRINT CURRENT_TIMESTAMP;', DEFAULT, DEFAULT),
    ('Run IndexOptimize on DBAToolbox', DEFAULT, 'EXECUTE [DBAToolbox].[dbo].[IndexOptimize] @Databases = ''DBAToolbox'';', DEFAULT, DEFAULT);
GO

INSERT INTO [Manager].[GroupCommands]([GroupID],[CommandID],[RecordStatus],[RecordCreated])
VALUES
    (1, 1, DEFAULT, DEFAULT),
    (1, 2, DEFAULT, DEFAULT),
    (2, 1, DEFAULT, DEFAULT),
    (1, 3, DEFAULT, DEFAULT),
    (1, 4, DEFAULT, DEFAULT),
    (2, 4, DEFAULT, DEFAULT);
GO


INSERT INTO [Manager].[Command]([ScriptName],[ScriptReference],[ExecuteScript],[RecordStatus],[RecordCreated])
VALUES
    ('DBA: Truncate Log without Retention', DEFAULT, N'EXEC [msdb].[dbo].[sp_start_job] @job_name=''DBA: Truncate Log without Retention'';', DEFAULT, DEFAULT);
GO
INSERT INTO [Manager].[GroupCommands]([GroupID],[CommandID],[RecordStatus],[RecordCreated])
VALUES
    (2, 5, DEFAULT, DEFAULT)
GO

-- view sample data results
SELECT su.[UserID], su.[UserName], sg.[GroupID], sg.[GroupName]
FROM [Manager].[UserGroups] ug
    INNER JOIN [Manager].[SystemUsers] su ON ug.[UserID] = su.[UserID]
    INNER JOIN [Manager].[SystemGroups] sg ON ug.[GroupID] = sg.[GroupID]
WHERE (ug.[RecordStatus] = 'A' AND su.[RecordStatus] = 'A' AND sg.[RecordStatus] = 'A')
ORDER BY sg.[GroupName],su.[UserName]
GO

SELECT c.[ScriptName], c.[ScriptReference], c.[ExecuteScript],
    sg.[GroupName], su.[UserName]
FROM [Manager].[GroupCommands] gc
    INNER JOIN [Manager].[Command] c ON gc.[CommandID] = c.[CommandID]
    INNER JOIN [Manager].[SystemGroups] sg ON gc.[GroupID] = sg.[GroupID]
    INNER JOIN [Manager].[UserGroups] ug ON ug.[GroupID] = gc.[GroupID]
    INNER JOIN [Manager].[SystemUsers] su ON ug.[UserID] = su.[UserID]
WHERE (gc.[RecordStatus] = 'A' AND c.[RecordStatus] = 'A' AND ug.[RecordStatus] = 'A' AND su.[RecordStatus] = 'A' AND sg.[RecordStatus] = 'A')
ORDER BY sg.[GroupName],su.[UserName], c.[ScriptName]
GO


--------------------------------------------------
-- FUNCTION: Check if the Current User is a valis application User
IF OBJECT_ID('[Manager].[ufn_UserHasAccess]') IS NOT NULL
DROP FUNCTION [Manager].[ufn_UserHasAccess]
GO

CREATE FUNCTION [Manager].[ufn_UserHasAccess] (
    @UserName nvarchar(128) )
RETURNS bit
WITH EXECUTE AS CALLER
AS
BEGIN
    -- always returns the highest value first
    RETURN (
        SELECT TOP(1) CAST([Exists] AS bit) 
        FROM (
            SELECT 1 AS [Exists] FROM [Manager].[SystemUsers] WHERE [UserName] = @UserName 
            UNION ALL 
            SELECT 0 ) a
        ORDER BY 1 DESC
        );
END
GO

--------------------------------------------------
-- PROCEDURE: Log the Command executed by the Current User
IF OBJECT_ID('[Manager].[usp_LogCommand]') IS NOT NULL
DROP PROCEDURE [Manager].[usp_LogCommand]
GO

CREATE PROCEDURE [Manager].[usp_LogCommand]
    @CommandID int
    ,@ScriptName nvarchar(255)
    ,@ScriptReference uniqueidentifier
    ,@ExecuteScript nvarchar(max)
    ,@UserName nvarchar(128)
    ,@StartTime datetime2(0)
    ,@EndTime datetime2(0)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [Manager].[CommandLog] (
        [CommandID],[ScriptName],[ScriptReference],[ExecuteScript]
        ,[UserName],[StartTime],[EndTime],[RecordStatus],[RecordCreated]
     )
     VALUES (
        @CommandID,@ScriptName,@ScriptReference,@ExecuteScript
        ,@UserName,@StartTime,@EndTime,DEFAULT,DEFAULT )
END
GO
-- TODO: Error handling

--------------------------------------------------
-- PROCEDURE: Get list of Commands available for the Current User
IF OBJECT_ID('[Manager].[usp_GetCommandList]') IS NOT NULL
DROP PROCEDURE [Manager].[usp_GetCommandList]
GO

CREATE PROCEDURE [Manager].[usp_GetCommandList]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentLogin nvarchar(128) = ORIGINAL_LOGIN();

    -- check if the current login is a valid application User
    IF [Manager].[ufn_UserHasAccess] (@CurrentLogin) = 0
    BEGIN
        RAISERROR('The current user is not allowed to use this system.', 16, 1);
        RETURN -1;
    END
    ELSE
    BEGIN
        SELECT ROW_NUMBER() OVER(ORDER BY a.[CommandName]) AS [RowNumber], a.[CommandName], a.[CommandRef]
        FROM (
            SELECT DISTINCT -- using DISTINCT since a User can be a member of omore than one Group, and a Command can be linked to more than one Group
                c.[ScriptName] AS [CommandName], c.[ScriptReference] AS [CommandRef]
            FROM [Manager].[GroupCommands] gc
                INNER JOIN [Manager].[Command] c ON gc.[CommandID] = c.[CommandID]
                INNER JOIN [Manager].[SystemGroups] sg ON gc.[GroupID] = sg.[GroupID]
                INNER JOIN [Manager].[UserGroups] ug ON ug.[GroupID] = gc.[GroupID]
                INNER JOIN [Manager].[SystemUsers] su ON ug.[UserID] = su.[UserID]
            WHERE (gc.[RecordStatus] = 'A' AND c.[RecordStatus] = 'A' AND ug.[RecordStatus] = 'A' AND su.[RecordStatus] = 'A' AND sg.[RecordStatus] = 'A')
            AND su.[UserName] = @CurrentLogin
        ) a
        ORDER BY a.[CommandName] ASC;
    END
    RETURN 0;
END
GO
-- TEST: EXEC [Manager].[usp_GetCommandList]

--------------------------------------------------
-- PROCEDURE: Execute the Command selected by the User
IF OBJECT_ID('[Manager].[usp_ExecuteCommand]') IS NOT NULL
DROP PROCEDURE [Manager].[usp_ExecuteCommand]
GO

CREATE PROCEDURE [Manager].[usp_ExecuteCommand]
    @CommandRef uniqueidentifier
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentLogin nvarchar(128) = ORIGINAL_LOGIN();
    -- check if the current login is a valid application User
    IF [Manager].[ufn_UserHasAccess] (@CurrentLogin) = 0
    BEGIN
        RAISERROR('The current user is not allowed to use this system.', 16, 1);
        RETURN -1;
    END -- access check
    ELSE
    BEGIN
        DECLARE @CommandID int
            ,@ScriptName nvarchar(255)
            ,@ScriptReference uniqueidentifier
            ,@ExecuteScript nvarchar(max)
            ,@UserName nvarchar(128)
            ,@StartTime datetime2(0)
            ,@EndTime datetime2(0);

        -- set the values
        SELECT TOP(1) -- to make sure that only one record is returned
            @CommandID = c.[CommandID]
            ,@ScriptName = c.[ScriptName]
            ,@ExecuteScript = LTRIM(RTRIM(c.[ExecuteScript]))
        FROM [Manager].[GroupCommands] gc
            INNER JOIN [Manager].[Command] c ON gc.[CommandID] = c.[CommandID]
            INNER JOIN [Manager].[SystemGroups] sg ON gc.[GroupID] = sg.[GroupID]
            INNER JOIN [Manager].[UserGroups] ug ON ug.[GroupID] = gc.[GroupID]
            INNER JOIN [Manager].[SystemUsers] su ON ug.[UserID] = su.[UserID]
        WHERE (gc.[RecordStatus] = 'A' AND c.[RecordStatus] = 'A' AND ug.[RecordStatus] = 'A' AND su.[RecordStatus] = 'A' AND sg.[RecordStatus] = 'A')
        AND su.[UserName] = @CurrentLogin
        AND c.[ScriptReference] = @CommandRef
        ORDER BY [ScriptName] ASC;

        -- some checks, then execute
        IF (NULLIF(@ExecuteScript, N'') IS NOT NULL)
        BEGIN
            -- then execute main script
            SET @StartTime = CURRENT_TIMESTAMP;
            EXEC sp_executesql @ExecuteScript;
            SET @EndTime = CURRENT_TIMESTAMP;

            EXEC [Manager].[usp_LogCommand] @CommandID, @ScriptName, @CommandRef, @ExecuteScript, @CurrentLogin, @StartTime, @EndTime;
            RETURN 0;
        END -- checks
    END -- else
END
GO
-- TODO: Error handling

-- NOTE: Get valid values for @CommandRef from the [Manager].[Command] table.
-- TEST: EXEC [Manager].[usp_ExecuteCommand] @CommandRef = '965FF01A-46CF-4F00-9525-E46C3FD46695';
-- TEST: EXEC [Manager].[usp_ExecuteCommand] @CommandRef = '7EAE9D1C-4DDF-4A9D-82E4-E87F6F1241F2';
-- TEST: EXEC [Manager].[usp_ExecuteCommand] @CommandRef = '226CDC0D-D59F-450E-B1CC-2CC4282CF18A';


--------------------------------------------------
-- PERMISSIONS
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = N'ManagerApp' AND [type] = 'R')
    CREATE ROLE [ManagerApp] AUTHORIZATION [dbo]
GO
GRANT EXECUTE ON [Manager].[usp_GetCommandList] TO [ManagerApp]
GRANT EXECUTE ON [Manager].[usp_ExecuteCommand] TO [ManagerApp]
GO
-- NEXT: Add members to the role
/*
ALTER ROLE [ManagerApp] ADD MEMBER [AD\Login2]
GO
*/

--------------------------------------------------
USE [master]
GO

IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE [name] = 'DBAToolbox' AND is_trustworthy_on = 1)
ALTER DATABASE [DBAToolbox] SET TRUSTWORTHY ON
GO
