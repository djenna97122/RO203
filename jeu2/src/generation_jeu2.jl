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
       c = 0
       # While the grid is valid and the required number of cells is not filled we fill in the grid with a new number
       while c < (n*n*density) || !isGridValid
           # Randomly select a cell and a value
           l = ceil.(Int, n * rand())
           c = ceil.(Int, n * rand())
           v = ceil.(Int, 6 * rand())
           
               # Initialisation of a file which will contain the islands to treat
               f=Stack{Array}()
               push!(f,[l,c,v])
               # an island is valid only if the number of connection it can get is at least v
               # While file is not empty we add enough islands that can connect to current island
               while !isempty(f) && isGridValid
                   el=pop!(f)
                   i=el[1]
                   j=el[2]
                   val=el[3]
                   println("i:",i," ","j:",j," ","val:",val)
                   #If there is enough space around (i,j) for value val we add the island to the grid
                   if gets_space(i,j,val,t)
                    println("enough space")
                     t[i,j]=val
                     c+=1
                    end
                    
                    testedCells=0
                    
                   #While the number of connection is insufficient we add a neighbour to the grid and add it to the file to analyze it after
                  
                   while nbco_neighbours(i,j,val,t)<val && testedCells<2*(n-1)
                    
                        v2 = ceil.(Int, 6 * rand())
                        println("v2:",v2)
                        # if ind_lc==1 we add it on the same line if ind_lc==2 we add it on the same colonne
                        ind_lc=ceil.(Int, 2 * rand())
                        position=ceil.(Int, n * rand())
                        println(position)
                        if ind_lc==1 && position != j
                                testedCells+=1
                                if gets_space(i,position,v2,t)
                                    println("ajout meme ligne ","colonne: ",position)
                                   t[i,position]=v2
                                   c+=1
                                   push!(f,[i,position,v2])
                                else
                                    println("not enough space")
                                end
                          
                        elseif ind_lc==2
                            if position !=i
                                testedCells += 1
                                if gets_space(position,j,v2,t)
                                 println("ajout meme colonne ","ligne: ",position)
                                    t[position,j]=v2
                                    c+=1
                                    push!(f,[position,j,v2])
                                else
                                    println("not enough space")
                                end
                            end
                        end
                   #Fin while nbco_neighbours(i,j,val,t)<val && testedCells<2*(n-1)
                   end
                   if (nbco_neighbours(i,j,val,t)<val && testedCells==2*(n-1))
                       isGridValid = false
                   end
               #Fin while f!=[] && while isGridValid
               end
       #Fin c < n*n*density
       end
    # Fin while !isGridValid
    return t
    end

end 

function gets_space(i::Int,j::Int,val::Int,t::Array{Int,2})
    n=size(t,1)
    space=true
    if t[i,j]>0
        space=false
    end
    if i>1
        if t[i-1,j]>0
            space=false
        end
    end
    if i<n
         if t[i+1,j]>0
            space=false
        end
    end
    if j>1
        if t[i,j-1]>0
            space=false
        end
    end
    if j<n
        if t[i,j+1]>0
            space=false
        end
    end
    nb_edges=0
    if i==1 || i==n
        nb_edges+=1
    end
    if j==1 || j==n
        nb_edges+=1
    end
    nb_voisin_max=0
    if val==5 || val==6
        nb_voisin_max=1
    end
    if val==3 || val==4
        nb_voisin_max=2
    end
    if val==1 || val==2
        nb_voisin_max=3
    end
    if nb_edges>nb_voisin_max
        space=false
    end
    return space
end

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

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



