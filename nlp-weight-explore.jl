using YAML, LinearAlgebra
using OrderedCollections, MatrixNetworks, Graphs

mini = YAML.load_file("minisymposia-edit.yaml", dicttype=OrderedDict)
nrooms = 10
nslots = 10 
nmini = length(mini)
room_capacities=nrooms:-1:1
class_code_penalty = 1
nlp_soft_penalty = 10 

# index the minisymposia
mini_id = Dict(keys(mini) .=> 1:nmini)
id2mini = collect(keys(mini))


hard_edges = [
  #[80749, 80748], # BE Minisympsium 
  [80632, 80688], 
  [80632, 80565], 
  [80559, 80510], 
  [80514, 80554], 
  [80340, 80287], 
  [80598, 80551], 
  [80534, 80441], 
  [80518, 80608], 
  [80445, 80436], 
  [80336, 80346], 
  [80632, 80587], 
  [80688, 80632], 
  [80511, 80509], 
  [80608, 80518], 
  [80598, 80517], 
  [80610, 80436], 
  [80580, 80426], 
  [80510, 80343], 
  [80554, 80514], 
  [80514, 80400], 
  [80346, 80341], 
  [80587, 80688], 
  [80625, 80756], 
  [80587, 80565], 
  [80565, 80688], 
  [80436, 80610], 
  [80426, 80580], 
  [80521, 80336], 
  [80427, 80340], 
  [80565, 80587], 
  [80340, 80427], 
  # [80748, 80749], BE Minisymposium
  [80518, 80514], 
  [80625, 80558], 
  [80287, 80340], 
  [80597, 80510], 
  [80445, 80398], 
  [80558, 80756], 
  [80452, 80582], 
  [80601, 80551], 
  [80610, 80398], 
  [80558, 80604], 
  [80609, 80688], 
  [80609, 80565], 
  [80265, 80605], 
  [80625, 80605], 
  [80634, 80598], 
  [80436, 80445], 
  [80756, 80604], 
  [80605, 80625], 
  [80518, 80554], 
  [80803, 80340], 
  [80605, 80265], 
  [80634, 80601], 
  [80756, 80558], 
  [80632, 80609], 
  [80609, 80587], 
  [80398, 80610], 
  [80598, 80634], 
  [80343, 80559], 
  [80803, 80287], 
  [80336, 80521], 
  [80582, 80554], 
  [80336, 80341], 
  [80517, 80598], 
  [80341, 80336], 
  [80688, 80565], 
  [80400, 80608], 
  [80551, 80598], 
  [80518, 80400], 
  [80341, 80346], 
  [80608, 80400], 
  [80551, 80601], 
  [80554, 80452], 
  [80688, 80587], 
  [80400, 80518], 
  [80587, 80609], 
  [80433, 80620], 
  [80603, 80725], 
  [80565, 80609], 
  [80340, 80803], 
  [80604, 80756], 
  [80265, 80625], 
  [80398, 80445], 
  [80578, 80635], 
  [80625, 80265], 
  [80346, 80336], 
  [80441, 80534], 
  [80598, 80601], 
  [80514, 80518], 
  [80521, 80341], 
  [80725, 80603], 
  [80554, 80582], 
  [80587, 80632], 
  [80604, 80558], 
  [80620, 80433], 
  [80565, 80632], 
  [80582, 80452], 
  [80510, 80559], 
  [80601, 80634], 
  [80400, 80514], 
  [80635, 80578], 
  [80558, 80625], 
  [80756, 80625], 
  [80517, 80551], 
  [80452, 80554], 
  [80436, 80398], 
  [80343, 80510], 
  [80509, 80511], 
  [80398, 80436], 
  [80510, 80597], 
  [80287, 80803], 
  [80609, 80632], 
  [80559, 80343], 
  [80688, 80609], 
  [80341, 80521], 
  [80554, 80518], 
  [80601, 80598], 
  [80551, 80517], 
]
soft_edges = [
  [80610, 80426], 
  [80560, 80515], 
  [80339, 80635], 
  [80618, 80578], 
  [80619, 80312], 
  [80561, 80603], 
  [80551, 80287], 
  [80492, 80572], 
  [80588, 80439], 
  [80397, 80521], 
  [80439, 80588], 
  [80397, 80557], 
  [80562, 80343], 
  [80523, 80510], 
  [80287, 80551], 
  [80425, 80618], 
  [80442, 80515], 
  [80439, 80549], 
  [80557, 80559], 
  [80524, 80608], 
  [80397, 80338], 
  [80515, 80442], 
  [80343, 80588], 
  [80338, 80397], 
  [80572, 80492], 
  [80618, 80425], 
  [80510, 80523], 
  [80521, 80397], 
  [80618, 80742], 
  [80578, 80572], 
  [80452, 80430], 
  [80549, 80439], 
  [80492, 80339], 
  [80582, 80615], 
  [80517, 80530], 
  [80523, 80588], 
  [80541, 80514], 
  [80521, 80559], 
  [80608, 80524], 
  [80572, 80578], 
  [80426, 80610], 
  [80603, 80561], 
  [80615, 80492], 
  [80559, 80521], 
  [80588, 80343], 
  [80559, 80557], 
  [80557, 80523], 
  [80615, 80582], 
  [80635, 80339], 
  [80430, 80452], 
  [80312, 80619], 
  [80426, 80445], 
  [80339, 80492], 
  [80530, 80517], 
  [80287, 80615], 
  [80515, 80560], 
  [80588, 80523], 
  [80742, 80618], 
  [80514, 80541], 
  [80615, 80287], 
  [80492, 80615], 
  [80523, 80557], 
  [80343, 80562], 
  [80445, 80426], 
  [80578, 80618], 
  [80557, 80397], 
]

