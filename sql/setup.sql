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
	CREATE LOGIN watchdog WITH PASSWORD = N'18BB1E14-8837-4FD6-AB9B-72240DC3C9F4',
	CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF, DEFAULT_DATABASE = CircuitWatchdog
END

SET @test = IS_SRVROLEMEMBER('public',N'watchdog')
IF @test = 0
BEGIN
	EXEC sp_addsrvrolemember @loginame = N'watchdog', @rolename = 'public' 
END
GO

USE CircuitWatchdog

DECLARE @test int = SCHEMA_ID('Bus')

IF @test IS NULL
BEGIN
	EXEC('CREATE SCHEMA Bus')
END

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

SELECT @test = OBJECT_ID('Bus.Circuits')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.Circuits
	(
		Id			int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver			rowversion		NOT NULL,
		Enbld		bit						NOT NULL DEFAULT(1),
		TMake		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code		nvarchar(32)	NOT NULL
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Bus_Circuits ON Bus.Circuits (Code ASC)
END

SELECT @test = OBJECT_ID('Bus.CircuitDescs')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.CircuitDescs
	(
		Id		int						NOT NULL PRIMARY KEY,
		Ver		rowversion		NOT NULL,
		Dsc		nvarchar(max)	NULL
	)

	ALTER TABLE Bus.CircuitDescs ADD CONSTRAINT FK1_Bus_CircuitDescs FOREIGN KEY (Id)
	REFERENCES Bus.Circuits (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Bus.Pins')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.Pins
	(
		Id			int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver			rowversion		NOT NULL,
		Enbld		bit						NOT NULL DEFAULT(1),
		TMake		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code		nvarchar(32)	NOT NULL,
		Typ			int						NOT NULL, -- input, output
		Probed	bit						NOT NULL DEFAULT(1) -- if it should be probed/monitored
		--extra parameters such as weight, priority, criticality, etc. may apply
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Bus_Pins ON Bus.Pins (Code ASC)
END

SELECT @test = OBJECT_ID('Bus.CircuitPins')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.CircuitPins
	(
		CircuitId		int						NOT NULL,
		PinId				int						NOT NULL,
		Ver					rowversion		NOT NULL,
		Enbld				bit						NOT NULL DEFAULT(1),
		TMake				datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod				datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE Bus.CircuitPins ADD CONSTRAINT PK_Bus_CircuitPins PRIMARY KEY CLUSTERED(CircuitId,PinId)
END

SELECT @test = OBJECT_ID('Bus.PinMeasures')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.PinMeasures
	(
		PinId				int						NOT NULL,
		MeasureId		int						NOT NULL,
		Ver					rowversion		NOT NULL,
		Enbld				bit						NOT NULL DEFAULT(1),
		TMake				datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod				datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE Bus.PinMeasures ADD CONSTRAINT PK_Bus_PinMeasures PRIMARY KEY CLUSTERED(PinId,MeasureId)
END

SELECT @test = OBJECT_ID('Bus.Switches')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.Switches --the concept of switches is TBD, so far it is just indication of intentions
	(
		Id			int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver			rowversion		NOT NULL,
		Enbld		bit						NOT NULL DEFAULT(1),
		TMake		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Tmod		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code		nvarchar(32)	NOT NULL
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Bus_Switches ON Bus.Switches (Code ASC)
END

SELECT @test = OBJECT_ID('Bus.Buses')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.Buses -- may operate under the hood
	(
		Id			int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver			rowversion		NOT NULL,
		Enbld		bit						NOT NULL DEFAULT(1),
		TMake		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMode		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code		nvarchar(32)	NOT NULL -- may not be required
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Bus_Buses ON Bus.Buses (Code ASC)
END

SELECT @test = OBJECT_ID('Bus.BusDescs')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.BusDescs
	(
		Id		int						NOT NULL PRIMARY KEY,
		Ver		rowversion		NOT NULL,
		Dsc		nvarchar(max)	NULL
	)

	ALTER TABLE Bus.BusDescs ADD CONSTRAINT FK1_Bus_BusDescs FOREIGN KEY (Id)
	REFERENCES Bus.Buses (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Bus.Wires')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.Wires --operates under the hood
	(
		Id			int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver			rowversion		NOT NULL,
		Enbld		bit						NOT NULL DEFAULT(1),
		TMake		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod		datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)
END

SELECT @test = OBJECT_ID('Bus.BusWires')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.BusWires --operates under the hood
	(
		BusId			int						NOT NULL,
		WireId		int						NOT NULL,
		Ver				rowversion		NOT NULL,
		Enbld			bit						NOT NULL DEFAULT(1),
		TMake			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod			datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE Bus.BusWires ADD CONSTRAINT PK_Bus_BusWires PRIMARY KEY CLUSTERED(BusId,WireId)

	ALTER TABLE Bus.BusWires ADD CONSTRAINT FK1_Bus_BusWires FOREIGN KEY (BusId)
	REFERENCES Bus.Buses (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE

	ALTER TABLE Bus.BusWires ADD CONSTRAINT FK2_Bus_BusWires FOREIGN KEY (WireId)
	REFERENCES Bus.Wires (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Bus.WiredPins')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.WiredPins --operates under the hood
	(
		WireId		int						NOT NULL,
		PinId			int						NOT NULL,
		Ver				rowversion		NOT NULL,
		Enbld			bit						NOT NULL DEFAULT(1),
		TMake			datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod			datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE Bus.WiredPins ADD CONSTRAINT PK_Bus_WiredPins PRIMARY KEY CLUSTERED(WireId,PinId)

	ALTER TABLE Bus.WiredPins ADD CONSTRAINT FK1_Bus_WiredPins FOREIGN KEY (WireId)
	REFERENCES Bus.Wires (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE

	ALTER TABLE Bus.WiredPins ADD CONSTRAINT FK2_Bus_WiredPins FOREIGN KEY (PinId)
	REFERENCES Bus.Pins (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Bus.Watch')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.Watch
	(
		Id			int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver			rowversion		NOT NULL,
		Enbld		bit						NOT NULL DEFAULT(1),
		TMake		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod		datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Code		nvarchar(32)	NOT NULL
	)
	
	CREATE UNIQUE NONCLUSTERED INDEX IX1_Bus_Watch ON Bus.Watch (Code ASC)
END

SELECT @test = OBJECT_ID('Bus.WatchDescs')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.WatchDescs
	(
		Id		int						NOT NULL PRIMARY KEY,
		Ver		rowversion		NOT NULL,
		Dsc		nvarchar(max)	NULL
	)

	ALTER TABLE Bus.WatchDescs ADD CONSTRAINT FK1_Bus_WatchDescs FOREIGN KEY (Id)
	REFERENCES Bus.Watch (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Bus.WatchItems')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.WatchItems
	(
		WatchId			int						NOT NULL,
		DeviceId		int						NOT NULL, -- must be circuit, etc.
		Ver					rowversion		NOT NULL,
		Enbld				bit						NOT NULL DEFAULT(1),
		TMake				datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TMod				datetime2			NOT NULL DEFAULT(GETUTCDATE())
	)

	ALTER TABLE Bus.WatchItems ADD CONSTRAINT PK_Bus_WatchItems PRIMARY KEY CLUSTERED(WatchId,DeviceId)

	ALTER TABLE Bus.WatchItems ADD CONSTRAINT FK1_Bus_WatchItems FOREIGN KEY (WatchId)
	REFERENCES Bus.Watch (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE

	/*ALTER TABLE WatchItems ADD CONSTRAINT FK2_WatchItems FOREIGN KEY (DeviceId)
	REFERENCES ??? (Id) maybe we need a global register of all devices subject to watching
	ON DELETE CASCADE
	ON UPDATE CASCADE*/
END

SELECT @test = OBJECT_ID('Bus.Faults')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.Faults
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		TMake				datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TLog				datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		Severity		int						NOT NULL DEFAULT(-1),	--N/A for Exception class
		Code				int						NOT NULL DEFAULT(-1),	--N/A for Exception class
		Title				nvarchar(32)	NULL,
		Dsc					nvarchar(256)	NULL
	)
END

SELECT @test = OBJECT_ID('Bus.FaultData')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.FaultData
	(
		Id		int					NOT NULL PRIMARY KEY,
		Ver		rowversion	NOT NULL,
		Blob	image				NULL
	)

	ALTER TABLE Bus.FaultData ADD CONSTRAINT FK1_Bus_FaultData FOREIGN KEY (Id)
	REFERENCES Bus.Faults (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

SELECT @test = OBJECT_ID('Bus.Evnts')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.Evnts
	(
		Id					int						NOT NULL PRIMARY KEY IDENTITY(1,1),
		Ver					rowversion		NOT NULL,
		Lvl					int						NOT NULL,
		TMake				datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		TLog				datetime2			NOT NULL DEFAULT(GETUTCDATE()),
		EventId			int						NOT NULL DEFAULT(0),
		Category		int						NOT NULL DEFAULT(0),
		Src					nvarchar(32)	NULL,
		Dsc					nvarchar(256)	NULL
	)
END

SELECT @test = OBJECT_ID('Bus.EvntData')
IF @test IS NULL
BEGIN
	CREATE TABLE Bus.EvntData
	(
		Id		int					NOT NULL PRIMARY KEY,
		Ver		rowversion	NOT NULL,
		Blob	image				NULL
	)

	ALTER TABLE Bus.EvntData ADD CONSTRAINT FK1_Bus_EvntData FOREIGN KEY (Id)
	REFERENCES Bus.Evnts (Id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
END

COMMIT TRANSACTION
GO