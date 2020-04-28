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
