--	Objects to support random population generation
If Exists (	Select * From INFORMATION_SCHEMA.Tables Where TABLE_TYPE = 'View' And TABLE_NAME = 'UUID')
	Drop View UUID
Go
Create View UUID
As
Select
	NewID() As UUID
Go
If Exists (Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_TYPE = 'Function' And ROUTINE_NAME = 'RandomNo')
	Drop Function RandomNo
Go
Create Function RandomNo
(	@Min Int,
	@Max Int)
Returns Table 
As
Return
(
	Select
		Abs(CheckSum(UUID)%(@Max - @Min + 1)) + @Min  As Number
	From	
		UUID
)
Go
If Exists (Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_TYPE = 'Function' And ROUTINE_NAME = 'NumberList')
	Drop Function NumberList
Go
Create Function NumberList
(	@Quantity Int)
Returns Table
As
Return
	-- Bootstrap a numberlist
	With N0 As 
	(
		Select
			n
		From
			(Values(1)) N(n)
		Union All
		Select
			n + 1 
		From
			N0
		Where 
			n < 101
	),
	N1 As 
	(
		Select
			1 As n
		From
			N0
		Union All
		Select
			n + 1 
		From
			N1
		Where 
			n < 101
	),
	N2 As 
	(
		Select
			1 As n
		From
			N1
			Cross Join
			N1 As N1a
	),
	N3 As 
	(
		Select
			1 As n
		From
			N2
			Cross Join
			N2 As N2a
	)
	Select
		Number
	From
		(
			Select
				ROW_NUMBER() Over (Order By n) As Number
			From
				N3
		) As N4
	Where
		N4.Number <= @Quantity
Go

--	Example game
Truncate Table Settings

Insert Settings
(	SettingsID, XMin, XMax, YMin, YMax)
Values
(	1, 0, 30, 0, 30)

Truncate Table LiveCell

Insert LiveCell
(	Generation, XPos, YPos)
Select Distinct	--	Can sometimes generate duplicates
	1, RX.Number, RY.Number
From
	NumberList(450) As N
	Cross Join
	Settings As S
	Cross Apply
	RandomNo(S.Xmin, S.XMax) As RX
	Cross Apply
	RandomNo(S.YMin, S.YMax) As RY

Exec GenerateIterations 100

/*
Smaller test population, fixed data
Truncate Table LiveCell

Insert LiveCell
(	Generation, XPos, YPos)
Values
(	1, 1, 1),
(	1, 2, 1),
(	1, 1, 2),
(	1, 2, 2),
(	1, 10, 2),
(	1, 11, 1),
(	1, 12, 1),
(	1, 11, 3),
(	1, 12, 3),
(	1, 13, 2),
(	1, 20, 1),
(	1, 20, 2),
(	1, 20, 3),
(	1, 1, 5),
(	1, 2, 5),
(	1, 3, 5),
(	1, 2, 6),
(	1, 3, 6),
(	1, 4, 6)


Exec GenerateIterations 20

*/