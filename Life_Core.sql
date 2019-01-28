--	Core Game of Life engine

If Exists (	Select * From INFORMATION_SCHEMA.Tables Where TABLE_TYPE = 'Base Table' And TABLE_NAME = 'LiveCell')
	Drop Table LiveCell
Go
Create Table LiveCell
(	Generation Int Not Null,
	XPos Int Not Null,
	YPos Int Not Null,
	Constraint PK_LiveCell Primary Key Clustered
	(	XPos, YPos, Generation),
	Constraint CK_XPosInRange Check
	(	XPos Between -2147483647 And 2147483646),	--	Prevent overflow at edges
	Constraint CK_YPosInRange Check
	(	YPos Between -2147483647 And 2147483646))
									 
If Exists (	Select * From INFORMATION_SCHEMA.Tables Where TABLE_TYPE = 'Base Table' And TABLE_NAME = 'Translation')
	Drop Table Translation
Go
Create Table Translation
(	DeltaX SmallInt Not Null,
	DeltaY SmallInt Not Null,
	Constraint PK_Translation Primary Key Clustered
	(	DeltaX, DeltaY))

Insert Translation
(	DeltaX, DeltaY)
Select
	DX.DeltaX, DY.DeltaY
From
	(	Values
		(-1), (0), (1)) As DX(DeltaX)
	Cross Join
	(	Values
		(-1), (0), (1)) As DY(DeltaY)

If Exists (	Select * From INFORMATION_SCHEMA.Tables Where TABLE_TYPE = 'Base Table' And TABLE_NAME = 'Settings')
	Drop Table Settings

Create Table Settings
(	SettingsID TinyInt Not Null,
	XMin Int Not Null,
	XMax Int Not Null,
	YMin Int Not Null,
	YMax Int Not Null,
	Constraint PK_Settings Primary Key Clustered
	(	SettingsID),
	Constraint CK_SingleRow Check
	(	SettingsID = 1))

;
Go

If Exists (	Select * From INFORMATION_SCHEMA.Tables Where TABLE_TYPE = 'View' And TABLE_NAME = 'Iteration')
	Drop View Iteration
Go
Create View Iteration
As
With LiveCellTranslation As
(
	Select
		LC.Generation, LC.XPos + T.DeltaX As XPos, LC.YPos + T.DeltaY As YPos, 
		Case 
			When DeltaX = 0 And DeltaY = 0 Then 1 
			Else 0 
		End As IsLive
	From
		LiveCell As LC
		Cross Join
		Translation As T
),
Agg As 
(
	Select
		LCT.Generation, LCT.XPos, LCT.YPos, Max(LCT.IsLive) As IsLive, Count(*) As Neighbours
	From
		LiveCellTranslation As LCT
		Inner Join
		Settings As S
			On	LCT.XPos Between S.XMin And S.XMax
			And	LCT.YPos Between S.YMin And S.YMax
	Group By
		LCT.Generation, LCT.XPos, LCT.YPos
)
Select
	A.Generation + 1 As Generation, A.XPos, A.YPos, A.IsLive, A.Neighbours
From
	Agg As A
Where
	(
		A.IsLive = 1 
		And 
		A.Neighbours Between 3 And 4
	)
	Or
	(
		A.IsLive = 0
		And
		A.Neighbours = 3
	)
Go
If Exists (Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_TYPE = 'Procedure' And ROUTINE_NAME = 'GenerateIteration')
	Drop Procedure GenerateIteration
Go
Create Procedure GenerateIteration
As
Insert LiveCell
(	Generation, XPos, YPos)
Select
	I.Generation, I.XPos, I.YPos
From
	Iteration As I
Where
	I.Generation =	(	
						Select 
							Max(Generation) + 1 
						From 
							LiveCell
					)
Go

If Exists (Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_TYPE = 'Procedure' And ROUTINE_NAME = 'GenerateIterations')
	Drop Procedure GenerateIterations
Go

Create Procedure GenerateIterations
	@NoOfIterations Int
As
Declare @Ctr Int = 1

While @Ctr <= @NoOfIterations
	Begin
		Exec GenerateIteration
		Set @Ctr = @Ctr + 1
	End
Go
/*
Usage:

Insert initial configuration to LiveCells.
Call GenerateIterations with the required number of new iterations

*/
