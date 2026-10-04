# ToMATo.jl

Imagine two hills connected by a saddle. As a water level moves down from the summits, each hill first appears as its own island. When the water reaches the saddle, the islands meet. ToMATo uses this picture to cluster data: hills are density peaks, a proximity graph supplies connections, and the height of a peak above its merge saddle measures its prominence.

`ToMATo.jl` implements this density-based workflow for [JuliaTDA](https://github.com/JuliaTDA). It exposes three functions, and you can replace either the density estimate or the graph with your own inputs.

| Step | Function | Output |
| :--- | :--- | :--- |
| Estimate local density | [`knn_density`](@ref) | One numeric value per point |
| Decide which points can meet | [`proximity_graph`](@ref) | An undirected graph on point IDs |
| Merge modes below a prominence threshold | [`tomato`](@ref) | Point labels and a peak birth/death dictionary |

Start with the [worked tutorial](tutorial.md), then read [parameters and interpretation](parameters.md). The [API reference](api.md) retains source docstrings; the guides clarify implementation details that matter when interpreting results.

## Installation

Use Julia 1.9 or later. The ecosystem packages are currently unregistered, so develop both in one resolution:

```julia
using Pkg
Pkg.activate("tomato-example"; shared=false)
Pkg.develop([
    PackageSpec(url="https://github.com/JuliaTDA/MetricSpaces.jl"),
    PackageSpec(url="https://github.com/JuliaTDA/ToMATo.jl"),
])
```

For local sibling checkouts, use `PackageSpec(path="../MetricSpaces.jl")` and `PackageSpec(path="../ToMATo.jl")` instead; paths are relative to the Julia working directory. Dataset generators require an explicit import such as `using MetricSpaces.Datasets: two_clusters`.

## What the threshold means

For an eligible merge at density `d`, the shorter peak with density `b` merges when `b - d < τ`. **Increasing `τ` permits more merging.** The default `τ=Inf` merges every eligible finite-density mode; it does not keep every peak as a separate cluster. With distinct densities, disconnected graph components cannot merge with each other even at this default.

The dictionary returned from an `Inf` run records the births of detected peaks and the saddle heights of eligible merges. This makes it useful for exploring a finite threshold. A visible gap in finite prominences can suggest a choice; examine it alongside geometry and connectivity rather than treating it as a guarantee of a unique correct cluster count.

The current implementation has limitations on equal-density plateaus and some multiway saddles. A connected graph can retain several modes even with `τ=Inf`; see the reproducible example in [parameters and interpretation](parameters.md#Multiway-saddles-in-the-current-implementation). Its recorded diagram should be read with these limits in mind.

## Build these docs

Clone `MetricSpaces.jl` beside this repository, then run from the ToMATo repository root:

```bash
julia --project=docs docs/setup.jl
julia --project=docs docs/make.jl
```

Setup resolves local sources and instantiates the dedicated docs environment. The build executes tutorial `@example` blocks and writes `docs/build/index.html`. Deployment is disabled unless `JULIATDA_DOCS_DEPLOY=true` is set explicitly.

## Reference

F. Chazal, L. J. Guibas, S. Y. Oudot & P. Skraba (2013), *Persistence-based clustering in Riemannian manifolds*, Journal of the ACM 60(6), 41. [DOI](https://doi.org/10.1145/2535927).

See [MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl) for geometry, [TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl) for figures, and [JuliaTDA.jl](https://github.com/JuliaTDA/JuliaTDA.jl) for the umbrella package.
