"""
    knn_density(X::MetricSpace; k=10, d=dist_euclidean)

Estimate a density score at each point as the inverse of the distance to the
k-th nearest sample, with a `1e-10` stabilizer. The query point itself counts
among the `k` samples: for distinct points, `k=2` reaches the nearest other point,
whereas `k=1` gives approximately `1e10` everywhere. Higher scores correspond
to smaller local neighbour distances; they are not normalized probabilities.

This is a simple density estimator useful for ToMATo clustering. For each point,
the k-nearest-neighbor distance is computed via `distance_to_measure`, and the
density is returned as the reciprocal.

Use `ToMATo.knn_density` explicitly when MetricSpaces is also loaded, since
that package exports a different function with the same name. The distance
argument changes the density estimate, not the metric used by `proximity_graph`.
"""
function knn_density(X::MetricSpace; k::Integer=10, d=dist_euclidean)
    dtm = distance_to_measure(X, X; d=d, k=k, summary_function=maximum)
    return 1.0 ./ (dtm .+ 1e-10)
end
