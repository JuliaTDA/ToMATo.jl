# =============================================================================
# ToMATo.jl — Full Feature Demo
# =============================================================================
#
# ToMATo (Topological Mode Analysis Tool) is a density-based clustering
# algorithm that uses persistence to decide how many clusters exist.
#
# Pipeline: Point cloud → Density estimation → Proximity graph → ToMATo → Clusters
#
# This script walks through every feature of the package, with plots at each step.

using MetricSpaces
using MetricSpaces.Datasets
using ToMATo
using Graphs: nv, ne
using TDAplots
using GLMakie
using AlgebraOfGraphics

# =============================================================================
# 1. DENSITY ESTIMATION — knn_density
# =============================================================================
#
# knn_density estimates local density at each point using k-nearest-neighbor
# distances. Points in dense regions get high values; outliers get low values.

X = two_clusters(500, dim=2, separation=10)

ds = knn_density(X, k=10)

# Plot the point cloud colored by density
metricspace_plot(X; color=ds)

# You can also use a custom distance function:
ds_cityblock = knn_density(X, k=10, d=dist_cityblock)

metricspace_plot(X; color=ds_cityblock)

# =============================================================================
# 2. PROXIMITY GRAPH — proximity_graph
# =============================================================================
#
# Builds a graph connecting nearby points. For each point:
#   - Find all neighbors within ϵ-ball
#   - If too few neighbors, fall back to k-NN
#   - Keep at most max_k_ball edges per point

g = proximity_graph(X, 1.5;
    max_k_ball = 5,   # max edges per point
    min_k_ball = 2,    # minimum neighbors before falling back to k-NN
    k_nn       = 2     # k for k-NN fallback
)

# Plot the proximity graph with edges, colored by density
fig, ax, plt = graph_plot(X, g, ds)
fig

# =============================================================================
# 3. ToMATo CLUSTERING — tomato
# =============================================================================
#
# The core algorithm. It processes points from highest to lowest density,
# creating new clusters at density peaks and merging them based on the
# persistence parameter τ.
#
# Returns:
#   - clusters: integer label per point
#   - births_and_deaths: persistence info for each peak

# --- 3a. First pass with τ = Inf (no merging) to inspect persistence ---

clusters_raw, bds = tomato(X, g, ds, Inf)

# Plot persistence diagram to choose τ
plot_births_and_deaths(bds)

# Plot the raw clusters (many small clusters before merging)
fig, ax, plt = graph_plot(X, g, clusters_raw)
fig

# --- 3b. Choose τ based on the persistence gap ---
#
# Look for a large gap in persistence values. Features with persistence > τ
# are kept as separate clusters; those below are merged.

clusters, bds = tomato(X, g, ds, 0.5)

# Plot the merged clusters
fig, ax, plt = graph_plot(X, g, clusters)
fig

# Also show as a simple scatter (without graph edges)
metricspace_plot(X; color=Float64.(clusters))

# --- 3c. Using max_cluster_height to filter small peaks ---
#
# Clusters whose peak density is below max_cluster_height are merged into
# cluster 0 (background). Useful for removing noise clusters.

clusters_filtered, _ = tomato(X, g, ds, 0.5; max_cluster_height=0.1)

metricspace_plot(X; color=Float64.(clusters_filtered))

# =============================================================================
# 4. COMPLETE PIPELINE — Different Datasets
# =============================================================================

# --- 4a. Three clusters ---

X3 = three_clusters(600, dim=2)
g3 = proximity_graph(X3, 2.0, max_k_ball=10, k_nn=5)
ds3 = knn_density(X3, k=10)

# Density landscape
metricspace_plot(X3; color=ds3)

clusters3, bds3 = tomato(X3, g3, ds3, Inf)
plot_births_and_deaths(bds3)
fig, ax, plt = graph_plot(X3, g3, clusters3)
fig

# --- 4b. Linked clusters (bridge topology) ---

Xlink = linked_clusters(3, per_cluster=100, per_link=30, dim=2)
glink = proximity_graph(Xlink, 1.0, max_k_ball=10, k_nn=5)
dslink = knn_density(Xlink, k=10)

metricspace_plot(Xlink; color=dslink)

clusters_link, bds_link = tomato(Xlink, glink, dslink, 0.1)
plot_births_and_deaths(bds_link)
graph_plot(Xlink, glink, clusters_link)

# --- 4c. Torus (3D — single connected component) ---

Xtorus = torus(500, r=1, R=3)
gtorus = proximity_graph(Xtorus, 1.5, max_k_ball=15, k_nn=5)
dstorus = knn_density(Xtorus, k=15)

# 3D scatter colored by density
metricspace_plot(Xtorus; color=dstorus)

clusters_torus, bds_torus = tomato(Xtorus, gtorus, dstorus, 0.01)
plot_births_and_deaths(bds_torus)

# 3D graph plot colored by clusters
graph_plot(Xtorus, gtorus, clusters_torus)

# --- 4d. Swiss roll (3D manifold) ---

Xswiss = swiss_roll(500)
gswiss = proximity_graph(Xswiss, 3.0, max_k_ball=15, k_nn=5)
dsswiss = knn_density(Xswiss, k=10)

metricspace_plot(Xswiss; color=dsswiss)

clusters_swiss, bds_swiss = tomato(Xswiss, gswiss, dsswiss, 0.001)
plot_births_and_deaths(bds_swiss)
graph_plot(Xswiss, gswiss, clusters_swiss)

# --- 4e. Figure eight (two loops, β₁ = 2) ---

Xeight = figure_eight(400, r=2.0)
geight = proximity_graph(Xeight, 0.8, max_k_ball=10, k_nn=5)
dseight = knn_density(Xeight, k=10)

metricspace_plot(Xeight; color=dseight)

clusters_eight, bds_eight = tomato(Xeight, geight, dseight, Inf)
plot_births_and_deaths(bds_eight)
graph_plot(Xeight, geight, clusters_eight)
