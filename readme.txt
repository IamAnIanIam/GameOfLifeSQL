SQL Server-based version of Conway's Game of Life.

Life_core contains the actual engine.

Life_rendering contains objects to support grid rendering in SSMS

Life_SampleGeneration contains objects to support random population generation

Use Settings table to define the grid size - can be arbitarily large (up to int limits, obviously!). Grid size in itself doesn't affect speed/space requirements, only the number of live cells does. Rendering large grids takes longer though & there may be limits to the size that can be displayed in SSMS.

Insert initial configuration to LiveCells.

Call GenerateIterations with the required number of new iterations.

Call DisplayGenerations with start & end generations to display, or no parameters to display all (beware of memory issues if displaying > 100 grids

