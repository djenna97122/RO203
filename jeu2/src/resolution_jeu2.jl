# This file contains methods to solve a bridges grid (heuristically or with CPLEX)
using CPLEX

include("generation_jeu2.jl")
using Random
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

 
    # Set only horizontal or vertical connections
    for l in 1:n
        for c in 1:n
            for i in 1:n
                for j in 1:n
                    if (i!= l && j!=c)
                        @constraint(m, edges[l,c,i,j] == 0)
                    elseif (i==l && j==c)
                         @constraint(m, edges[l,c,i,j] == 0)
                    end
                end
            end
        end
    end
   

    # the number in each island must match the number of bridges that end at that island (counting double bridges as two) and only an island can connect
  
    for i in 1:n
        for j in 1:n
            if t[i,j]>0
                @constraint(m,sum(edges[i,j,i,k]+edges[i,j,k,j] for k in 1:n)==t[i,j])
            else
                 @constraint(m,[k in 1:n, l in 1:n],edges[i,j,k,l]==0)
            end
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
                            @constraint(m,edges[l1,j,l2,j]==0  edges[i,c1,i,c2])
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
    # 2- edges
    # 3 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, edges,time() - start
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve(t)
    # True if the grid has completely been filled
    gridFilled = false

    # True if the grid may still have a solution
    gridStillFeasible = true

    n = size(t, 1)
    tCopy =Array{Int,2}
    tCopy=zeros(Int,n,n)
     while !gridFilled
         println("while grid not filled")
         
        #tableau des iles; une ile = tuple (i,j,val,nbAvailableCo)
        islands=Array{Tuple{Int64,Int64,Any,Int64},1}()
        
        #tableau des arretes: nbre d'aretes entre (i,j) et à (k,l)
        edges=Array{Int,4}
        edges=zeros(Int,n,n,n,n)
     
        for i in 1:n
            for j in 1:n
                push!(islands,(i,j,t[i,j],t[i,j]))
            end
        end
        
        #Sorting islands by their values (small value= island with more constraint)
       
        sort!(islands, by = x -> x[3])
     
        #We save at index (i-1)*n+j the new index of island [i,j]
        new_index=Array{Int,1}
        new_index=zeros(Int,n*n)
        h=1
        for isl in islands
            (l1,c1,v1,co1)=isl
            new_index[(l1-1)*n+c1]=h
            h+=1
        end
        
      
        
            #Go to the first islands because the first cases are empty cells
            c=1
            i=0
            j=0
            val=0
            co=0
            while val==0 && c<n*n
                (i,j,val,co)=islands[c]
                c+=1
            end
            c-=1
      
         gridStillFeasible = true
            
            # While the grid is not filled and it may still be solvable
            while gridStillFeasible

                (i,j,val,co)=islands[c]
                print("nouveau sommet: ")
                println(c," ",i," ",j," ",val," ",co)
                 
                 #We choose a random way of connecting islands to its neighbours
                neighbours=ComputeNeighbours(i,j,t,islands,new_index)
                permutation=Array{Int,1}
              
                #Number of neighbours examinated
                count=0
                
                
                #While an island has neighbours available and not enough connections
                while islands[c][4]>0 && neighbours!=[]
                    count+=1
                    
                    permutation=randperm(size(neighbours,1))
                    print("voisins= ")
                    print(neighbours)
                    print("permutation= ")
                    println(permutation)
                    (k,l,v,nbCo)=neighbours[permutation[1]]
                    print("on choisit de le connecter au voisin= ")
                    println(k,l,v,nbCo)
                    
                    #Set the number of connection to (l,c)
                     minco=min(nbCo,co)
                    co2set=min(rand(1:minco),2)
                    print("on lui met ")
                    print(co2set)
                    println("aretes ")
                    new_indv=new_index[(k-1)*n+l]
                    tuple1=Tuple{Int64,Int64,Any,Int64}[]
                    tuple1= (k,l,v,nbCo-co2set)
                    islands[new_indv] =tuple1
                    tuple2=Tuple{Int64,Int64,Any,Int64}[]
                    tuple2=(i,j,val,co-co2set)
                    islands[c]=tuple2
                    edges[i,j,k,l]=co2set
                    edges[k,l,i,j]=co2set
                  
                  #Mise a jour
                    (i,j,val,co)=islands[c]
                    print("il lui reste ")
                    print(co)
                    println(" ponts a construire encore ")
                    neighbours=ComputeNeighbours(i,j,t,islands,new_index)
                  
                end
                #If an island still lacks connection and doesn't have enough neighbours available
                if (neighbours==[] && islands[c][4]>0)
                    println("pas assez de voisins dispo")
                    gridStillFeasible = false
                end
                
                if c==n*n
                    gridFilled=true
                    gridStillFeasible=false
                    tCopy=displayIntermediate2(edges,t)
                    print(gridFilled,  gridStillFeasible)
                    return tCopy
                else
                    c+=1
                    (i,j,val,co)=islands[c]
                end
            end
            println(gridFilled)
    end
   
    
