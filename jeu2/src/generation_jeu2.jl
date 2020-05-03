# This file contains methods to generate a data set of instancesof bridges grids
include("io_jeu2.jl")

Pkg.add("DataStructures")
using DataStructures

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

   # True if the current grid has no conflicts
    isGridValid = false
    t = []
    
   # While a valid grid is not obtained we initialize a new grid
    while !isGridValid
       
       t = zeros(Int, n, n)
       isGridValid = true
       
       #number of cells filled
       cells = 0
       
       # While the grid is valid and the required number of cells is not filled we fill in the grid with a new number
       while cells < (n*n*density) && isGridValid
           
           # Randomly select a cell and a value
           i = ceil.(Int, n * rand())
           j= ceil.(Int, n * rand())
           val = ceil.(Int, 6 * rand())
            
           # True if a value has not already been assigned to the cell (l, c) or if it is not a cell between 2 islands neighbours
           isCellFree = t[i, j] ==0
           
           # True if value v can be set in cell (l, c)
           isValueValid = isValid(t, i, j, val)
           
           # Number of value that we already tried to assign to cell (l, c)
           attemptCount = 0
           
            # Number of cells considered in the grid
            testedCells = 1
        
            #While the cell is not valid and while all the cells have not been considered
             while !(isCellFree&& isValueValid) && testedCells < n*n
                
                if !isCellFree  || attemptCount == n
                    # Go to the next cell
                    if j < n
                        j += 1
                    else
                        if i < n
                            i += 1
                            j = 1
                        else
                            i = 1
                            j = 1
                        end
                    end
                    
                    testedCells += 1
                    
                    isCellFree = t[i, j] == 0
                    isValueValid = isValid(t,i, j,val)
                    attemptCount = 0
                else
                    val=rem(val,n)+1
                    attemptCount += 1

                end
                
            #Fin while !isCellFree && testedCells < n*n
            end
           
            if testedCells == n*n
               isGridValid = false
               println("toutes cellules testees")
            else
                t[i,j]=val
                (t,add)=set_void(i,j,t)
                cells+=add
                Atraiter=[(i,j,val)]
                while Atraiter!=[] && isGridValid
                
                    (l,c,v)=popfirst!(Atraiter)
                    cells+=1
                    
                    (b,l1,c1,val1,l2,c2,val2)=set_neighbours(l,c,v,t)
        
                    #If setneighbours hasn't found available cells for the neighbours of cells, the grid is not valid
                    if !b
                        isGridValid = false
                        println("pas de neighbours possibles")
                    else
                        push!(Atraiter,(l,c1,val1))
                        push!(Atraiter,(l2,c,val2))
                        t[l,c1]=val1
                        t[l2,c]=val2
                
                       #Our program impose cells to be one box away at list
                         
                       if val1>0
                        (t,add)=set_void(l,c1,t)
                        cells+=add
                    end
                    if val2>0
                       (t,add)=set_void(l2,c,t)
                       cells+=add
                    end
                        
                      #We set cells between (l,c) and its neighbours as unavailable
                        if val1 >0
                            if c1<c #if cell1 is on the left of cell
                                for k in c1+1:c-1
                                    t[l,k]=-1
                                    cells+=1
                                end
                            else # cell1 is on the right of cell
                                for k in c+1:c1-1
                                    t[l,k]=-1
                                    cells+=1
                                end
                            end
                        end
                        if val2 >0
                            if l2<l #if cell2 is on top of cell
                                for k in l2+1:l-1
                                    t[k,c]=-1
                                    cells+=1
                                end
                            else #if cell2 is under cell
                                for k in l+1:l2-1
                                    t[k,c]=-1
                                    cells+=1
                                end
                            end
                        end
                    #Fin if !b
                    end
                  
                #Fin while Atraiter!=[]
                end
            #Fin if tested cells=n*n
            end
        #Fin while c < (n*n*density) && isGridValid
        end
     #Fin while !isGridValid
     end
     return t
end

function isValid(t,i,j,v)
    valid=true
    if ((i,j)==(1,1) || (i,j)==(1,5) ||(i,j)==(5,1) ||(i,j)==(5,5)) && v>=5
        valid=false
    end
    return valid
