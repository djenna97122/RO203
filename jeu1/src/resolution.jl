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
    @variable(m, x[1:n, 1:n, 1:4], Bin) 
        # 1:haut, 2:gauche, 3:bas, 4:droite
	

    # Each clue around the edge gives the number of towers that are visibles when looking into the grid from that direction
    @constraint(m, [j in 1:n], sum(x[i,j,1] for i in 1:n) == t[1,j+1])
    @constraint(m, [i in 1:n], sum(x[i,j,2] for j in 1:n) == t[i+1,1])
    @constraint(m, [j in 1:n], sum(x[i,j,3] for i in 1:n) == t[n+2,j+1])
    @constraint(m, [i in 1:n], sum(x[i,j,4] for j in 1:n) == t[i+1,n+2])

    # Maximize the top-left cell
    @objective(m, Max, sum(x[1, 1, k] for k in 1:4))

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    #Test passage de x a t avec une deuxieme application de optimize
    m2 = Model(with_optimizer(CPLEX.Optimizer))
    @variable(m2, 1 <= s[1:n, 1:n] <= n, Int) 

    for i in 1:n
        for j in 1:n
            if x[i,j,1] == 1
                if i > 1
                    for k in 1:(i-1)
                        @constraint(m2, s[k,j] - s[i,j] <= -1)
                    end
                end
            end

            if x[i,j,2] == 1
                if j > 1
                    for k in 1:(j-1)
                        @constraint(m2, s[i,k] - s[i,j] <= -1)
                    end
                end
            end

            if x[i,j,3] == 1
                if i < n
                    for k in (i+1):n
                        @constraint(m2, s[k,j] - s[i,j] <= -1)
                    end
                end
            end

            if x[i,j,4] == 1
                if j < n
                    for k in (j+1):n
                        @constraint(m2, s[i,k] - s[i,j] <= -1)
                    end
                end
            end

            if (x[i,j,1] == 1) && (x[i,j,2] == 1) && (x[i,j,3] == 1) && (x[i,j,4] == 1)
                @constraint(m2, s[i,j] == n)       
            end
        end
    end

    # Maximize the top-left cell
    @objective(m2, Max, s[1, 1])

    # Solve the model
    optimize!(m2)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, x, s, time() - start
    
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
       t= readInputFile(dataFolder * file)
        
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
                    isOptimal=cplexSolve(t)[1]
                    x=cplexSolve(t)[2]
                    resolutionTime = cplexSolve(t)[3]
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                       writeSolution(fout,x)
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
