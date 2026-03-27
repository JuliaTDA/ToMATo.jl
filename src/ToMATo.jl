module ToMATo

using MetricSpaces
using Distances
using NearestNeighbors
using Base.Threads
using Graphs
using ProgressMeter

include("density.jl")
export knn_density

include("graph.jl")
export proximity_graph

include("tomato algorithm.jl")
export tomato

end # module ToMATo
