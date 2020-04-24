# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid 

Argument
- n: size of the grid

"""
function generateInstance(n::Int64, density::Float64)

 # True if the current grid has no conflicts
 # 
    isGridValid = false
     t = []

    # While a valid grid is not obtained 
    while !isGridValid

        isGridValid = true
        
        # Array that will contain the generated grid
        t = zeros(n+2, n+2)
        i = 1
         
	while isGridValid
    
end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



