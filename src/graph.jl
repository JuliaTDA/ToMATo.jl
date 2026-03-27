"""
    proximity_graph(X::EuclideanSpace, ϵ; max_k_ball=5, min_k_ball=1, k_nn=3)

Calculate the proximity graph of a metric space `X` and return a graph.

For each point x in X, creates an ϵ-ball and stores all neighbor ids.
If the number of neighbors is less than `min_k_ball`, searches for the
`k_nn` nearest neighbors instead. At most `max_k_ball` edges per point
are kept.
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