end
"""
Compute the potential neighbours of an island
return a tuple with
- a boolean res: true if we have succeed to generate neighbours for the island (l,c)
- coordinates of neighbours and their value. First is on the same line, second one on the same column
"""
function potential_neighbours(i,j,t)
    l_up=i
    l_down=i
    c_left=j
    c_right=i
    n=size(t,1)
    
    if l_up>2 && t[l_up-1,j] ==0
          l_up-=2
          while l_up>1 && t[l_up,j]==0
              l_up-=1
          end
          if  t[l_up,j]==-1 || (t[l_up,j]!=0) #no neighbours possible on the upside otherwise bridges will cross
            l_up=0
        else
            l_up+=2
          end
      end
     
      if l_down<n-2 && t[l_down+1,j] ==0
          l_down+=2
          while l_down<n && t[l_down,j]==0
              l_down+=1
          end
          
          if  t[l_down,j]==-1 || (l_down==1 && t[l_up,j]!=0)
            l_down=0
          end
      end
     
     if c_left>2 && t[i,c_left-1] ==0
         c_left-=2
         while c_left>1 && t[i,c_left]==0
             c_left-=1
         end
        if  t[l,c_left]==-1 #no neighbours possible on the left side otherwise bridges will cross
           c_left=0
         end
     end
    
     if c_right<n-2 && t[i,c_right+1] ==0
         c_right+=2
         while c_right<n && t[i,c_right]==0
             c_right+=1
         end
         if  t[l,c_right]==-1 #no neighbours possible on the left side otherwise bridges will cross
           c_right=0
         end
     end
return (l_up,l_down,c_left,c_right)
end

"""
Modify the grid t so islands are at least on cell away
return: grid t modified
"""
function set_void(l,c,t)
    cells=0
    if l>1
        if t[l-1,c]==0
            t[l-1,c]=-1
            cells+=1
        end
    end
    if l<n
        if t[l+1,c]==0
           t[l+1,c]=-1
           cells+=1
        end
    end
    if c>1
        if t[l,c-1]==0
            t[l,c-1]=-1
            cells+=1
        end
    end
    if c<n
        if t[l,c+1]==0
            t[l,c+1]=-1
            cells+=1
        end
    end
return(t,cells)
end

"""
Compute the random values and positions for the neighbours of island(l,c,v)
"""
function set_neighbours(l,c,v,t)
    c1=ceil.(Int, n * rand())
    l2=ceil.(Int, n * rand())
    res=true
    attemptCount=0
    while t[l,c1]!=0 && attemptCount<(n-1)
        if c1<n
            c1=rem(c1,n)+1
        end
        attemptCount+=1
    end
    
    if (attemptCount==(n-1) && t[l,c1]!=0)
        res=false
    end
    
    attemptCount=0
    while t[l2,c]!=0 && attemptCount<2(n-1)
        if l2<n
            l2=rem(l2,n)+1
        end
        attemptCount+=1
    end
   if (attemptCount==(n-1) && t[l2,c]!=0)
        res=false
    end
    
    val1=0
    val2=0
    while val1+val2 <v
        if (l,c1)==(1,1) || (l,c1)==(1,5) ||(l,c1)==(5,1) ||(l,c1)==(5,5)
            val1=floor.(Int, 5 * rand())
        end
        
        if (l2,c)==(1,1) || (l2,c)==(1,5) ||(l2,c)==(5,1) ||(l2,c)==(5,5)
            val1=floor.(Int, 5 * rand())
        end
        val1=floor.(Int, 7 * rand())
        val2=floor.(Int, 7 * rand())
       
    end
return(res,l,c1,val1,l2,c,val2)
end

"""

return the limits to set neighbours for (i,j) in t in each direction if limit=0 it means no neighbours can be set
"""
function set_limits(i,j,t)
end


"""
Compute the number of connection an island can set to its neighbours
"""
function nbco_neighbours(i::Int64,j::Int64,val::Int64,t::Array{Int,2})
    l_up=i
    l_down=i
    c_left=j
    c_right=i

    n=size(t,1)
    res=0
    if l_up>2 && t[l_up-1,j] ==0
     
        l_up-=2
        while l_up>1 && t[l_up,j]==0
            l_up-=1
        end
        res+=min(2,t[l_up,j])
    end
    if l_down<n-2 && t[l_down+1,j] ==0
      
        l_down+=2
        while l_down<n && t[l_down,j]==0
            l_down+=1
        end
        res+=min(t[l_down,j],2)
    end
   if c_left>2 && t[i,c_left-1] ==0
    
       c_left-=2
       while c_left>1 && t[i,c_left]==0
           c_left-=1
       end
       res+=min(t[i,c_left],2)
   end
  
   if c_right<n-2 && t[i,c_right+1] ==0

       c_right+=2
      
       while c_right<n && t[i,c_right]==0
           c_right+=1
       end
       res+=min(2,t[i,c_right])
   end
   return res
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""


   function generateDataSet()
       # For each grid size considered
        for size in [7, 10, 15, 20,50]
           for instance in 1:10

               fileName = "/Users/djennaedom/Documents/ENSTA/2A/RO203/Bloc 2/Projet_RO203/jeu1/data/instance_t" * string(size) * "_" * string(instance) * ".txt"

               if !isfile(fileName)
                   println("-- Generating file " * fileName)
                   saveInstance(generateInstance(size), fileName)
               end
           end
       end
   end





