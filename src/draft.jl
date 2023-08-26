using ToMATo
import GeometricDatasets as gd
using DataFrames
using AlgebraOfGraphics

X = hcat(randn(2, 800), randn(2, 800) .+ 4)
k = x -> exp(-(x / 2)^2)
ds = gd.Filters.density(X, kernel_function = X -> X .|> k |> sum)

df = DataFrame(X', :auto)
df.ds = ds
plt = data(df) * mapping(:x1, :x2, color = :ds)
draw(plt)

g = proximity_graph(X, 0.2)

fig, ax, plt = graph_plot(X, g, ds)
fig

clusters, births_and_deaths = tomato(X, g, ds, Inf)

plot_births_and_deaths(births_and_deaths)

clusters, births_and_deaths = tomato(X, g, ds, 0.1)

df = DataFrame(X', :auto)
df.cluster = clusters .|> string
plt = data(df) * mapping(:x1, :x2, color = :cluster)
draw(plt)