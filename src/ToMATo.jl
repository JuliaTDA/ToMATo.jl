module ToMATo

using GeometricDatasets
using Distances
using NearestNeighbors
using Base.Threads
using AlgebraOfGraphics
using GLMakie
using Graphs
using ProgressMeter
using Quartomenter;
export @qdoc;
export PointCloud;

include("graph.jl");
export proximity_graph;

include("tomato algorithm.jl");
export tomato, plot_births_and_deaths;

include("plots.jl");
export graph_plot;

end # module ToMATo
