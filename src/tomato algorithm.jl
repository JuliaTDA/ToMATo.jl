"""
    tomato(
        X::PointCloud, g::Graph, ds::Vector{<:Real}, τ::Real = Inf;
        max_cluster_height::Real = τ
        )    

Calculates the ToMATo clustering of the metric space X,
with proximity-graph g, relative to the function ds and
the parameter τ.

Returns two objects: 

- `clusters`: a vector of integers, one for each point of `X`,
with the corresponding cluster number.

- `births_and_deaths`: a dictionary with the birth and death of
each peak that arised in the ToMATo algorithm. This is used
to decide the best value of τ.

`max_cluster_height` is equal to τ in default; this means
that every clusters whose peal is less than `max_cluster_height`
will be fused together in a single cluster called `0`.
Set to Inf to ignore fusing of short peaks.

"""
function tomato(
    X::PointCloud, g::Graph, ds::Vector{<:Real}, τ::Real = Inf;
    max_cluster_height::Real = 0
    )
    sorted_ids = sortperm(ds, rev = true)
    clusters = zeros(Int64, size(X)[2])
    births_and_deaths = Dict{Int64, Vector{<: Real}}()

    for i ∈ sorted_ids
        N = neighbors(g, i) |> copy
        filter!(x -> ds[x] > ds[i], N)
    
        # if there is no upper-neighbor
        if length(N) == 0
            clusters[i] = i
            births_and_deaths[i] = [ds[i], Inf]
            continue
        end
    
        c_max = clusters[argmax(x -> ds[x], N)]
        clusters[i] = c_max    
        
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
            # we fuse the clusters        
            if min(ds[c_max], ds[c_j]) < ds[i] + τ
                from, to = sort([c_max, c_j], by = x -> ds[x])
                births_and_deaths[from][2] = ds[i]
                replace!(clusters, from => to)
            end
        end    
    end

    sorted_clusters = sort(clusters |> unique, by = x -> ds[x], rev = true)

    cluster_dict = 
        map(sorted_clusters) do cl

            if  (ds[cl] < max_cluster_height)
                true_number = 0
            else
                true_number = findfirst(x -> x == cl, sorted_clusters)
            end

            Dict(cl => true_number)
        end
    
    cluster_dict = merge(cluster_dict...)

    final_clusters = replace(clusters, cluster_dict...)

    return final_clusters, births_and_deaths
    
end

"""
    plot_births_and_deaths(
        births_and_deaths; 
        max_value_multiplier = 1.3
        )

Plot the `births_and_deaths` of the persistence diagram obtained
with `tomato`. This is useful to decide which parameter
τ is the most reasonable, before applying the ToMATo algorithm again.
"""
function plot_births_and_deaths(births_and_deaths; max_value_multiplier = 1.3)
    bds = [[x[2][1], x[2][1] - x[2][2]] for x ∈ births_and_deaths] |> stack
    max_value = filter(!isinf, bds[2, :]) |> maximum
    replace!(bds, -Inf => max_value * max_value_multiplier)    
    scatter(bds)
end