# ToMATo.jl

[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaTDA.github.io/ToMATo.jl/dev/)
[![Build Status](https://github.com/JuliaTDA/ToMATo.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaTDA/ToMATo.jl/actions/workflows/CI.yml?query=branch%3Amain)

Topological mode-seeking clustering for [JuliaTDA](https://github.com/JuliaTDA): find density peaks, then merge peaks whose prominence is too small. A high peak separated by a deep valley can remain a cluster; a small bump on its hillside can disappear. The input neighbourhood graph determines which valleys the algorithm can cross.

## Installation

The current packages are unregistered. In a new Julia project, resolve both together:

```julia
using Pkg
Pkg.activate("tomato-example"; shared=false)
Pkg.develop([
    PackageSpec(url="https://github.com/JuliaTDA/MetricSpaces.jl"),
    PackageSpec(url="https://github.com/JuliaTDA/ToMATo.jl"),
])
```

Julia 1.9 or later is supported. For sibling checkouts, replace the URLs with `path="../MetricSpaces.jl"` and `path="../ToMATo.jl"`, relative to your working directory.

## A valley you can inspect by hand

Five points form a path with assigned densities `5, 3, 1, 2, 4`. The two peaks meet at density `1`, so the shorter peak has prominence `4 - 1 = 3`.

```julia
using ToMATo, MetricSpaces
using Graphs: path_graph

X = EuclideanSpace([[Float64(i), 0.0] for i in 1:5])
g = path_graph(5)
ds = [5.0, 3.0, 1.0, 2.0, 4.0]

labels, modes = tomato(X, g, ds, 2.0)
@assert labels == [1, 1, 1, 2, 2]

merged, full_modes = tomato(X, g, ds)  # default τ = Inf
@assert merged == ones(Int, 5)
@assert full_modes[5] == [4.0, 1.0]
@assert full_modes[1] == [5.0, Inf]
```

**Larger `τ` permits more merging.** `τ=0` keeps all modes for distinct finite densities; `τ=Inf` permits every eligible merge. The inequality is strict: a mode with prominence exactly `3` survives at `τ=3` and merges at `τ>3`.

`modes` maps **original peak point IDs** to `[birth_density, death_density]`. These keys differ from final cluster labels, which are ranked by peak density. `death=Inf` is the implementation's sentinel for a mode that did not merge in that run. Do not calculate `birth - Inf` as its lifetime. A finite death is recorded only when a merge occurs, so use the `τ=Inf` run to inspect eligible merges before selecting a finite threshold.

## From a point cloud to clusters

```julia
using Random, ToMATo, MetricSpaces
using MetricSpaces.Datasets: two_clusters

Random.seed!(42)
X = two_clusters(200; dim=2, separation=10)
ds = ToMATo.knn_density(X; k=6)
g = proximity_graph(X, 1.5; max_k_ball=12, min_k_ball=2, k_nn=5)

_, modes = tomato(X, g, ds, Inf)
prominences = sort([b - d for (b, d) in values(modes) if isfinite(d)])
labels, _ = tomato(X, g, ds, 0.1)  # illustrative: inspect prominences first
```

`knn_density` is inverse neighbour distance, not a normalized probability density. The query point counts among the `k` neighbours, so `k=6` reaches the fifth other neighbour when points are distinct. The graph uses Euclidean geometry even if you supply another distance to the density estimator. Changing scaling, `k`, or graph connectivity changes the meaning of `τ`.

The [documentation](https://JuliaTDA.github.io/ToMATo.jl/dev/) explains density and graph parameters, disconnected graphs and plateaus, threshold selection, background label `0`, and plots with TDAplots. Tutorial examples execute during the documentation build.

The current implementation also has a limitation at some multiway saddles: even a connected graph with distinct densities can retain more than one mode at `τ=Inf`. The parameters guide gives a reproducible counterexample. Check memberships rather than assuming the unrestricted run equals graph connected components.

## Documentation and development

With the sibling `MetricSpaces.jl` checkout beside this repository:

```bash
julia --project=docs docs/setup.jl
julia --project=docs docs/make.jl
```

Open `docs/build/index.html`. Publishing is opt-in through `JULIATDA_DOCS_DEPLOY=true`; the default command only builds locally. In a configured development environment, run tests with `julia --project=. -e 'using Pkg; Pkg.test()'`.

## Reference and ecosystem

F. Chazal, L. J. Guibas, S. Y. Oudot & P. Skraba (2013), *Persistence-based clustering in Riemannian manifolds*, Journal of the ACM 60(6), 41. [DOI](https://doi.org/10.1145/2535927).

[MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl) supplies geometry and datasets; [TDAmapper.jl](https://github.com/JuliaTDA/TDAmapper.jl) supplies Mapper summaries; [TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl) visualizes results; [JuliaTDA.jl](https://github.com/JuliaTDA/JuliaTDA.jl) brings the ecosystem together.

MIT license.
