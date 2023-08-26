update_cluster!(cluster, from, to) = replace!(x -> x == from ? to : x, cluster)

"""
    tomato(X, g, ds, τ)

Calculates the ToMATo clustering of the metric space X,
with proximity-graph g, relative to the function ds and
the parameter τ
"""
function tomato(X, g, ds, τ)
    sorted_ids = sortperm(ds, rev = true)
    global clusters = zeros(Int64, size(X)[2])
    global births_and_deaths = Dict{Int64, Vector{<: Real}}()

    for i ∈ sorted_ids
        N = neighbors(g, i)
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
                update_cluster!(clusters, from, to)
            end
        end    
    end

    return clusters, births_and_deaths
    
end

function plot_births_and_deaths(births_and_deaths)
    bds = [[x[2][1], x[2][1] - x[2][2]] for x ∈ births_and_deaths] |> stack
    max_value = filter(!isinf, bds[2, :]) |> maximum
    replace!(bds, -Inf => max_value*1.1)    
    scatter(bds)
end