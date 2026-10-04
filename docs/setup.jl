using Pkg

# Sources are resolved relative to this file, independent of working directory.
Pkg.activate(@__DIR__)
metricspaces = normpath(joinpath(@__DIR__, "..", "..", "MetricSpaces.jl"))
isdir(metricspaces) || error("Clone MetricSpaces.jl beside ToMATo.jl before running docs/setup.jl")
Pkg.develop([
    PackageSpec(path=metricspaces),
    PackageSpec(path=normpath(joinpath(@__DIR__, ".."))),
])
Pkg.instantiate()
