## write a routine to order the poster sessions...
using YAML
include("schedule-2024-06-21.jl")
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

## the goal is to order the poster sessions so that the posters are in the same order as the minisymposia
# We are going to use the OpenAI embeddings to 
using MatrixNetworks, NearestNeighbors

"""
The goal of this function is to build groups of posters
  that all should should be in the same area, so they
  should have sequential numbers. 
"""  
function _build_poster_session_groups(day)
  posterlist = Set(postersessions[day])
  # build a set of groups of posters
  postergroups = Vector{Int}[] 
  while length(posterlist) > 0
    poster = pop!(posterlist)
    if !(poster in keys(poster2mini))
      push!(postergroups, [poster])
    else 
      mini = poster2mini[poster]
      group = Set(miniposters[mini]["poster-ids"])
      remgroup = intersect(group, posterlist)
      push!(remgroup, poster)
      #@show group, remgroup
      @assert(group == remgroup)
      # add them 
      push!(postergroups, collect(group))
      # remove them... 
      setdiff!(posterlist, group)
    end
  end
  return postergroups
end 

function _build_group_embedding_matrix(day)
  groups = _build_poster_session_groups(day)
  embeddings = [ mean(x->poster_embeddings[x], group) for group in groups ]
  map(x->normalize!(x), embeddings)
  return hcat(embeddings...), groups
end

function _get_group_order(day) 
  X, groups = _build_group_embedding_matrix(day)
  G = X'*X 
  f, lambda2 = fiedler_vector(sparse(G)) 
  @info "2nd eigenvector of normalized Laplacian is $lambda2"
  p = sortperm(f) 
  return p, groups, f
end 

_remove_newlines(str) = replace(str, r"\n" => " ")
function poster_order(day; verbose=true) 
  p, groups, f = _get_group_order(day)
  posterorder = Vector{Int}() 
  for gi in p 
    if verbose == true 
      #println("          group $gi - fielder value $(f[gi]):")
    end 
    for poster in groups[gi]
      sym = "-"
      if length(groups[gi]) > 1
        sym = "="
        sym = "MS$(poster2mini[poster])"
      end 
      push!(posterorder, poster)
      if verbose == false 
        mini = length(groups[gi]) > 1 ? string(poster2mini[poster]) : ""
        println("$day,$(mini),$poster,\"$(_remove_newlines(posters[poster]["title"]))\"")
      else 
        println(" $sym $poster - $(_remove_newlines(posters[poster]["title"]))")
      end 
    end
  end
  return posterorder
end 

poster_order(2)

##
foreach(1:5) do d
  println("Day $d")
  poster_order(d; verbose=false )
  return nothing 
end

