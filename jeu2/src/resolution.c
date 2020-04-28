# This file contains methods to solve a bridges grid (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX

Argument
-t:  array of size n*n with values in [0, n] (0 if the cell is empty)

Return
- status: :Optimal if the problem is solved optimally
- edges: 4-dimensional variables array such that edges[i, j, k,l] =number of bridges between (i,j) and (k,l)
- getsolvetime(m): resolution time in seconds
"""
function cplexSolve(t::Array{Any, 2})
    n = size(t, 1)
    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))

    #edges[i, j, k,l] =number of bridges between (i,j) and (k,l)
    @variable(m, 2>=edges[1:n, 1:n, 1:n, 1:n]>=0,Int)
    
    #   Mat sym par rapport aux paires
    for l in 1:n
        for c in 1:n
            for i in 1:n
                for j in 1:n
                    @constraint(m, edges[l,c,i,j]==edges[i,j,l,c])
                end
            end
        end
    end

        """
    # Set only horizontal or vertical connections
    for l in 1:n
        for c in 1:n
            for i in 1:n
                for j in 1:n
                    if (i!= l && j!=c)
                        @constraint(m, edges[l,c,i,j] == 0)
                    end
                end
            end
        end
    end
    """

    # the number in each island must match the number of bridges that end at that island (counting double bridges as two)
  
    for i in 1:n
        for j in 1:n
            if t[i,j]>0
                @constraint(m,[k in 1:n, l in 1:n], sum(sum(edges[i,j,k,l] for j in 1:n) for i in 1:n)==t[i,j])
            end
        end
    end
    #each island is connected to 1 island or less on one line or column
    for i in 1:n
        for j in 1:n
        @constraint(m,sum(edges[i,j,k,j] for k in 1:n)<=1)
        @constraint(m,sum(edges[i,j,i,l] for l in 1:n)<=1)
        end
    end
   
    """
    # Bridges dont cross
    
    for i in 1:n
        for c1 in 1:n
            for c2 in 1:n
                for j in c1:c2
                    for l1 in 1:i
                        for l2 in i:n
                            @constraint(m,edges[i,c1,i,c2]+edges[l1,j,l2,j]<=1)
                            
                        end
                    end
                end
            end
        end
    end
    """
    
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, edges,time() - start
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
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
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

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
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
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
                    
                    # TODO
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout")
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end
                end

                println(fout, "solveTime = ", resolutionTime)
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout")
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end
    end
end
