"""
    proximity_graph(X, ϵ; max_k_ball = 5, min_k_ball = 1, k_nn = 3)

Calculate the proximity graph of a point cloud `X` and return
a graph. The construction is as follows:

- For each point x in X, we create an ϵ-ball around X and 
store all the ids of these points inside the ball. If the amount
of ids is less than min_k_ball, we then search the nearest neighbors
k_nn neighbors of x, and store these ids. 

- In any of the cases above, we select only a max of max_k_ball points, 
so the graph does not became too big.

"""
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
