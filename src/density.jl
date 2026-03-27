"""
    knn_density(X::MetricSpace; k=10, d=dist_euclidean)

Estimate density at each point as the inverse of the distance to the k-th nearest neighbor.
Higher values correspond to denser regions.

This is a simple density estimator useful for ToMATo clustering. For each point,
the k-nearest-neighbor distance is computed via `distance_to_measure`, and the
density is returned as the reciprocal.
"""
function knn_density(X::MetricSpace; k::Integer=10, d=dist_euclidean)
    dtm = distance_to_measure(X, X; d=d, k=k, summary_function=maximum)
    return 1.0 ./ (dtm .+ 1e-10)
end
