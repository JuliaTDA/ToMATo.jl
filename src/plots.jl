
# function graph_plot(X, g, ds)
#     node_positions = [Point2(X[:, i]) for i ∈ 1:size(X)[2]]

#     fig, ax, plt = scatter(node_positions, color = ds);
    
#     for e ∈ edges(g)
#         e.src == e.dst && continue
#         linesegments!(
#             ax, [node_positions[e.src], node_positions[e.dst]], color = :black
#             ,linewidth = 0.5, alpha = 0.5
#             )
#     end;
    
#     fig, ax, plt
# end
"""
    graph_plot(X, g, values)

Given a metric space X on 2 dimensions, a graph g obtained with
`proximity_graph` and a numeric vector of size `size(X)[2]` (real or string),
plot the proximity graph with nodes colored by `values`.
"""
function graph_plot(X::PointCloud, g::Graph, values)
    n = size(X)[1]
    n = clamp(n, 2, 3)
    node_positions = [Point{n}(X[:, i]) for i ∈ 1:size(X)[2]]

    if n == 2
        axis_type = Axis
    else 
        axis_type = Axis3
    end

    axis = (type = axis_type, width = 600, height = 600)

    if n == 2
        df = (x1 = X[1, :], x2 = X[2, :], values = values)
    else
        df = (x1 = X[1, :], x2 = X[2, :], x3 = X[3, :], values = values)
    end

    fig = Figure();
    ax = axis_type(fig[1, 1], title = "ToMATo clustering")
    if n == 2
        plt = data(df) * mapping(:x1, :x2, color = :values)
    else
        plt = data(df) * mapping(:x1, :x2, :x3, color = :values)
    end
    
    ag = draw!(ax, plt, axis = axis)    
    legend!(fig[1, 2], ag)    
    
    for e ∈ edges(g)
        e.src == e.dst && continue
        linesegments!(
            ax, [node_positions[e.src], node_positions[e.dst]], color = :black
            ,linewidth = 0.5, alpha = 0.5
            )
    end;
    
    fig, ax, plt
end