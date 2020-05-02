# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an towers grid with CPLEX
"""
function cplexSolve(t::Array{Int, 2})
   
    n=size(t,1)-2	

    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))

    # x[i, j, k,l] = 1 if cell (i, j) is visible from (k,l)
    @variable(m, x[1:n, 1:n, 1:n, 1:n], Bin) 
        # x_ijkl = 1 si t_ij > t_kl, 0 sinon
	

    # Each clue around the edge gives the number of towers that are visibles when looking into the grid from that direction
    @constraint(m, [j in 1:n], sum((1/(i-1))*sum(x[i,j,k,j] for k in 1:(i-1)) for i in 2:n) + 1 >= t[1,j+1])
    @constraint(m, [i in 1:n], sum((1/(j-1))*sum(x[i,j,i,k] for k in 1:(j-1)) for j in 2:n) + 1 >= t[i+1,1])
    @constraint(m, [j in 1:n], sum((1/(n-i))*sum(x[i,j,k,j] for k in (i+1):n) for i in 1:(n-1)) + 1 >= t[n+2,j+1])
    @constraint(m, [i in 1:n], sum((1/(n-j))*sum(x[i,j,i,k] for k in (j+1):n) for j in 1:(n-1)) + 1 >= t[i+1,n+2])

    #test : le nb de tours visibles depuis la premiere de la ligne/col est inférieur a la contrainte
    @constraint(m, [j in 1:n], sum(x[1,j,i,j] for i in 2:n) <= n - t[1,j+1])
    @constraint(m, [i in 1:n], sum(x[i,1,i,j] for j in 2:n) <= n - t[i+1,1])
    @constraint(m, [j in 1:n], sum(x[n,j,i,j] for i in 1:(n-1)) <= n - t[n+2,j+1])
    @constraint(m, [i in 1:n], sum(x[i,n,i,j] for j in 1:(n-1)) <= n - t[i+1,n+2])

    # sum(x[i,j,i,k] for k in 1:n) + 1 = t_ij
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,i,k] for k in 1:n) - sum(x[i,j,k,j] for k in 1:n) == 0)
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,i,k] for k in 1:n) <= n - 1)
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,i,k] for k in 1:n) >= 0)

    @constraint(m, [i in 1:n, j in 1:n], x[i,j,i,j] == 0)
    @constraint(m, [i in 1:n, j in 2:n, l in 1:(j-1)], x[i,l,i,j] + x[i,j,i,l] == 1)
    @constraint(m, [i in 1:n, j in 1:(n-1), l in (j+1):n], x[i,l,i,j] + x[i,j,i,l] == 1)
    @constraint(m, [i in 1:n, j in 2:n, k in 1:(i-1)], x[k,j,i,j] + x[i,j,k,j] == 1)
    @constraint(m, [i in 1:n, j in 1:(n-1), k in (i+1):n], x[k,j,i,j] + x[i,j,k,j] == 1)

    # somme t_ij sur ligne/col doit etre egale a sum(k)
        # somme des coef sur ligne i
    @constraint(m, [i in 1:n], sum(sum(x[i,j,i,k] for k in 1:n) + 1 for j in 1:n) == sum(k for k in 1:n))
        # somme des coef sur col j
    @constraint(m, [j in 1:n], sum(sum(x[i,j,i,k] for k in 1:n) + 1 for i in 1:n) == sum(k for k in 1:n))

    @constraint(m, [i in 1:n, j in 1:n, k in 1:n, l in 1:n; k!=l && j!=l && k!=j], x[i,j,i,k] + x[i,k,i,l] - 1 <= x[i,j,i,l])
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n, l in 1:n; k!=l && i!=k && l!=i], x[i,j,k,j] + x[k,j,l,j] - 1 <= x[i,j,l,j])


    # Maximize the top-left cell
    @objective(m, Min, sum(sum((1/(i-1))*sum(x[i,j,k,j] for k in 1:(i-1)) for i in 2:n) for j in 1:n) 
                        + sum(sum((1/(j-1))*sum(x[i,j,i,k] for k in 1:(j-1)) for j in 2:n) for i in 1:n) 
                        + sum(sum((1/(n-i))*sum(x[i,j,k,j] for k in (i+1):n) for i in 1:(n-1)) for j in 1:n) 
                        + sum(sum((1/(n-j))*sum(x[i,j,i,k] for k in (j+1):n) for j in 1:(n-1)) for i in 1:n))

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, x, time() - start
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve(t::Array{Int, 2})

    n = size(t, 1)-2
    tCopy = []
    tCopy = zeros(Int64, n, n)

    # True if the grid has completely been filled
    gridFilled = false

    # True if the grid may still have a solution
    gridStillFeasible = true

    # While the grid is not filled and it may still be solvable
    while !gridFilled && gridStillFeasible

        # Coordinates of the most constrained cell
        mcCell = [-1 -1]

        # Values which can be assigned to the most constrained cell
        values = nothing
        
        # Randomly select a cell and a value
        l = ceil.(Int, n * rand())
        c = ceil.(Int, n * rand())
        id = 1

        # For each cell of the grid, while a cell with 0 values has not been found
        while id <= n*n && (values == nothing || size(values, 1)  != 0)

            # If the cell does not have a value
            if tCopy[l, c] == 0

                # Get the values which can be assigned to the cell
                cValues = possibleValues2(t, tCopy, l, c)

                # If it is the first cell or if it is the most constrained cell currently found
                if values == nothing || size(cValues, 1) < size(values, 1)

                    values = cValues
                    mcCell = [l c]
                end 
            end
            
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

            id += 1
        end

        # If all the cell have a value
        if values == nothing

            gridFilled = true
            gridStillFeasible = true
        else

            # If a cell cannot be assigned any value
            if size(values, 1) == 0
                gridStillFeasible = false

                # Else assign a random value to the most constrained cell 
            else
                
                newValue = ceil.(Int, rand() * size(values, 1))
                tCopy[mcCell[1], mcCell[2]] = values[newValue]
            end 
        end  
    end  

    return gridStillFeasible, tCopy

end 

"""
Number of values which could currently be assigned to a cell

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
- l, c: row and column of the cell

