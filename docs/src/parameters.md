# Parameters, outputs and practical limits

```@meta
CurrentModule = ToMATo
```

## Keep point identities aligned

For `n` points, `g` must have `n` vertices and `ds` must have `n` real values. Vertex `i`, `ds[i]` and `X[i]` must refer to the same observation. Sorting or filtering one without updating the others changes the problem.

Use a nonempty dataset with finite density values and a nonnegative threshold. These are practical requirements; the implementation does not validate every inconsistency. In `tomato`, coordinates themselves are not recomputed: density ordering and graph adjacency drive merging.

## Density scale

MetricSpaces also exports a function named `knn_density`. When loading both packages, use `ToMATo.knn_density(...)` explicitly to select this package's inverse-kth-neighbour estimator; the other function has a different definition.

[`knn_density`](@ref) computes `ρᵢ = 1 / (rₖ,ᵢ + 10⁻¹⁰)`, where `rₖ,ᵢ` is the largest distance among the `k` nearest samples in `X`. It is a density score, not a probability density integrating to one, and does not include a dimension-dependent ball-volume factor.

| Argument | Default | Interpretation |
| :--- | :--- | :--- |
| `k` | `10` | Samples in the distance query, including the point itself |
| `d` | `dist_euclidean` | Pairwise distance function for this density estimate |

With distinct points and `k=2`, the distance is to the nearest **other** point. `k=1` sees self and gives approximately `10¹⁰` everywhere; avoid it for informative estimation. Duplicates can also cause very large densities. Choose `2 ≤ k ≤ length(X)` and inspect `extrema(ds)`; larger `k` smooths fine variations, smaller `k` emphasizes local detail. MetricSpaces currently caps the density query's effective `k` at the available sample count.

Scale or standardize features to reflect meaningful distances before estimating density and building the graph. Multiplying coordinates by a positive factor approximately divides density scores and prominences by that factor, so reconsider `τ`. Supply your own finite score vector when inverse neighbour distance does not fit the application.

## Graph construction

[`proximity_graph`](@ref) accepts `EuclideanSpace` and uses a Euclidean `BallTree`. The optional density distance `d` does **not** change the graph metric. For another adjacency model, construct a `Graphs.SimpleGraph` yourself and pass it to `tomato`.

| Argument | Default | Implementation behavior |
| :--- | :--- | :--- |
| `ϵ` | Required | Radius query around each point |
| `min_k_ball` | `1` | Uses fallback if radius list has fewer than `min_k_ball + 1` entries |
| `k_nn` | `3` | Fallback requests `k_nn + 1` samples, including self |
| `max_k_ball` | `5` | Truncates each queried list **before removing self** |

Radius results are sorted by distance. With distinct points a cap of `5` usually retains at most four outgoing neighbours per query. The graph is undirected: either endpoint can introduce an edge, so final degree can exceed the cap. Fallback edges may be longer than `ϵ`.

Use `0 ≤ k_nn < length(X)` if fallback is possible, `min_k_ball ≥ 0`, a positive cap, and nonnegative radius. To approximate a pure radius graph, set `min_k_ball=0` and `max_k_ball=length(X)`: this disables fallback and avoids truncation. High caps cost memory and produce more edges.

Check connected components and edge lengths. A small radius can fragment a group; a large radius or fallback can bridge groups. Revisit the graph before interpreting disconnected survivors as distinct density populations.

## Thresholds and returned objects

[`tomato`](@ref) returns `(clusters, births_and_deaths)`, not a custom result struct.

| Output | Contents | Interpretation |
| :--- | :--- | :--- |
| `clusters` | Integer vector, one entry per point | Final cluster labels |
| `births_and_deaths` | `peak_point_id => [birth, death]` dictionary | Peak density and actual merge density in this run |

Positive labels are ranked by descending surviving peak density. They are not stable IDs across runs; dictionary keys are not those labels. Compare memberships rather than label numbers across parameters.

The test is `min(peak₁, peak₂) < current_density + τ`; equality does not merge. For distinct finite densities:

- `τ=0` retains each detected local mode.
- Increasing `τ` permits additional eligible merges.
- `τ=Inf` applies no finite prominence cutoff to the tested merges; disconnected components still cannot merge.

`death=Inf` means **no merge recorded in that run**. It does not imply survival under every larger threshold. Obtain finite prominences from an `Inf` run by subtracting only entries with finite death, keeping survivors separate. `birth - Inf = -Inf` is not a negative prominence.

`max_cluster_height=0` is the default. A surviving cluster with peak density **strictly less** than the floor receives label `0`; all such clusters share it. Arbitrary negative scores can therefore become background at the default floor. The floor changes labels after merging without rewriting birth/death entries.

## Plateaus and other edge cases

Only **strictly higher** density neighbours count as upper neighbours. Equal-density neighbours do not automatically join. A constant-density connected graph can produce one mode per point even at `τ=Inf`. Duplicates, symmetric datasets and rounded scores can expose this behavior.

Investigate ties explicitly. For plateau-aware merging, preprocess with a documented domain-specific rule or choose an implementation with plateau handling. Arbitrary jitter changes the model and can make results seed dependent.

An isolated point becomes a mode with death `Inf`. Handle empty datasets before calling the pipeline: downstream operations expect nonempty data. The routines are intended for finite scores; `NaN` and infinities can disrupt ordering and comparisons.

## Multiway saddles in the current implementation

There is a second limit even without ties. At a point meeting three or more current modes, the algorithm chooses an initial component `c_max` from the densest upper neighbour. If the first merge absorbs that component into a higher peak, `c_max` is not updated for subsequent comparisons at the same point. A later replacement can then target a label that has already disappeared, leaving modes unmerged.

This seven-vertex connected graph reproduces the behavior with distinct densities:

```@example multiway
using ToMATo, MetricSpaces, Graphs

X = EuclideanSpace([[Float64(i), 0.0] for i in 1:7])
g = SimpleGraph(7)
for (a, b) in [(1, 4), (2, 5), (3, 6), (4, 7), (5, 7), (6, 7)]
    add_edge!(g, a, b)
end
ds = [5.0, 7.0, 8.0, 3.0, 2.0, 1.5, 1.0]
labels, modes = tomato(X, g, ds, Inf)
@assert length(connected_components(g)) == 1
@assert length(unique(labels)) == 2
labels
```

The two unmerged peaks receive `death=Inf`. This is a current implementation limitation, not evidence of two graph components or a finite prominence gap. For analyses relying on a complete merge hierarchy, verify multiway events against an independent implementation. The earlier path example avoids this case and demonstrates the intended pairwise threshold rule.

## Troubleshooting and cost

| Symptom | Inspect first |
| :--- | :--- |
| Many clusters even at `Inf` | Disconnected components, density ties, truncation cap, multiway saddle limitation |
| Everything becomes one cluster | Graph bridges, fallback edges, threshold too large |
| Very large density scores | `k=1`, duplicates, feature scaling |
| Neighbour-query bounds error | Graph fallback `k_nn + 1` relative to dataset size |
| Label numbers change after an edit | Labels rank peak densities; compare membership |
| Finite prominences disappear | Finite-threshold runs record accepted merges only |

The density estimator evaluates pointwise distances through MetricSpaces and can require quadratic work. A BallTree accelerates graph queries, but dense radius searches can still collect many neighbours before truncation. Each accepted `tomato` merge replaces labels across the full assignment vector. Explore on a representative subset, then measure memory and elapsed time before scaling up.
