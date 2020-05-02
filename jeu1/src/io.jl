# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)

    m = length(split(data[1], ","))
    t = Array{Int64}(undef, m, m)

    lineNb = 1

    # For each line of the input file
    for line in data

        # TODO

        lineSplit = split(line, ",")

        if size(lineSplit, 1) == m
            for colNb in 1:m

                if lineSplit[colNb] != " "
                    t[lineNb, colNb] = parse(Int64, lineSplit[colNb])
                else
                    t[lineNb, colNb] = 0
                end
            end
        end 
        
        lineNb += 1
    end

    return t

end

"""
Display a grid represented by a 2-dimensional array

Argument:
- t: array of size m*m with values in [0, n] (0 if the cell is empty)
"""
function displayGrid(t::Array{Int64, 2})

    n = size(t, 1)
  
    blockSize = round.(Int, sqrt(n))
    
    # Display the upper border of the grid
    println("|", "-"^(3*n+blockSize-1),"|") 
    
    # For each cell (l, c)
    for l in 1:n
        for c in 1:n
          if c==1
            print("|")
          end
		
          if t[l, c] == 0
            print(" -")
          else
            if t[l, c] < 10
                print(" ")
            end
            
            print(t[l, c])
          end
          print(" ")

          if c==1 || c==(n-1)
            print("|")
          end
            	
        end
        println("| ")
        if l==1  || l== n-1
            println("|", "-"^(3*n+blockSize-1),"|") 
        end
	end 
   println("|", "-"^(3*n+blockSize-1),"|")
end

"""
Display cplex solution

Argument
- x: 3-dimensional variables array such that x[i, j, k, l] = 1 if cell (i, j) has value k
"""
function displaySolution(x::Array{VariableRef,4})

    n = size(x, 1)
    
    blockSize = round.(Int, sqrt(n))

    # Display the upper border of the grid
    println(" ", "-"^(3*n+blockSize-2)) 
    
    # For each cell (l, c)
    for l in 1:n
        for c in 1:n
          if c==1
            print("|")
          end
        
          t = Int64(1)
          for i in  1:n
            if JuMP.value(x[l, c, l, i]) > 0.5
                t = t + 1
            end
          end

          if t == 0
            print(" -")
          else
            if t < 10
                print(" ")
            end
            
            print(t)
          end
          print(" ")
            	
        end
        println("| ")
	end 
   println(" ", "-"^(3*n+blockSize-2)," ")         
end

"""
Save a grid in a text file

Argument
- t: 2-dimensional array of size n*n
- outputFile: path of the output file
"""

function saveInstance(t::Array{Int64, 2}, outputFile::String)

    n = size(t, 1)

    # Open the output file
    writer = open(outputFile, "w")

    # For each cell (l, c) of the grid
    for l in 1:n
        for c in 1:n

            # Write its value
            if t[l, c] == 0
                print(writer, " ")
            else
                print(writer, t[l, c])
            end

            if c != n
                print(writer, ",")
            else
                println(writer, "")
            end
        end
    end

    close(writer)
    
end 


"""
Write a solution in an output stream

Arguments
- fout: the output stream (usually an output file)
- t: 2-dimensional array of size n*n
"""
function writeSolution(fout::IOStream, t::Array{VariableRef, 4})
    
    println(fout, "#t = [")
    n = size(t, 1)
    
    for l in 1:n

        print(fout, "#[ ")
        
        for c in 1:n
            x = Int64(1)
            for i in  1:n
                if JuMP.value(t[l, c, l, i]) > 0.5
                    x = x + 1
                end
            end
            print(fout, string(x) * " ")
        end

        endLine = "]"

        if l != n
            endLine *= ";"
        end

        println(fout, endLine)
    end

    println(fout, "#]")
end

"""
Write a solution in an output stream

Arguments
- fout: the output stream (usually an output file)
- t: 2-dimensional array of size n*n
"""
function writeSolution(fout::IOStream, t::Array{Int64, 2})
    
    println(fout, "#t = [")
    n = size(t, 1)
    
    for l in 1:n

        print(fout, "#[ ")
        
        for c in 1:n
            print(fout, string(t[l, c]) * " ")
        end 

        endLine = "]"

        if l != n
            endLine *= ";"
        end

        println(fout, endLine)
    end

    println(fout, "#]")
