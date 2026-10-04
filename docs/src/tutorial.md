# A clustering decision you can explain

```@meta
CurrentModule = ToMATo
```

## Two hills and one saddle

First separate the algorithm from density estimation. We supply a five-point path and assign densities ourselves. Points 1 and 5 are peaks; point 3 is their connecting saddle.

```@example valley
using ToMATo, MetricSpaces
using Graphs: path_graph, rem_edge!

X = EuclideanSpace([[Float64(i), 0.0] for i in 1:5])
g = path_graph(5)
ds = [5.0, 3.0, 1.0, 2.0, 4.0]

labels, modes = tomato(X, g, ds, 2.0)
@assert labels == [1, 1, 1, 2, 2]
labels
```

Points 1–3 belong to the taller peak; points 4–5 belong to the shorter one. The algorithm visits points in descending density order. At point 3 it finds neighbours from both hills and compares the shorter peak's height above the current density: `4 - 1 = 3`. A threshold of `2` cannot merge it.

```@example valley
at_boundary, _ = tomato(X, g, ds, 3.0)
above_boundary, _ = tomato(X, g, ds, 3.1)
@assert at_boundary == labels
@assert above_boundary == ones(Int, 5)
(at_boundary, above_boundary)
```

This shows the strict boundary rule: a persistence equal to `τ` survives.

## Inspect every eligible merge

Run with the default `τ=Inf` to permit all eligible merges and obtain their saddle heights.

```@example valley
merged, full_modes = tomato(X, g, ds)
@assert merged == ones(Int, 5)
@assert full_modes[5] == [4.0, 1.0]
@assert full_modes[1] == [5.0, Inf]

finite_prominences = sort([
    birth - death for (birth, death) in values(full_modes) if isfinite(death)
])
@assert finite_prominences == [3.0]
finite_prominences
```

The dictionary key `5` is the **original point ID of the shorter peak**, not a final cluster label. Its `[4.0, 1.0]` entry means that it was born at density `4` and merged at density `1`. Key `1` has death `Inf`, the package's sentinel for a peak that never merged in this run. Treat it as an unmerged peak; `5 - Inf` is not a meaningful finite lifetime.

The earlier finite-threshold run kept both peaks, so both deaths in its dictionary remain `Inf`. A dictionary from that run does not contain saddle heights of rejected merges. Save the `Inf` run's dictionary when comparing candidate thresholds.

## A graph is a modelling choice

Remove the bridge across the saddle and try the strongest threshold again:

```@example valley
disconnected = copy(g)
rem_edge!(disconnected, 3, 4)
separate, _ = tomato(X, disconnected, ds, Inf)
@assert length(unique(separate)) == 2
separate
```

No threshold can create a missing connection. On this path graph, the `Inf` run leaves one mode per connected component. Conversely, a long nearest-neighbour fallback edge can connect groups that a radius-only graph would separate. Inspect the graph as part of the clustering decision. The current implementation's [multiway saddle limitation](parameters.md#Multiway-saddles-in-the-current-implementation) means this one-mode-per-component result is not a universal guarantee.

## Use all three functions on data

This deterministic cloud has two compact groups. Coordinates vary slightly to avoid deliberately identical distances. A point is a column of a matrix or an element of a vector of coordinate vectors; we use the latter.

```@example cloud
using ToMATo, MetricSpaces
using Graphs: nv, ne, connected_components

points = [
    [center + (0.25 + 0.015i) * cos(i), 0.2sin(i)]
    for center in (-2.0, 2.0) for i in 1:12
]
X = EuclideanSpace(points)
ds = ToMATo.knn_density(X; k=5)
g = proximity_graph(X, 0.8; max_k_ball=12, min_k_ball=2, k_nn=4)
@assert length(ds) == nv(g) == length(X)
@assert all(isfinite, ds)
@assert length(connected_components(g)) == 2
(points=length(X), edges=ne(g), density_range=extrema(ds))
```

Inspect the full merge run. These density units differ from the hand-assigned example, so the same numeric `τ` need not express the same decision.

```@example cloud
all_merged, peak_diagram = tomato(X, g, ds, Inf)
@assert length(unique(all_merged)) == 2
prominences = sort([
    b - d for (b, d) in values(peak_diagram) if isfinite(d)
])
prominences
```

Compare cluster counts over a few candidate thresholds:

```@example cloud
thresholds = [0.0, 0.1, 1.0, Inf]
[(τ=τ, clusters=length(unique(tomato(X, g, ds, τ)[1]))) for τ in thresholds]
```

Inspect member points, density values, graph edges and stability under reasonable parameter changes before adopting a clustering. If a dataset has a gap between small and large finite prominences, try thresholds inside the gap. When all candidates give the same count, graph or density choices may already determine the result.

## A background label is a separate decision

`max_cluster_height` applies an absolute peak-density floor after merging. It differs from the prominence threshold.

```@example valley
with_background, _ = tomato(X, g, ds, 2.0; max_cluster_height=4.5)
@assert with_background == [1, 1, 1, 0, 0]
with_background
```

The second peak has height `4`, so its cluster receives label `0`. All clusters below the floor share that label even if they are disconnected. Positive labels need not be consecutive once background assignment is applied.

## Plot the result

The plotting package is optional and requires a Makie backend. Install it with the complete dependencies in the [TDAplots installation guide](https://JuliaTDA.github.io/TDAplots.jl/dev/). In an environment containing those packages:

```julia
using CairoMakie, TDAplots
using ToMATo, MetricSpaces
using Graphs: path_graph

X = EuclideanSpace([[Float64(i), 0.0] for i in 1:5])
g = path_graph(5)
ds = [5.0, 3.0, 1.0, 2.0, 4.0]
labels, _ = tomato(X, g, ds, 2.0)
_, diagram = tomato(X, g, ds, Inf)

save("density-graph.png", tomato_graph_plot(X, g, ds))
save("clusters.png", metricspace_plot(X; color=string.(labels)))
save("mode-prominence.png", tomato_persistence_plot(diagram))
```

String labels give a categorical cluster legend. `tomato_graph_plot` takes numeric values and draws a continuous colorbar; a cluster ID is an identifier rather than a measured quantity. The prominence plot uses a display surrogate for unmerged modes, not a finite observed lifetime.
