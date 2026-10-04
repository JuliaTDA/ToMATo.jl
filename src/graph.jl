"""
    proximity_graph(X::EuclideanSpace, ϵ; max_k_ball=5, min_k_ball=1, k_nn=3)

Calculate the proximity graph of a metric space `X` and return a graph.

For each point, queries a Euclidean ϵ-ball including self. If the list has fewer
than `min_k_ball + 1` entries, queries `k_nn + 1` nearest samples instead. This
fallback can introduce edges longer than ϵ; it requires `k_nn < length(X)`.

The sorted neighbour list is truncated to `max_k_ball` entries before removing
self. The graph is undirected and unions all retained edges, so final vertex
degree can exceed this cap. Set `min_k_ball=0` and `max_k_ball=length(X)` for a
radius graph without fallback or truncation. Returns a `Graphs.SimpleGraph`.
"""
function proximity_graph(X::EuclideanSpace, ϵ; max_k_ball=5, min_k_ball=1, k_nn=3)
    n = length(X)
    bt = BallTree(X)

    # Collect neighbor lists per vertex (no shared mutation)
    neighbor_lists = Vector{Vector{Int}}(undef, n)

    @threads for v1 in 1:n
        p = X[v1]
        close_ones = inrange(bt, p, ϵ, true)

        if length(close_ones) < min_k_ball + 1
            close_ones, _ = knn(bt, p, k_nn + 1, true, x -> false)
        end

        if length(close_ones) > max_k_ball
            close_ones = close_ones[1:max_k_ball]
        end

        neighbor_lists[v1] = filter(!=(v1), close_ones)
    end

    g = Graph(n)
    for v1 in 1:n
        for v2 in neighbor_lists[v1]
            add_edge!(g, v1, v2)
        end
    end

    return g
end
