using JSON
using DataFrames
using LinearAlgebra

function read_embeddings(file_path)
  json_data = JSON.parsefile(file_path)
  df = DataFrame(json_data)
  df.text_embedding = [Float64.(x) for x in df[!,"text_embedding"]]
  df.title_embedding = [Float64.(x) for x in df[!,"title_embedding"]]
  df.id = map(u -> u[end-4:end], df.url) # get last 5 numbers as ids... 
  return df
end 

df = read_embeddings("mini-embeddings.json")

function vector_distance(v1, v2)
  return norm(v1 .- v2)
end

function dot_distance(v1, v2)
  return dot(v1, v2) / ((norm(v1)*norm(v2)))
end

function metric(vectors, distance=vector_distance)
  n = size(vectors, 1)
  m = zeros(n, n)
  for i in 1:n
    for j in 1:n
      m[i,j] = distance(vectors[i], vectors[j])
    end
  end
  return m
end


function upper_triangular_vector(A)
  return [A[i, j] for j in 1:size(A, 2) for i in 1:j-1]
end 

##
using GLMakie
hist(upper_triangular_vector(metric(df.text_embedding, vector_distance)))

##
using GLMakie 
fig, ax, p = scatter(first.(df.text_embedding), last.(df.text_embedding), 
  inspector_label = (self, i, p) -> df.title[i],)
DataInspector(fig)
fig 

##
using LinearAlgebra, Statistics
function pca(vectors, dim=2)
  # the input is a collection of vectors
  vectors = hcat(df.text_embedding...)'
  n = size(vectors, 1)
  m = mean(vectors, dims=1)
  centered = vectors .- m
  U, S, V = svd(centered)
  return U[:,1:dim]
end

fig, ax, p = scatter(eachcol(pca(df.text_embedding))..., 
  inspector_label = (self, i, p) -> df.title[i],)
DataInspector(fig)
fig 

## Generate nearest neighbors 
using NearestNeighbors
function knn_for_vectors(vectors, k=5)
  vectors_matrix = hcat(vectors...)
  T = BruteTree(vectors_matrix)
  return knn(T, vectors_matrix, k, true)
end
knninfo = knn_for_vectors(df.text_embedding)

## Show the distances
knndists = vec(hcat(knninfo[2]...)[2:end,:])
hist(knndists, bins=10)

## print out the nearest neighbor info
function _thresh_knn_to_edges(knninfo, threshhold) 
  edges = Tuple{Int,Int}[] 
  idxs, dsts = knninfo 
  for i in 1:length(idxs)
    for j in 1:length(idxs[i])
      if dsts[i][j] < threshhold && i < idxs[i][j]
        push!(edges, (i, idxs[i][j]))
      end
    end
  end
  return edges 
end 

function draw_minis(thresh)
  edges = _thresh_knn_to_edges(knninfo, thresh)
  x,y = eachcol(pca(df.text_embedding))
  fig, ax, p = scatter(x, y, 
    inspector_label = (self, i, p) -> df.title[i],)
  foreach(eij -> linesegments!(ax, [(x[eij[1]],y[eij[1]]), (x[eij[2]],y[eij[2]])], color=:gray), edges)
  DataInspector(fig)
  fig 
end

draw_minis(0.70)


