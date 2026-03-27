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

# Stubs for extension functions (loaded by ToMAToMakieExt)
function graph_plot end
function plot_births_and_deaths end
export graph_plot, plot_births_and_deaths

end # module ToMATo
