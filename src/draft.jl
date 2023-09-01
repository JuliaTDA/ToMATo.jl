using ToMATo
import GeometricDatasets as gd
# using DataFrames
using AlgebraOfGraphics

X = hcat(randn(2, 800), randn(2, 800) .+ 4)
k = x -> exp(-(x / 2)^2)
ds = gd.Filters.density(X, kernel_function = X -> X .|> k |> sum)

df = (x1 = X[1, :], x2 = X[2, :], ds = ds)
plt = data(df) * mapping(:x1, :x2, color = :ds)
draw(plt)

g = proximity_graph(X, 0.2, max_k_ball = 6, k_nn = 4, min_k_ball = 2)

fig, ax, plt = graph_plot(X, g, ds)
fig

clusters, births_and_deaths = tomato(X, g, ds, Inf)

plot_births_and_deaths(births_and_deaths)

τ = 0.1
clusters, births_and_deaths = tomato(X, g, ds, τ, max_cluster_height = τ)

fig, ax, plt = graph_plot(X, g, clusters .|> string)
fig





X = hcat(randn(3, 800), randn(3, 800) .+ 4)
k = x -> exp(-(x / 2)^2)
ds = gd.Filters.density(X, kernel_function = X -> X .|> k |> sum)

using Makie

axis = (type = Axis3, width = 600, height = 600)
df = (x1 = X[1, :], x2 = X[2, :], x3 = X[3, :], ds = ds)
plt = data(df) * mapping(:x1, :x2, :x3, color = :ds)
draw(plt, axis = axis)

g = proximity_graph(X, 0.2, max_k_ball = 10, k_nn = 4, min_k_ball = 4)

fig, ax, plt = graph_plot(X, g, ds)
fig

clusters, births_and_deaths = tomato(X, g, ds, Inf)
plot_births_and_deaths(births_and_deaths)

τ = 0.2
clusters, births_and_deaths = tomato(X, g, ds, τ, max_cluster_height = τ)
clusters |> unique

fig, ax, plt = graph_plot(X, g, clusters .|> string)
fig