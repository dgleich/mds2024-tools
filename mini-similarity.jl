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
function draw_with_layout(G, xypts)
  edgelist = map(e -> (e.src, e.dst), collect(edges(G)))
  fig, ax, p = scatter(xypts, markersize=25,
    inspector_label = (self, i, p) -> "$(df.id[i]): $(df.title[i])",)
  foreach(eij -> linesegments!(ax, [xypts[eij[1]], xypts[eij[2]]], color=:gray), edgelist)
  DataInspector(fig)
  fig 
end
draw_with_layout(G, xy)


## final try
# any mini where we get a complementary pair of 1st nn's is a hard conflict.
using MatrixNetworks
function _hard_conflicts()
  idxs = knninfo[1]
  edgeindex = Set{Tuple{Int,Int}}()
  bothedges = Tuple{Int,Int}[]
  n = length(idxs)
  for i in eachindex(idxs)
    @assert idxs[i][1] == i # first nn is always itself 
    push!(edgeindex, (i, idxs[i][2]))
    if (idxs[i][2], i) in edgeindex
      push!(bothedges, (i, idxs[i][2]))
      push!(bothedges, (idxs[i][2], i))
    end
  end 
  return bothedges
end 


function new_idea(thresh, knnthresh)
  hardedges = _hard_conflicts() 
  Gedges = _thresh_knn_to_edges_and_knn(knninfo, thresh, knnthresh)
  push!(Gedges, hardedges...)
  A = sparse(first.(Gedges), last.(Gedges), 1, length(knninfo[1]), length(knninfo[1]))
  A = min.(A, A')
  A = A - Diagonal(A)
  ts = MatrixNetworks.triangles(A) 
  for t in ts
    push!(hardedges, (t.v1, t.v2))
    push!(hardedges, (t.v2, t.v1))
    push!(hardedges, (t.v2, t.v3))
    push!(hardedges, (t.v3, t.v2))
    push!(hardedges, (t.v1, t.v3))
    push!(hardedges, (t.v3, t.v1))
  end

  # output connected components of the hard edges 
  Ghard = Graph(map(e -> Edge(e[1], e[2]), collect(hardedges)))
  trans_Ghard = SimpleGraph(transitiveclosure(DiGraph(Ghard)))

  hardedges = Set(map(e -> (e.src, e.dst), collect(edges(trans_Ghard))))
  alledges = Set(collect(zip(findnz(A)[1:2]...)))
  softedges = setdiff(alledges, hardedges)
  
  return Graph(A), hardedges, softedges 
end 

G, hardedges, softedges = new_idea(0.8, 5)

sim = ForceSimulation(Point2f, vertices(G); 
    link=LinkForce(;edges=edges(G)), 
    charge=ManyBodyForce(;),
    center=PositionForce(;target=Point2f(400, 300)),
    )
fig = playground(G, sim)

## Look at the graph of hard edges originally
Ghard = Graph(map(e -> Edge(e[1], e[2]), collect(hardedges)))
trans_Ghard = SimpleGraph(transitiveclosure(DiGraph(Ghard)))

sim = ForceSimulation(Point2f, vertices(trans_Ghard); 
    link=LinkForce(;edges=edges(trans_Ghard)), 
    charge=ManyBodyForce(;),
    center=PositionForce(;target=Point2f(400, 300)),
    )
fig = playground(trans_Ghard, sim)

## Print out the edges
function write_constraints()
  println("hard_edges = [")
  for (i,j) in hardedges
    println("  [$(df.id[i]), $(df.id[j])], ")
  end
  println("]")
  println("soft_edges = [")
  for (i,j) in softedges
    println("  [$(df.id[i]), $(df.id[j])], ")
  end
  println("]")
end
write_constraints()