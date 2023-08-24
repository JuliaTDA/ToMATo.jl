using Distances
using NearestNeighbors
using NetworkLayout
using Base.Threads
import GeometricDatasets as gd
using AlgebraOfGraphics
using DataFrames
using Graphs
using Makie
using GLMakie

X = hcat(randn(2, 800), randn(2, 800) .+ 4)
k = x -> exp(-(x / 2)^2)
ds = gd.Filters.density(X, kernel_function = X -> X .|> k |> sum)

fig, ax, pt = scatter(X[1, :], X[2, :], color = ds);
Colorbar(fig[1, 2], colorrange = extrema(ds))
fig

ids = sortperm(ds, rev = true)

g = Graph(Int64)
add_vertices!(g, size(X)[2])

max_k_ball = 50
min_k_ball = 3
k_nn = 2

ϵ = 0.7
bt = BallTree(X)

for v1 ∈ 1:size(X)[2]
    p = X[:, v1]
    close_ones = inrange(bt, p, ϵ, true)
    # close_ones = Int64[]

    # length(close_ones) == 0 && continue
        
    if length(close_ones) < min_k_ball + 1        
        close_ones, _ = knn(bt, p, k_nn + 1, true, x -> false)        
    end

    if length(close_ones) > max_k_ball
        close_ones = close_ones[1:max_k_ball]
    end
    
    # get at most max_k_ball edges
    for v2 ∈ close_ones
        v1 == v2 && continue
        add_edge!(g, v1, v2)
    end
end

g

# 
node_positions = [Point2(X[:, i]) for i ∈ 1:size(X)[2]]

fig, ax, plt = scatter(node_positions);

for e ∈ edges(g)
    e.src == e.dst && continue
    linesegments!(ax, [node_positions[e.src], node_positions[e.dst]], color = :black)
end;

fig

clusters = zeros(Int64, size(X)[2])

i = ids[1]
ds[i]
ds |> maximum

for i ∈ ids   
    nbs = neighbors(g, i)
    pushfirst!(nbs, i)

    id_max = nbs[findmax(ds[nbs])[2]]

    if i == id_max
        clusters[i] = i
    else
        clusters[i] = clusters[id_max]
    end
end
clusters
clusters |> unique

dados = DataFrame(X', :auto)
dados.cor = clusters .|> string

axis = (width = 600, height = 600)
pt = data(dados) * mapping(:x1, :x2, color = :cor)
draw(pt, axis = axis)


# https://juliacollections.github.io/DataStructures.jl/stable/disjoint_sets/
using DataStructures
U = IntDisjointSets(0)
U
n = push!(U)
n
push!(U, 1)
U
union!(U, 3, 5)
U
root_union!(U, 1, 2)
U
find_root(U, 3)
in_same_set(U, 1, 3)