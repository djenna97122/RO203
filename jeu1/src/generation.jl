# This file contains methods to generate a data set of instances (i.e., towers grids)
include("io.jl")

"""
Generate an n+2*n+2 grid

Argument
- n: size of the grid to play in

"""
function generateInstance(n::Int64)
    # True if the current grid has no conflicts
    # (i.e., not twice the same value on a line or column)
    isGridValid = false

    t = []
    

    # While a valid grid is not obtained 
    while !isGridValid

        isGridValid = true
        
        # Array that will contain the generated grid
        t = zeros(Int64, n, n)
        i = 1

        # While the grid is valid and the required number of cells is not filled
        while isGridValid && i <= (n*n)

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

            # While is it not possible to assign the value to the cell
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
                    isValueValid = isValid(t, l, c, v)
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

    c = []
    c = zeros(Int64, n+2, n+2)
    # tours visibles gauche
    for i in 1:n
        c[i+1, 1] = 1
        j=1
        m=t[i,j]
        while j<n 
            if t[i, j+1] > m 
                c[i+1, 1] += 1
                m = t[i, j+1]
            end
            j += 1
        end
    end
    # tours visibles bas
    for j in 1:n
        c[n+2, j+1] = 1
        i=n
        m=t[i,j]
        while i>1  
            if t[i-1, j] > m
                c[n+2, j+1] += 1
                m = t[i-1, j]
            end
            i -= 1
        end
    end
    # tours visibles droite
    for i in 1:n
        c[i+1, n+2] = 1
        j=n
        m=t[i,j]
        while j>1 
            if t[i, j-1] > m
                c[i+1, n+2] += 1
                m = t[i, j-1]
            end
            j -= 1
        end
    end
    # tours visibles haut
    for j in 1:n
        c[1, j+1] = 1
        i=1
        m=t[i,j]
        while i<n 
            if t[i+1, j] > m
                c[1, j+1] += 1
                m = t[i+1, j]
            end
            i += 1            
        end
    end
    return c, t 
end


"""
Test if cell (i, j) can be assigned value v

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
- i, j: considered cell
- v: value considered

Return: true if t[i, j] can be set to v; false otherwise
"""

function isValid(t::Array{Int64, 2}, i::Int64, j::Int64, v::Int64)

    n = size(t, 1)
    isValid = true

    # Test if v appears in column j
    l2 = 1

    while isValid && l2 <= n
        if t[l2, j] == v
            isValid = false
        end

        l2 += 1
    end

    # Test if v appears in line i
    c2 = 1

    while isValid && c2 <= n
        if t[i, c2] == v
            isValid = false
        end
        c2 += 1
    end
    
    return isValid

end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()
    # For each grid size considered
    for size in [4, 5, 6, 7, 8]
        # Generate 10 instances
        for instance in 1:2

            fileName = "../data/instance_t" * string(size) * "_" * string(instance) * ".txt"

            if !isfile(fileName)
                println("-- Generating file " * fileName)
                saveInstance(generateInstance(size), fileName)
            end
        end
    end
end


