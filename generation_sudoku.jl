# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

    # True if the current grid has no conflicts
    # (i.e., not twice the same value on a line, column or block)
    isGridValid = false

    t = []

    # While a valid grid is not obtained 
    while !isGridValid

        isGridValid = true
        
        # Array that will contain the generated grid
        t = zeros(n, n)
        i = 1

        # While the grid is valid and the required number of cells is not filled
        while isGridValid && i < (n*n*density)

            # Randomly select a cell and a value
            l = ceil.(Int, n * rand())
            c = ceil.(Int, n * rand())
            v = ceil.(Int, n * rand())

            # True if a value has already been assigned to the cell (l, c)
            isCellFree = t[l, c] == 0

            # True if value v can be set in cell (l, c)
            isValueValid = isValid(t, l, c, v)

            # Number of value that we already tried to assign to cell (l, c)
            attemptCount = 0

            # Number of cells considered in the grid
            testedCells = 1

            # While it is not possible to assign the value to the cell
            # (we assign a value if the cell is free and the value is valid)
            # and while all the cells have not been considered
            while !(isCellFree && isValueValid) && testedCells < n*n

                # If the cell has already been assigned a number or if all the values have been tested for this cell
                if !isCellFree || attemptCount == n
                    
                    # Go to the next cell                    
                    if c < n
                        c += 1
                    else
                        if l < n
                            l += 1
                            c = 1
                        else
                            l = 1
                            c = 1
                        end
                    end

                    testedCells += 1
                    isCellFree = t[l, c] == 0
                    isValueValid = isValid(t, l, c, v)
                    attemptCount = 0
                    
                    # If the cell has not already been assigned a value and all the value have not all been tested
                else
                    attemptCount += 1
                    v = rem(v, n) + 1
                end 
            end

            if testedCells == n*n
                isGridValid = false
            else 
                t[l, c] = v
            end

            i += 1
        end
    end

    return t
    
end 


"""
Test if cell (l, c) can be assigned value v

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
- l, c: considered cell
- v: value considered

Return: true if t[l, c] can be set to v; false otherwise
"""
function isValid(t::Array{Int64, 2}, l::Int64, c::Int64, v::Int64)

    n = size(t, 1)
    isValid = true

    # Test if v appears in column c
    l2 = 1

    while isValid && l2 <= n
        if t[l2, c] == v
            isValid = false
        end

        l2 += 1
    end

    # Test if v appears in line l
    c2 = 1

    while isValid && c2 <= n
        if t[l, c2] == v
            isValid = false
        end
        c2 += 1
    end
    
    # Test if v appears in the block which contains cell (l, c)
    blockSize = round.(Int, sqrt(n))
    
    lTop = l - rem(l - 1, blockSize)
    cLeft = c - rem(c - 1, blockSize)

    l2 = lTop
    c2 = cLeft

    while isValid && l2 != lTop + blockSize
        
        if t[l2, c2] == v
            isValid = false
        end

        # Go to the next cell of the block
        if c2 != cLeft + blockSize - 1
            c2 += 1
        else
            l2 += 1
            c2 = cLeft
        end 
    end

    return isValid
    
end


"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # For each grid size considered
    for size in [4, 9, 16, 25]

        # For each grid density considered
        for density in 0.1:0.2:0.3

            # Generate 10 instances
            for instance in 1:10

                fileName = "../data/instance_t" * string(size) * "_d" * string(density) * "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println("-- Generating file " * fileName)
                    saveInstance(generateInstance(size, density), fileName)
                end 
            end
        end
    end
end



