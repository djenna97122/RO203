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
        c = 1
	
       # While the grid is valid and the required number of cells is not filled
        while isGridValid && c < (4*n)
	
	# Randomly select a cell by its edge(1:up, 2:left,3: bottom, 4:right) and its position and a value 
            edge = ceil.(Int, 4 * rand()) 
            p = ceil.(Int, n * rand())
           
	    if edge==1 
		i=1
		j=p
	    else if edge==2
		i=p
		j=1
		
	    else if edge ==3
		i=n+2
		j=p
	   
	    else if edge==4
		i=p
		j=n+2
	    end
	 v= ceil.(Int, n * rand())

	#True if cell is a corner
            isCellCorner= ( (i,j)==(1,1) ||(i,j)==(1,n+2)||(i,j)==(n+2,1)||(i,j)==(n+2,n+2) )

	# True if cell (i,j) is free
            isCellFree = t[i, j] == 0

	 # True if value v can be set in cell (i, j)
            isValueValid = isValid(t, i, j, v)
	

            # Number of cells considered in the grid
            testedCells = 1
	 
        # While it is not possible to assign the value to the cell
            # (we assign a value if the cell is free, not a corner and the value is valid)
            # and while all the cells have not been considered
            while !(isCellFree && isValueValid ) && isCellCorner && testedCells < 4*n


  	# If the cell has already been assigned a number or is a corner we change cell
		
                if !isCellFree || is CellCorner
                    
                    # Go to the next cell       
			if (i==1 && j<n+2)
			    j+=1
			else if (j=n+2 && i< n+2)
			    i+=1
			else if (i=n+2 && j>1)
			    j-=1
			else if (j=1 && i<1)
			    i-=1
		end
		testedCells += 1
	        isCellFree = t[i, j] == 0
		isValueValid = isValid(t, i, j, v)
		

	   
	 # If the cell has not already been assigned a value and the value is not valid we change value
		else
	 	    v = rem(v, n) + 1
		end

	     end
	 if testedCells == 4*n
                isGridValid = false
	c+=1
	
	end
end


end 


"""
Test if cell (i, j) can be assigned value v

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
- i, j: considered cell
- v: value considered

Return: true if t[l, c] can be set to v; false otherwise
"""
function isValid(t::Array{Int64, 2}, i::Int64, j::Int64, v::Int64) 
	
	n = size(t, 1)
        isValid = true
	
	
	
	 if v==1 || v==n
	   #If cell on top or bottom 
	    if i==1 || i==n+2
	        # Test if v appears in line i 
		c=2 
		while isValid && c <= n+1
                  if t[i, c] == v
     	              isValid = false
       		  end
       		  c += 1
           

                 # Test if v appears in front of cell
   		 f=n-i+3
		 if t[f, c] == v
     	               isValid = false
       		  end

	    #If cell on left or right 
	    if j==1 || j==n+2
	        # Test if v appears in column j  
		l=2
		while isValid && l <= n+1
                  if t[l, j] == v
     	              isValid = false
       		  end
       		  l += 1
           

                 # Test if v appears in front of cell 
   		 f=n-j+3
		 if t[f, f] == v
     	               isValid = false
       		  end

	 end
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end


