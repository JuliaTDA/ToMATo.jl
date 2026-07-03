# ToMATo.jl

*Topological mode-seeking clustering for the [JuliaTDA](https://github.com/JuliaTDA) ecosystem.*

```@meta
CurrentModule = ToMATo
```

`ToMATo.jl` is a Julia implementation of the **ToMATo** algorithm
(*Topological Mode Analysis Tool*; Chazal, Guibas, Oudot & Skraba, 2013). It
clusters a point cloud by seeking the peaks (modes) of a density estimate and
then **merging** peaks that are not prominent enough to survive as separate
clusters.

Prominence is measured with **persistence**: as a threshold sweeps down through
the density, each mode is *born* at its peak and *dies* when it merges into a
taller neighbour. A single parameter `τ` decides which merges happen — modes
whose persistence (peak height minus merge height) is below `τ` are absorbed
into a more prominent cluster.

The practical payoff is that [`tomato`](@ref) returns a **persistence diagram of
the modes**, so you don't have to guess the number of clusters up front: read
the natural number of clusters off the gap in that diagram, then pick `τ` inside
the gap.

## Installation

`ToMATo.jl` builds on
[MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl), which is not yet
registered in the General registry. Until it is, `develop` the dependency from
its URL:

```julia
using Pkg
Pkg.develop(url = "https://github.com/JuliaTDA/MetricSpaces.jl")
Pkg.develop(url = "https://github.com/JuliaTDA/ToMATo.jl")
```

## The pipeline

The workflow has three steps, one function each:

1. [`knn_density`](@ref) — estimate a density at every point.
2. [`proximity_graph`](@ref) — build a neighbourhood graph over the points.
3. [`tomato`](@ref) — run the topological merging and return the clusters plus
   the mode births/deaths.

```julia
using ToMATo
using MetricSpaces
using MetricSpaces.Datasets: two_clusters

# A point cloud with two well-separated blobs
X = two_clusters(200; dim = 2, separation = 10)

# 1. Density estimate (higher = denser region)
ds = knn_density(X; k = 5)

# 2. Neighbourhood graph over the points
g = proximity_graph(X, 1.5; max_k_ball = 10, min_k_ball = 2, k_nn = 5)

# 3. ToMATo: merge modes whose persistence is below τ = 0.1
clusters, births_and_deaths = tomato(X, g, ds, 0.1)

clusters               # a cluster label for each point of X
births_and_deaths      # birth/death height of each mode — read τ off the gap
```

## Choosing `τ`

Run [`tomato`](@ref) once with `τ = Inf` (the default) to keep every mode and
inspect `births_and_deaths`; the difference `birth - death` is each mode's
persistence. Pick a `τ` larger than the noise-level persistences but smaller than
the gap to the real clusters, then re-run. Set `max_cluster_height` to fuse any
cluster whose peak density is below a floor into a single background cluster
labelled `0`.

## Reference

- F. Chazal, L. J. Guibas, S. Y. Oudot & P. Skraba (2013). **Persistence-based
  clustering in Riemannian manifolds.** *Journal of the ACM*, 60(6), 41.
  <https://doi.org/10.1145/2535927>

## See also

* [MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl) — the geometry
  foundation this package builds on.
* [TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl) — plots a ToMATo result
  and its mode-persistence diagram.
* [JuliaTDA.jl](https://github.com/JuliaTDA/JuliaTDA.jl) — the umbrella package.
