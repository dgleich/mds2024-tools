using YAML
include("schedule-2024-06-17.jl")
miniposters = YAML.load_file("matched_posters.yaml")
minis = YAML.load_file("minisymposia-edit.yaml")
posterinfo = YAML.load_file("posters-info.yaml")
posterembeddings = YAML.load_file("posters-info-embeddings.yaml")
# index the posters...
posters = Dict( (poster["poster"], poster) for poster in posterinfo ) 
poster_embeddings = Dict( (poster["poster"], poster["embedding"]) for poster in posterembeddings )
days = [ [1,2], [3,4], [5,6], [7,8], [9,10] ]
# index the posters to mini symposium
poster2mini = Dict( (posterid, mini) for (mini, info) in miniposters for posterid in info["poster-ids"] )

## the goal is to make a nice picture of the poster embeddings.
using GraphPlayground, Graphs, NearestNeighbors
function knn_for_vectors(vectors, k=5)
  vectors_matrix = hcat(vectors...)
  T = BruteTree(vectors_matrix)
  return knn(T, vectors_matrix, k, true)
end
knninfo = knn_for_vectors(values(poster_embeddings))

##
using SparseArrays
function knn_graph(knninfo,kmax=2)
  edges = Tuple{Int,Int}[] 
  idxs, dsts = knninfo 
  for i in 1:length(idxs)
    #for j in 1:min(kmax, length(idxs[i]))
    dmax = rand(3:3)
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

##
using GeometryBasics
sim = ForceSimulation(Point2f, vertices(Gknn); 
    link=LinkForce(;edges=edges(Gknn),iterations=2, distance=25, strength=1), 
    charge=ManyBodyForce(;strength=-100),
    center=CenterForce(;center=(400, 300)),
    )
fig = playground(Gknn, sim)
