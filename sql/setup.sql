--this script is for database design purposes only

USE master

DROP DATABASE IF EXISTS CircuitWatchdog
GO

DECLARE @test int
SELECT @test = DB_ID('CircuitWatchdog')
IF @test IS NULL
BEGIN
	CREATE DATABASE CircuitWatchdog COLLATE SQL_Latin1_General_CP1_CI_AS
END

ALTER DATABASE CircuitWatchdog SET RECOVERY SIMPLE, AUTO_SHRINK ON
GO

DECLARE @test int
SELECT @test = SUSER_ID(N'watchdog')
IF @test IS NULL
BEGIN
	CREATE LOGIN watchdog WITH PASSWORD = N'watchdog',
	CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF, DEFAULT_DATABASE = CircuitWatchdog
END

SET @test = IS_SRVROLEMEMBER('public',N'watchdog')
IF @test = 0
BEGIN
	EXEC sp_addsrvrolemember @loginame = N'watchdog', @rolename = 'public' 
END
GO

USE CircuitWatchdog

DECLARE @test int

IF NOT EXISTS(SELECT 1 FROM sys.sysusers WHERE name = N'watchdog')
BEGIN
	CREATE USER watchdog FROM LOGIN watchdog WITH DEFAULT_SCHEMA = dbo
END

IF IS_ROLEMEMBER(N'db_owner',N'watchdog') <> 1
BEGIN
	EXEC sp_addrolemember N'db_owner', N'watchdog'
END

IF IS_ROLEMEMBER(N'db_datareader',N'watchdog') <> 1
BEGIN
	EXEC sp_addrolemember N'db_datareader', N'watchdog'
END

IF IS_ROLEMEMBER(N'db_datawriter',N'watchdog') <> 1
BEGIN
	EXEC sp_addrolemember N'db_datawriter', N'watchdog'
END

BEGIN TRANSACTION

SELECT @test = OBJECT_ID('Circuits')
IF @test IS NULL
BEGIN
	CREATE TABLE Circuits
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code				nvarchar(32)	NOT NULL,
		[Name]			nvarchar(256)	NOT NULL
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Circuits ON Circuits (Code ASC)
	CREATE UNIQUE NONCLUSTERED INDEX IX2_Circuits ON Circuits ([Name] ASC)
END

