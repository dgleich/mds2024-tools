##
const salt_string = get(ENV, "SALT_STRING", "")
##
const email2hash_check = Dict{String, String}()
## 
using YAML, OrderedCollections

function email2hash(email)
  # convert this into a hex string of the hash combined with the salt string
  # this throws an error if we hash two emails to the same hash. 
  hashstr = string(hash(string(email, salt_string)), base=16)
  if hashstr in keys(email2hash_check)
    @assert(email2hash_check[hashstr] == email)
  end 
  email2hash_check[hashstr] = email
  return hashstr
end
function _replace_email_field(record)
  record["email"] = email2hash(record["email"])
  return record
end

##
function replace_emails()

  yamlfiles = [
    "matched_posters.yaml",
    "posters-info-embeddings.yaml",
    "posters.yaml",
    "minisymposia-edit.yaml",
    "posters-info.yaml"
  ]

  for yamlfile in yamlfiles
    data = YAML.load_file(splitext(yamlfile)[1] * "-raw.yaml", dicttype=OrderedDict)
    if yamlfile == "matched_posters.yaml"
      foreach(values(data)) do x 
        x["poster-emails"] = map(email2hash, x["poster-emails"])
      end
    elseif yamlfile == "posters-info-embeddings.yaml"
      foreach(_replace_email_field, data)
    elseif yamlfile == "posters.yaml"
      foreach(_replace_email_field, data)
    elseif yamlfile == "posters-info.yaml"
      data = map(_replace_email_field, data)
    elseif yamlfile == "minisymposia-edit.yaml"
      foreach(values(data)) do x 
        x["emails"] = map(email2hash, x["emails"])
      end
    end
    YAML.write_file(yamlfile, data)
  end
end 

replace_emails()