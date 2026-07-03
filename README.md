# ToMATo.jl

[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaTDA.github.io/ToMATo.jl/dev/)
[![Build Status](https://github.com/JuliaTDA/ToMATo.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaTDA/ToMATo.jl/actions/workflows/CI.yml?query=branch%3Amain)

**Topological mode-seeking clustering** for the
[JuliaTDA](https://github.com/JuliaTDA) ecosystem — a Julia implementation of the
**ToMATo** algorithm (Chazal, Guibas, Oudot & Skraba, 2013).

## What is ToMATo?

ToMATo (*Topological Mode Analysis Tool*) clusters a point cloud by seeking the
peaks (modes) of a density estimate and then **merging** peaks that are not
prominent enough to survive as separate clusters. "Prominence" is measured with
**persistence**: as you sweep a threshold down through the density, each mode is
*born* at its peak and *dies* when it merges into a taller neighbour. A single
parameter `τ` decides which merges happen — modes whose persistence (peak height
minus merge height) is below `τ` are absorbed into a more prominent cluster.

The great practical advantage is that ToMATo hands you a **persistence diagram of
the modes**, so you don't have to guess the number of clusters up front: you read
the natural number of clusters off the gap in that diagram, then pick `τ` to sit
inside the gap.

The pipeline has three steps, one function each:

1. [`knn_density`](https://JuliaTDA.github.io/ToMATo.jl/dev/) — estimate a density at every point.
2. [`proximity_graph`](https://JuliaTDA.github.io/ToMATo.jl/dev/) — build a neighbourhood graph over the points.
3. [`tomato`](https://JuliaTDA.github.io/ToMATo.jl/dev/) — run the topological merging and return the clusters (plus the mode births/deaths).

## Installation

`ToMATo.jl` builds on [MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl),
which is not yet registered in the General registry. Until it is, `develop` the
dependency from its URL:

```julia
using Pkg
Pkg.develop(url = "https://github.com/JuliaTDA/MetricSpaces.jl")
Pkg.develop(url = "https://github.com/JuliaTDA/ToMATo.jl")
```

## Quick start

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

Run `tomato` once with `τ = Inf` (the default) to keep every mode and inspect
`births_and_deaths`; the difference `birth - death` is each mode's persistence.
Choose a `τ` larger than the noise-level persistences but smaller than the gap to
the real clusters, then re-run. Set `max_cluster_height` to fuse any cluster
whose peak density is below a floor into a single background cluster labelled `0`.

## The three functions

| Function | Role |
| :--- | :--- |
| `knn_density(X; k, d)` | Density at each point as the inverse k-th-nearest-neighbour distance. |
| `proximity_graph(X, ϵ; max_k_ball, min_k_ball, k_nn)` | ε-ball neighbourhood graph, falling back to k-NN where the ball is too sparse. |
| `tomato(X, g, ds, τ; max_cluster_height)` | Topological mode merging; returns `(clusters, births_and_deaths)`. |

## Reference

- F. Chazal, L. J. Guibas, S. Y. Oudot & P. Skraba (2013). **Persistence-based
  clustering in Riemannian manifolds.** *Journal of the ACM*, 60(6), 41.
  <https://doi.org/10.1145/2535927>

## Positioning

Part of the [JuliaTDA](https://github.com/JuliaTDA) ecosystem. ToMATo is the
density-clustering counterpart to the Mapper pipeline
([TDAmapper.jl](https://github.com/JuliaTDA/TDAmapper.jl)); both build on
[MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl), and
[TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl) can plot a ToMATo result
and its mode-persistence diagram.

## License

MIT.