SELECT @test = OBJECT_ID('CircuitDescs')
IF @test IS NULL
BEGIN
	CREATE TABLE CircuitDescs
	(
		Id					int						NOT NULL PRIMARY KEY,
		Ver					rowversion		NOT NULL,
		[Desc]			nvarchar(max)	NULL
	)

	ALTER TABLE CircuitDescs ADD CONSTRAINT FK1_CircuitDescs FOREIGN KEY (Id)
	REFERENCES Circuits (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Pins')
IF @test IS NULL
BEGIN
	CREATE TABLE Pins
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code				nvarchar(32)	NOT NULL,
		[Name]			nvarchar(256)	NOT NULL, --may not be required
		[Type]			int						NOT NULL, -- input, output
		Probed			bit						NOT NULL DEFAULT(1) -- if it should be probed/monitored
		--extra parameters such as weight, priority, criticality, etc. may apply
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Pins ON Pins (Code ASC)
	CREATE UNIQUE NONCLUSTERED INDEX IX2_Pins ON Pins ([Name] ASC)
END

SELECT @test = OBJECT_ID('CircuitPins')
IF @test IS NULL
BEGIN
	CREATE TABLE CircuitPins
	(
		CircuitId		int						NOT NULL,
		PinId				int						NOT NULL,
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE CircuitPins ADD CONSTRAINT PK_CircuitPins PRIMARY KEY CLUSTERED(CircuitId,PinId)
END

SELECT @test = OBJECT_ID('Switches')
IF @test IS NULL
BEGIN
	CREATE TABLE Switches --the concept of switches should TBD, so far it is just indication of intentions
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code				nvarchar(32)	NOT NULL,
		[Name]			nvarchar(256)	NOT NULL
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Switches ON Switches (Code ASC)
	CREATE UNIQUE NONCLUSTERED INDEX IX2_Switches ON Switches ([Name] ASC)
END

SELECT @test = OBJECT_ID('Buses')
IF @test IS NULL
BEGIN
	CREATE TABLE Buses -- may operate under the hood
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code				nvarchar(32)	NOT NULL, -- may not be required
		[Name]			nvarchar(256)	NOT NULL -- may not be required
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Buses ON Buses (Code ASC)
	CREATE UNIQUE NONCLUSTERED INDEX IX2_Buses ON Buses ([Name] ASC)
END

SELECT @test = OBJECT_ID('BusDescs')
IF @test IS NULL
BEGIN
	CREATE TABLE BusDescs
	(
		Id					int						NOT NULL PRIMARY KEY,
		Ver					rowversion		NOT NULL,
		[Desc]			nvarchar(max)	NULL
	)

	ALTER TABLE BusDescs ADD CONSTRAINT FK1_BusDescs FOREIGN KEY (Id)
	REFERENCES Buses (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Wires')
IF @test IS NULL
BEGIN
	CREATE TABLE Wires --operates under the hood
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)
END

SELECT @test = OBJECT_ID('BusWires')
IF @test IS NULL
BEGIN
	CREATE TABLE BusWires --operates under the hood
	(
		BusId				int						NOT NULL,
		WireId			int						NOT NULL,
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE BusWires ADD CONSTRAINT PK_BusWires PRIMARY KEY CLUSTERED(BusId,WireId)

	ALTER TABLE BusWires ADD CONSTRAINT FK1_BusWires FOREIGN KEY (BusId)
	REFERENCES Buses (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE

	ALTER TABLE BusWires ADD CONSTRAINT FK2_BusWires FOREIGN KEY (WireId)
	REFERENCES Wires (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('WiredPins')
IF @test IS NULL
BEGIN
	CREATE TABLE WiredPins --operates under the hood
	(
		WireId			int						NOT NULL,
		PinId				int						NOT NULL,
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE WiredPins ADD CONSTRAINT PK_WiredPins PRIMARY KEY CLUSTERED(WireId,PinId)

	ALTER TABLE WiredPins ADD CONSTRAINT FK1_WiredPins FOREIGN KEY (WireId)
	REFERENCES Wires (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE

	ALTER TABLE WiredPins ADD CONSTRAINT FK2_WiredPins FOREIGN KEY (PinId)
	REFERENCES Pins (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Watch')
IF @test IS NULL
BEGIN
	CREATE TABLE Watch
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code				nvarchar(32)	NOT NULL,
		[Name]			nvarchar(256)	NOT NULL
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Watch ON Watch (Code ASC)
	CREATE UNIQUE NONCLUSTERED INDEX IX2_Watch ON Watch ([Name] ASC)
END

SELECT @test = OBJECT_ID('WatchDescs')
IF @test IS NULL
BEGIN
	CREATE TABLE WatchDescs
	(
		Id					int						NOT NULL PRIMARY KEY,
		Ver					rowversion		NOT NULL,
		[Desc]			nvarchar(max)	NULL
	)

	ALTER TABLE WatchDescs ADD CONSTRAINT FK1_WatchDescs FOREIGN KEY (Id)
	REFERENCES Watch (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('WatchItems')
IF @test IS NULL
BEGIN
	CREATE TABLE WatchItems
	(
		WatchId			int						NOT NULL,
		DeviceId		int						NOT NULL, -- must be circuit, etc.
		Ver					rowversion		NOT NULL,
		[Enabled]		bit						NOT NULL DEFAULT(1),
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Modified		datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE WatchItems ADD CONSTRAINT PK_WatchItems PRIMARY KEY CLUSTERED(WatchId,DeviceId)

	ALTER TABLE WatchItems ADD CONSTRAINT FK1_WatchItems FOREIGN KEY (WatchId)
	REFERENCES Watch (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE

	/*ALTER TABLE WatchItems ADD CONSTRAINT FK2_WatchItems FOREIGN KEY (DeviceId)
	REFERENCES ??? (Id) maybe we need a global register of all devices subject to watching
	ON DELETE CASCADE
	ON UPDATE CASCADE*/
END

SELECT @test = OBJECT_ID('Faults')
IF @test IS NULL
BEGIN
	CREATE TABLE Faults
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Logged			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Severity		int						NOT NULL DEFAULT(-1),	--N/A for Exception class
		Code				int						NOT NULL DEFAULT(-1),	--N/A for Exception class
		[Name]			nvarchar(32)	NULL,
		[Message]		nvarchar(256)	NULL
	)
END

SELECT @test = OBJECT_ID('FaultData')
IF @test IS NULL
BEGIN
	CREATE TABLE FaultData
	(
		Id		int					NOT NULL PRIMARY KEY,
		Ver		rowversion	NOT NULL,
		Blob	image				NULL
	)

	ALTER TABLE FaultData ADD CONSTRAINT FK1_FaultData FOREIGN KEY (Id)
	REFERENCES Faults (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Events')
IF @test IS NULL
BEGIN
	CREATE TABLE [Events]
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		[Level]			int						NOT NULL,
		Created			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Logged			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		EventId			int						NOT NULL DEFAULT(0),
		Category		int						NOT NULL DEFAULT(0),
		[Source]		nvarchar(32)	NULL,
		[Message]		nvarchar(256)	NULL
	)
END

SELECT @test = OBJECT_ID('EventData')
IF @test IS NULL
BEGIN
	CREATE TABLE [EventData]
	(
		Id		int					NOT NULL PRIMARY KEY,
		Ver		rowversion	NOT NULL,
		Blob	image				NULL
	)

	ALTER TABLE [EventData] ADD CONSTRAINT FK1_EventData FOREIGN KEY (Id)
	REFERENCES [Events] (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

COMMIT TRANSACTION
GO