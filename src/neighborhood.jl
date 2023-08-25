using Distances
using NearestNeighbors
using Base.Threads
import GeometricDatasets as gd
using AlgebraOfGraphics
using DataFrames
using Graphs

X = hcat(randn(2, 800), randn(2, 800) .+ 4)
k = x -> exp(-(x / 2)^2)
ds = gd.Filters.density(X, kernel_function = X -> X .|> k |> sum)

fig, ax, pt = scatter(X[1, :], X[2, :], color = ds);
Colorbar(fig[1, 2], colorrange = extrema(ds))
fig

global g = Graph(Int64)
add_vertices!(g, size(X)[2])

max_k_ball = 6
min_k_ball = 3
k_nn = 2

ϵ = 0.4
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

update_cluster!(cluster, from, to) = replace!(x -> x == from ? to : x, cluster)

ids = sortperm(ds, rev = true)
global clusters = zeros(Int64, size(X)[2])
τ = 0.1

i = ids[2]
for i ∈ ids#[1:2]
    N = neighbors(g, i)
    filter!(x -> ds[x] > ds[i], N)

    if length(N) == 0
        clusters[i] = i
        continue
    end

    # |N| > 0
    c_max = clusters[argmax(x -> ds[x], N)]
    clusters[i] = c_max

    j = N[1]
    for j ∈ N
        c_j = clusters[j]

        # if the clusters are equal, skip
        c_max == c_j && continue

        # if c_j has no cluster, put j on c_max
        if c_j == 0
            update_cluster!(clusters, j, c_max)
            continue
        end

        # If the lowest of them is just a bit below the current height ds[i],        
        # we then fuse the clusters        
        if min(ds[c_max], ds[c_j]) < ds[i] + τ
            from, to = sort([c_max, c_j], by = x -> ds[x])
            update_cluster!(clusters, from, to)
        end
    end    
end

clusters

clusters |> unique

using AlgebraOfGraphics

df = DataFrame(X', :auto)
df.cluster = clusters .|> string

using GLMakie
plt = data(df) * mapping(:x1, :x2, color = :cluster)
draw(plt)