Return
- values: array of integers which do not appear on line l, column c 
"""
function possibleValues(t::Array{Int, 2}, l::Int64, c::Int64)

    values = Array{Int64, 1}()

    for v in 1:size(t, 1)
        if isValid(t, l, c, v)
            values = append!(values, v)
        end 
    end 

    return values
    
end

function possibleValues2(d::Array{Int, 2}, t::Array{Int, 2}, l::Int64, c::Int64)

    values = Array{Int64, 1}()
    n = size(t, 1)
    m=(n+1)

    # tours visibles gauche
    mg = t[l, 1] # tour la plus haute sur la ligne a gauche
    vg = 1 # nb tours visibles avant [l, c] sur la ligne a gauche
    if c != 1
        for j in 2:(c-1) 
            if t[l, j] > mg && mg > 0
                mg = t[l, j]
                vg += 1
            end
        end
    elseif d[l+1, 1] == 1
        values = [n]
        return values
    end
    if d[l+1, 1] == vg
        m = mg # la tour ne doit pas etre visible a gauche
    end
    # tours visibles bas
    mb = t[n, c] # tour la plus haute sur la colonne bas
    vb = 1 # nb tours visibles avant [l, c] sur la colonne bas
    if l != n
        for i in (l+1):n 
            if t[n+l+1-i, c] > mb && mb > 0
                mb = t[i, c]
            end
        end
    elseif d[n+2, c+1] == 1
        values = [n]
        return values
    end
    if d[n+2, c+1] == vb
        if mb < m && mb > 0
            m = mb # la tour ne doit pas etre visible en bas
        end
    end
    # tours visibles droite
    md = t[l, n] # tour la plus haute sur la ligne a droite
    vd = 1 # nb tours visibles avant [l, c] sur la ligne a droite
    if c != n
        for j in (c+1):n
            if t[l, n+c+1-j] > md && md > 0
                md = t[l, j]
            end
        end
    elseif d[l+1, n+2] == 1
        values = [n]
        return values
    end
    if d[l+1, n+2] == vd
        if md < m && md > 0
            m = md # la tour ne doit pas etre visible a droite
        end
    end
    # tours visibles haut
    mh = t[1, c] # tour la plus haute sur la colonne en haut
    vh = 1 # nb tours visibles avant [l, c] sur la colonne en haut
    if l != 1
        for i in 2:(l-1) 
            if t[i, c] > mh && mh > 0
                mh = t[i, c]
            end
        end
    elseif d[1, c+1] == 1
        values = [n]
        return values
    end
    if d[1, c+1] == vh
        if mh < m && mh > 0
            m = mh # la tour ne doit pas etre visible en haut
        end 
    end
    
    if m > 0
        for v in 1:n
            if isValid(t, l, c, v) && v<m
                values = append!(values, v)
            end 
        end 
    else
        for v in 1:n
            if isValid(t, l, c, v) 
                values = append!(values, v)
            end 
        end 
    end
    
    return values
    
end

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    #resolutionMethod = ["cplex"]
    resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        t = readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # Solve it and get the results
                    isOptimal, x, resolutionTime = cplexSolve(t)
                    
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(fout, x)
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false
                    solution = []

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                                                                        
                        # Solve it and get the results
                        isOptimal, solution = heuristicSolve(t)

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal
                        writeSolution(fout, solution)
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