end 


"""

Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function performanceDiagram(outputFile::String)

    resultFolder = "../res/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    folderName = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)
            
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)

    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end

    folderCount = 0
    maxSolveTime = 0

    # For each subfolder
    for file in readdir(resultFolder)
            
        path = resultFolder * file
        
        if isdir(path)

            folderCount += 1
            fileCount = 0

            # For each text file in the subfolder
            for resultFile in filter(x->occursin(".txt", x), readdir(path))

                fileCount += 1
                include(path * "/" * resultFile)

                if isOptimal
                    results[folderCount, fileCount] = solveTime

                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end 
            end 
        end
    end 

    # Sort each row increasingly
    results = sort(results, dims=2)

    println("Max solve time: ", maxSolveTime)

    # For each line to plot
    for dim in 1: size(results, 1)

        x = Array{Float64, 1}()
        y = Array{Float64, 1}()

        # x coordinate of the previous inflexion point
        previousX = 0
        previousY = 0

        append!(x, previousX)
        append!(y, previousY)
            
        # Current position in the line
        currentId = 1

        # While the end of the line is not reached 
        while currentId != size(results, 2) && results[dim, currentId] != Inf

            # Number of elements which have the value previousX
            identicalValues = 1

             # While the value is the same
            while results[dim, currentId] == previousX && currentId <= size(results, 2)
                currentId += 1
                identicalValues += 1
            end

            # Add the proper points
            append!(x, previousX)
            append!(y, currentId - 1)

            if results[dim, currentId] != Inf
                append!(x, results[dim, currentId])
                append!(y, currentId - 1)
            end
            
            previousX = results[dim, currentId]
            previousY = currentId - 1
            
        end

        append!(x, maxSolveTime)
        append!(y, currentId - 1)

        # If it is the first subfolder
        if dim == 1

            # Draw a new plot
            plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)

        # Otherwise 
        else
            # Add the new curve to the created plot
            savefig(plot!(x, y, label = folderName[dim], linewidth=3), outputFile)
        end 
    end
end 

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String)
    
    resultFolder = "../res/"
    dataFolder = "../data/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    # Open the latex output file
    fout = open(outputFile, "w")

    # Print the latex file output
    println(fout, raw"""\documentclass{article}

\usepackage[french]{babel}
\usepackage [utf8] {inputenc} % utf-8 / latin1 
\usepackage{multicol}

\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
\setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
\setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
\setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
\setlength{\voffset}{-18pt} % Bon pour DOS
\setlength{\marginparsep}{7pt} % Séparation de la marge
\setlength{\topmargin}{0pt} % Pas de marge en haut
\setlength{\headheight}{13pt} % Haut de page
\setlength{\headsep}{10pt} % Entre le haut de page et le texte
\setlength{\footskip}{27pt} % Bas de page + séparation
\setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

\begin{document}""")

    header = raw"""
\begin{center}
\renewcommand{\arraystretch}{1.4} 
 \begin{tabular}{l"""

    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Array{String, 1}()

    # List of all the instances solved by at least one resolution method
    solvedInstances = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)

            # Add its name to the folder list
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            # Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end 

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Only keep one string for each instance solved
    unique(solvedInstances)

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end

    header *= "}\n\t\\hline\n"

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end

    header *= "\\\\\\hline\n"

    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)

    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1

    # For each solved files
    for solvedInstance in solvedInstances

        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))

        # For each resolution method
        for method in folderName

            path = resultFolder * method * "/" * solvedInstance

            # If the instance has been solved by this method
            if isfile(path)

                include(path)

                println(fout, " & ", round(solveTime, digits=2), " & ")

                if isOptimal
                    println(fout, "\$\\times\$")
                end 
                
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end

        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)

    println(fout, "\\end{document}")

    close(fout)
    
end 
