using Test
using ToMATo
using MetricSpaces
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
end
