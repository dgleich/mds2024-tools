## Check for duplicate posters based on embeddings... 
posterembeddings = YAML.load_file("posters-info-embeddings.yaml")
##
X = hcat([poster["embedding"] for poster in posterembeddings]...)
##
S = X'*X
S = S .- diagm(diag(S))
##
findall(S .> 0.9)