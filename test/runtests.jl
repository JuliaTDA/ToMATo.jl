using Test
using ToMATo
using MetricSpaces.Datasets
using Graphs: nv, ne

@testset "ToMATo.jl" begin
    @testset "knn_density" begin
        X = two_clusters(200, dim=2, separation=10)
        ds = knn_density(X, k=5)
        @test length(ds) == 200
        @test all(ds .> 0)
    end

    @testset "proximity_graph" begin
        X = two_clusters(200, dim=2, separation=10)
        g = proximity_graph(X, 1.0, max_k_ball=5, k_nn=3)
        @test nv(g) == 200
        @test ne(g) > 0
    end

    @testset "tomato basic" begin
        X = two_clusters(200, dim=2, separation=10)
        g = proximity_graph(X, 1.5, max_k_ball=10, k_nn=5)
        ds = knn_density(X, k=5)
        clusters, bds = tomato(X, g, ds, 0.1)
        @test length(clusters) == 200
        @test length(unique(clusters)) >= 1
        @test isa(bds, Dict)
    end

    @testset "tomato finds two clusters" begin
        X = two_clusters(400, dim=2, separation=20)
        g = proximity_graph(X, 2.0, max_k_ball=10, k_nn=5, min_k_ball=2)
        ds = knn_density(X, k=10)
        clusters, _ = tomato(X, g, ds, Inf)
        @test length(unique(clusters)) >= 2
    end

    @testset "tomato stress: overlapping clusters" begin
        using Random
        Random.seed!(123)
        # Tight overlap: separation=2 (vs 10–20 elsewhere) puts cluster modes close
        X = two_clusters(400, dim=2, separation=2.0)
        g = proximity_graph(X, 1.5, max_k_ball=10, k_nn=5, min_k_ball=2)
        ds = knn_density(X, k=10)
        # τ=Inf merges everything connected through the proximity graph
        clusters_inf, _ = tomato(X, g, ds, Inf)
        @test length(clusters_inf) == 400
        # With strong overlap + connected graph + τ=Inf, expect ≤ 2 real clusters
        @test length(unique(clusters_inf)) <= 3
    end

    @testset "tomato τ-behavior: cluster count is non-increasing in τ" begin
        using Random
        Random.seed!(456)
        X = two_clusters(400, dim=2, separation=4.0)
        g = proximity_graph(X, 1.5, max_k_ball=10, k_nn=5, min_k_ball=2)
        ds = knn_density(X, k=10)

        n0   = length(unique(tomato(X, g, ds, 0.0)[1]))
        n1   = length(unique(tomato(X, g, ds, 0.01)[1]))
        n2   = length(unique(tomato(X, g, ds, 0.1)[1]))
        n3   = length(unique(tomato(X, g, ds, 1.0)[1]))
        nInf = length(unique(tomato(X, g, ds, Inf)[1]))

        # Increasing τ → non-increasing cluster count (peak-merging is monotone)
        @test n0 >= n1 >= n2 >= n3 >= nInf
        # And the extremes should differ on this dataset
        @test n0 > nInf
    end
end
