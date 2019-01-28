--	Grid rendering objects
If Exists (	Select * From INFORMATION_SCHEMA.Tables Where TABLE_TYPE = 'View' And TABLE_NAME = 'LiveCellPolygonList')
	Drop View LiveCellPolygonList
Go
Create View LiveCellPolygonList
As
With A As
(
	Select
		Generation, XPos, YPos, Concat('(', String_Agg(Concat_WS(' ', Cast(XPos + DeltaX As VarChar(10)), Cast(YPos + DeltaY As VarChar(10))), ', ') Within Group (Order By SortOrder), ')') As Cell
	From
		LiveCell
		Cross Join
		(
			Select
				DeltaX, DeltaY, DeltaX + DeltaY + Cast(Cast(DeltaX As Bit) & ~Cast(DeltaY As Bit) As TinyInt) * 2 As SortOrder
			From
				Translation
			Where
				DeltaX > = 0
				And
				DeltaY >= 0
			Union All
			Select
				0, 0, 4
		) As T
	Where
		DeltaX > = 0
		And
		DeltaY >= 0
	Group By 
		Generation, XPos, YPos
)
Select
	Generation, String_Agg(Cast(A.Cell As VarChar(Max)), ', ') As PolygonList
From
	A
Group By
	Generation
Go

If Exists (Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_TYPE = 'Procedure' And ROUTINE_NAME = 'DisplayGrid')
	Drop Procedure DisplayGrid
Go
Create Procedure DisplayGrid
(	@Generation Int)
As
Declare @PolygonList VarChar(Max), @G geometry, @Polygon VarChar(Max), @XMin VarChar(20), @XMax VarChar(20), @YMin VarChar(20), @YMax VarChar(20)

Select
	@PolygonList = PolygonList
From
	LiveCellPolygonList
Where
	Generation = @Generation

Select
	@XMin = Cast(XMin As VarChar(20)), 
	@XMax = Cast(XMax + 1 As VarChar(20)), 
	@YMin = Cast(YMin As VarChar(20)), 
	@YMax = Cast(YMax + 1 As VarChar(20)) 
From
	Settings

Set @Polygon = Concat('POLYGON((', @XMin, ' ', @YMin, ', ', @XMax, ' ', @YMin, ', ', @XMax, ' ', @YMax, ', ', @XMin, ' ', @YMax, ', ', @XMin, ' ', @YMin, '), ', @PolygonList, ')')

Set @G = Geometry::Parse(@Polygon);  
Select @g
Go

If Exists (Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_TYPE = 'Procedure' And ROUTINE_NAME = 'DisplayGenerations')
	Drop Procedure DisplayGenerations
Go
Create Procedure DisplayGenerations
	@StartGeneration Int = 1,
	@EndGeneration Int = Null
As
Declare @Generation Int = @StartGeneration, @NoOfGenerations Int

Select 
	@NoOfGenerations = Max(Generation)
From
	LiveCell

Set @EndGeneration = Coalesce(@EndGeneration, @NoOfGenerations)

If @NoOfGenerations < @EndGeneration
	Set @EndGeneration = @NoOfGenerations
Else 

While @Generation <= @EndGeneration
	Begin		
		Exec DisplayGrid @Generation
		Set @Generation = @Generation + 1
	End
Go

/*
Call DisplayGenerations with start & end generations to display, or no parameters to display all (beware of memory issues if displaying > 100 grids
*/
