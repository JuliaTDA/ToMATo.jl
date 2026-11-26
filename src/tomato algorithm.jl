"""
    tomato(X::MetricSpace, g::Graph, ds::Vector{<:Real}, τ::Real=Inf;
           max_cluster_height::Real=0)

Calculate the ToMATo clustering of the metric space `X`, with proximity-graph `g`,
relative to aligned finite density values `ds` and a nonnegative threshold `τ`.
An eligible merge occurs when the shorter peak's height above the current
density is strictly less than `τ`. Increasing `τ` allows more merges; the
default `τ=Inf` applies no finite prominence cutoff, while `τ=0` retains modes
for distinct densities.

Returns two objects:

- `clusters`: a vector of integers, one for each point of `X`,
  with the corresponding cluster number.

- `births_and_deaths`: a dictionary mapping original peak point IDs to
  `[birth_density, death_density]`. A finite death is recorded only for an
  accepted merge in this run. `death_density=Inf` is the sentinel for an
  unmerged peak; do not interpret `birth_density - Inf` as a finite lifetime.
  Use the unrestricted `τ=Inf` run to inspect recorded finite prominences.

Final positive labels rank surviving peaks by descending density. Equal-density
neighbours do not automatically join. At a saddle, the component of the densest
upper neighbour is compared with the other upper components in vertex order.
Each accepted merge keeps the higher peak. On a peak-density tie, the peak from
the other component survives. Later comparisons use the surviving peak.

`max_cluster_height`: every cluster whose peak is less than
`max_cluster_height` will be fused together in a single cluster
labeled `0`. Set to `0` (default) to keep all clusters.
"""
function tomato(
    X::MetricSpace, g::Graph, ds::Vector{<:Real}, τ::Real=Inf;
    max_cluster_height::Real=0
    )
    n = length(X)
    parent = collect(1:n)
    sizes = ones(Int, n)
    peaks = collect(1:n)
    births_and_deaths = Dict{Int, Vector{<:Real}}()

    for i in sortperm(ds; rev=true)
        adjacent = neighbors(g, i)
        higher = filter(j -> ds[j] > ds[i], adjacent)
        if isempty(higher)
            births_and_deaths[i] = [ds[i], Inf]
            continue
        end

        anchor = argmax(j -> ds[j], higher)
        component = _tomato_root!(parent, anchor)
        parent[i] = component
        sizes[component] += 1
        for j in higher
            other = _tomato_root!(parent, j)
            component == other && continue
            a, b = peaks[component], peaks[other]
            min(ds[a], ds[b]) < ds[i] + τ || continue

            survivor, absorbed = ds[a] > ds[b] ? (a, b) : (b, a)
            births_and_deaths[absorbed][2] = ds[i]

            # Union by size without changing which peak labels the union.
            if sizes[component] < sizes[other]
                component, other = other, component
            end
            parent[other] = component
            sizes[component] += sizes[other]
            peaks[component] = survivor
        end
    end

    point_peaks = [peaks[_tomato_root!(parent, i)] for i in 1:n]
    surviving_peaks = sort!(unique(point_peaks); by=i -> ds[i], rev=true)
    labels = zeros(Int, n)
    for (label, peak) in enumerate(surviving_peaks)
        ds[peak] < max_cluster_height || (labels[peak] = label)
    end

    return labels[point_peaks], births_and_deaths
end

function _tomato_root!(parent, i)
    while i != parent[i]
        parent[i] = parent[parent[i]]
        i = parent[i]
    end
    return i
end