end

function affiche(tab)
    n=size(tab,1)
    for i in 1:n
        print(tab[i])
    end
end
"""

Compute the neighbours of island (i,j) which connections available are >0
Arguments
- i,j: Int64 coordinates of island
- t: the grid
- Return a list of tuples [island1, island2 , ...,]
"""
 
function ComputeNeighbours(i,j,t,islands,new_index)
   l_up=i
   l_down=i
   c_left=j
   c_right=j
   n=size(t,1)
   res=[]
    #Browsing column
   if l_up>2 && t[l_up-1,j] ==0
       l_up-=2
       while l_up>1 && t[l_up,j]==0
           l_up-=1
       end
     #  print("lup: ")
      # println(l_up)
       new_ind=new_index[(l_up-1)*n+j]
      
       if islands[new_ind][4]>0
       #print("nb co dispo du voisin haut= ")
        #     println(islands[new_ind][4])
        push!(res,islands[new_ind])
       end
   end
   if l_down<n-2 && t[l_down+1,j] ==0
    
       l_down+=2
       while l_down<n && t[l_down,j]==0
           l_down+=1
       end
       print("ldown: ")
             println(l_down)
             new_ind=new_index[(l_down-1)*n+j]
             
       new_ind=new_index[(l_down-1)*n+j]
      if islands[new_ind][4]>0
    #  print("nb co dispo du voisin bas= ")
     # println(islands[new_ind][4])
        push!(res,islands[new_ind])
       end
   end
  if c_left>2 && t[i,c_left-1] ==0
      c_left-=2
      while c_left>1 && t[i,c_left]==0
          c_left-=1
      end
     # print("l_left: ")
           # println(c_left)
            new_ind=new_index[(c_left-1)*n+j]
            
      new_ind=new_index[(i-1)*n+c_left]
      if islands[new_ind][4]>0
     # print("nb co dispo du voisin gauche = ")
       #println(islands[new_ind][4])
             push!(res,islands[new_ind])
        end
  end
  if c_right<n-2 && t[i,c_right+1] ==0
      c_right+=2
      while c_right<n && t[i,c_right]==0
          c_right+=1
      end
      #print("lright: ")
         #   println(c_right)
            new_ind=new_index[(c_right-1)*n+j]
            
      new_ind=new_index[(i-1)*n+c_right]
      if islands[new_ind][4]>0
      #print("nb co dispo du voisin droite= ")
       println(islands[new_ind][4])
           push!(res,islands[new_ind])
      end
  end
return(res)
end


"""
Solve all the instances contained in "../data" through CPLEX and heuristics
The results are written in "../res/cplex" and "../res/heuristic"
Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()


     dataFolder ="/Users/djennaedom/Documents/ENSTA/2A/RO203/Bloc 2/Projet_RO203/jeu2/data/"
     resFolder = "/Users/djennaedom/Documents/ENSTA/2A/RO203/Bloc 2/Projet_RO203/jeu2/res/"


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
        t=readInputFile(dataFolder * file)
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)


                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                  isOptimal, edges, resolutionTime = cplexSolve(t)
                    
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(outputFile,displayIntermediate(edges,t))
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
                fout = open(outputFile, "a")
                println(fout, "solveTime = ", resolutionTime)
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
                
               
            end
            """
            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
            """
        end
    end
end