## Find the theshold by finding the largest value such that we get clusters less than 8 in size.
using MatrixNetworks, SparseArrays
function check_threshold(thresh)
  edges = _thresh_knn_to_edges(knninfo, thresh)
  A = sparse(first.(edges), last.(edges), 1, length(knninfo[1]), length(knninfo[1]))
  A = max.(A, A')
  ccs = scomponents(A)
  return maximum(ccs.sizes)
end 
check_threshold(0.7)

## 
function _thresh_knn_to_edges_and_knn(knninfo, threshhold, knnthreshhold) 
  edges = Tuple{Int,Int}[] 
  idxs, dsts = knninfo 
  for i in 1:length(idxs)
    for j in 1:length(idxs[i])
      if dsts[i][j] < threshhold || j <= knnthreshhold
        push!(edges, (i, idxs[i][j]))
      end
    end
  end
  return edges 
end 
##
function draw_minis_knn(thresh, knnthresh)
  edges = _thresh_knn_to_edges_and_knn(knninfo, thresh, knnthresh)
  # originally, we just used either edge, but this was too much...
  A = sparse(first.(edges), last.(edges), 1, length(knninfo[1]), length(knninfo[1]))
  A = min.(A, A')
  edges = zip(findnz(A)[1:2]...)
  x,y = eachcol(pca(df.text_embedding))
  fig, ax, p = scatter(x, y, markersize=25,
    inspector_label = (self, i, p) -> "$i: $(df.title[i])",)
  foreach(eij -> linesegments!(ax, [(x[eij[1]],y[eij[1]]), (x[eij[2]],y[eij[2]])], color=:gray), edges)
  DataInspector(fig)
  fig 
end

draw_minis_knn(0.8, 2)
##
function check_threshold_with_knn(thresh, knnthresh)
  edges = _thresh_knn_to_edges_and_knn(knninfo, thresh, knnthresh)
  A = sparse(first.(edges), last.(edges), 1, length(knninfo[1]), length(knninfo[1]))
  A = min.(A, A')
  ccs = scomponents(A)
  return ccs.sizes
end 
sort(check_threshold_with_knn(0.8, 2))
## Okay, let's try and sort this out with our new playground infrastructure.
using Graphs, GeometryBasics, GraphPlayground
function get_graph_from_thresh_and_knn(thresh, knnthresh)
  edges = _thresh_knn_to_edges_and_knn(knninfo, thresh, knnthresh)
  A = sparse(first.(edges), last.(edges), 1, length(knninfo[1]), length(knninfo[1]))
  A = min.(A, A')
  A = A - Diagonal(A)
  return Graph(A)
end
G = get_graph_from_thresh_and_knn(0.8, 5)
function mysetup(G)
  sim = ForceSimulation(Point2f, vertices(G); 
    link=LinkForce(;edges=edges(G)), 
    charge=ManyBodyForce(;),
    center=PositionForce(;target=Point2f(400, 300)),
    )
  screen = GLMakie.Screen(title="Playground", framerate=60.0, size=(800,800),
            focus_on_show=true, render_on_demand=false, vsync=true )
  scene = Scene(camera = campixel!)
  ax = Axis(scene)
  p = GraphPlayground.igraphplot!(ax, G, sim)        
  GLMakie.display_scene!(screen, scene)
  scatterpos = Observable(sim.positions)
  scatter!(ax, scatterpos, markersize=10, 
    inspector_label = (self, i, p) -> "$i: $(df.title[i])",)
  on(screen.render_tick) do _ 
    p.node_pos[][:] = sim.positions
  end 
  return scene
end 

#mysetup(G)

sim = ForceSimulation(Point2f, vertices(G); 
    link=LinkForce(;edges=edges(G)), 
    charge=ManyBodyForce(;),
    center=PositionForce(;target=Point2f(400, 300)),
    )
fig = playground(G, sim)
## Arrange the graph, then save the positions... 
xy = sim.positions
##
write("mini-similarity-sinews-xy.json", JSON.json(xy))
##
f = GraphPlayground.graphplot(G, layout=xy, node_size=15)
hidedecorations!(f.axis)
hidespines!(f.axis)
f
##
save( "mini-similarity-sinews.png", f)
## Do a Eigenmap layout of the embeddings...
Xminis = hcat(df.text_embedding...)
Gw = Xminis'*Xminis
function laplacian(G)
  G = G.^2
  G = G - Diagonal(G)
  d = vec(sum(G, dims=1))
  @assert G == G' 
  n = size(G, 1)
  ai,aj,av = findnz(sparse(G))
  d = sqrt.(d)
  L = sparse(ai,aj,-av./((d[ai].*d[aj])),n,n) # applied sqrt above
  L = L + sparse(2.0I,n,n)
  return L
end 
function _dense_spectral(G)
  V = eigen(Matrix(laplacian(G)))
  p = sortperm(V.values, rev=true) # sort by smallest...
  return V.vectors[:,p[2:end]]
end 
X = _dense_spectral(Gw)[:,1:3]

##
_number_to_rank(x) = invperm(sortperm(x))
function coordinate_to_rank(X)
  R = similar(X) 
  for i in 1:size(X, 2)
    R[:,i] = _number_to_rank(X[:,i])
  end
  return R 
end
R = coordinate_to_rank(X)
##
scatter(eachcol(R[:,1:2])...)
##
R = coordinate_to_rank(pca(df.text_embedding, 3))
##
function draw_with_layout(G, xymat)
  edgelist = map(e -> (e.src, e.dst), collect(edges(G)))
  xypts = Point2f.(eachrow(xymat))
  fig, ax, p = scatter(xypts, markersize=25,
    inspector_label = (xymat, i, p) -> "$(df.id[i]): $(df.title[i])",)
  foreach(eij -> linesegments!(ax, [xypts[eij[1]], xypts[eij[2]]], color=:gray), edgelist)
  DataInspector(fig)
  fig 
end
draw_with_layout(G, R[:,1:3])
##
function scatter_with_labels(xymat)
  fig, ax, p = scatter(xymat, markersize=25,
    inspector_label = (xymat, i, p) -> "$(df.id[i]): $(df.title[i])",)
  DataInspector(fig)
  fig 
end
scatter_with_labels(R[:,1:3])

## Just make a KNN Graph 
function knn_graph(knninfo,kmax=2)
  edges = Tuple{Int,Int}[] 
  idxs, dsts = knninfo 
  for i in 1:length(idxs)
    #for j in 1:min(kmax, length(idxs[i]))
    dmax = rand(2:3)
    for j in 1:min(dmax, length(idxs[i]))
      if i != idxs[i][j]
        push!(edges, (i, idxs[i][j]))
      end 
    end
  end
  A = sparse(first.(edges), last.(edges), 1, length(knninfo[1]), length(knninfo[1]))
  A = max.(A, A')
  return Graph(A)
end
Gknn = knn_graph(knninfo)
playground(Gknn)