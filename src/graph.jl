function proximity_graph(X, ϵ; max_k_ball = 5, min_k_ball = 1, k_nn = 3)

    global g = Graph(Int64)
    add_vertices!(g, size(X)[2])
    bt = BallTree(X)

    @threads for v1 ∈ 1:size(X)[2]
        p = X[:, v1]
        close_ones = inrange(bt, p, ϵ, true)
            
        if length(close_ones) < min_k_ball + 1        
            close_ones, _ = knn(bt, p, k_nn + 1, true, x -> false)        
        end
    
        if length(close_ones) > max_k_ball
            close_ones = close_ones[1:max_k_ball]
        end
        
        # get at most max_k_ball edges
        for v2 ∈ close_ones
            v1 == v2 && continue
            add_edge!(g, v1, v2)
        end
    end
    
    return g
    
end

function graph_plot(X, g, ds)
    node_positions = [Point2(X[:, i]) for i ∈ 1:size(X)[2]]

    fig, ax, plt = scatter(node_positions, color = ds);
    
    for e ∈ edges(g)
        e.src == e.dst && continue
        linesegments!(
            ax, [node_positions[e.src], node_positions[e.dst]], color = :black
            ,linewidth = 0.5, alpha = 0.5
            )
    end;
    
    fig, ax, plt
end