sim = zeros(nmini, nmini)
for (i, ms) ∈ enumerate(keys(mini)), (j, ms2) ∈ enumerate(keys(mini))
    for c1 ∈ mini[ms]["class codes"]
        if c1 ∈ mini[ms2]["class codes"]
            sim[i,j] += class_code_penalty
        end
    end
end
# build up a similarity matrix for soft conflicts from NLP 
scmat = zeros(nmini, nmini)
for group in [soft_edges;hard_edges]
  for rawi in group
    i = mini_id[rawi]
    for rawj in group 
      j = mini_id[rawj]
      if i != j 
        scmat[i,j] += 1
      end 
    end
  end
end


# compute PageRank on the soft similarity matrix...
# this gives us a transitive property.. Maybe Katz is better. 
function simpr(S,alpha)
  #scale = maximum(S)
  scale = maximum(S)

  d = vec(sum(S; dims=2))/scale 

  dhalf = sqrt.(d)
  invdhalf = map(x -> x==0 ? 0.0 : 1.0 / x, dhalf)
  A = Diagonal(invdhalf) * S/scale * Diagonal(invdhalf)
  S = inv(I - alpha*A)
  return (S - Diagonal(S))*scale
end 
function simresolvent(S,alpha)
  R =  inv(I - alpha*S)
  R = R - Diagonal(R)
  return R
end

##
using Graphs, MatrixNetworks
function all_paths_weight(scmat, alpha) 
  S = zeros(size(scmat)...)
  g = Graph(scmat) 
  for i in 1:size(S,1), j in 1:size(S,2)
    if i == j
      continue
    end
    paths = all_simple_paths(g, i, j)
    # count how many paths there are of each length
    plength = zeros(Int, size(scmat,1))
    for path in paths
      plength[length(path)] += 1
    end
    paths = all_simple_paths(g, i, j)
    for path in paths
      for k in 2:length(path)
        S[i, path[k]] += alpha^(k-1)/plength[length(path)]
      end
    end
  end 

  return (S + S')/2
end 
P = all_paths_weight(scmat, 1)
function component_order(A, ordermat = A)
  N = sparse(ordermat) 
  ccinfo = scomponents(N)
  p = sortperm(ccinfo.map) 
  return A[p,p]
end 
heatmap(component_order(P))
##