## Required packages
# using Gurobi
using GLPK, JuMP, YAML, LinearAlgebra, Graphs
using OrderedCollections

## These are setup parameters. 

# Class code penalty is how much of a penalty we get for scheduling two minisymposia
# with the same class code at the same time.
class_code_penalty = 1
# NLP soft penalty is how much of a penalty we get for scheduling two minisymposia
# at the same time that are nearest neighbors of each other from the NLP objective
nlp_soft_penalty = 10 
# max span is how many sessions any individual can be scheduled for
max_span = 4
# poster balance
poster_balance = 10
# We can also set an exception for people who have registered to give too 
# many talks.
# Span exception emails
span_exceptions = Set(["1342cbee8b921175", "304f201b6192205f", "e7d16246d8683cea"] )

timelimit = 60.0*60*16.75 # run for 9 hours 
#timelimit = 60.0*40 # run for 40 minutes

# Presolve 
presolve_level = -1 # aggressive presolve, set to -1 for default, 0 for off, and 1 for conservative 

## Read the input from a yaml file
mini = YAML.load_file("minisymposia-edit.yaml", dicttype=OrderedDict)
miniposters = YAML.load_file("matched_posters.yaml", dicttype=OrderedDict)
posters = YAML.load_file("posters.yaml", dicttype=OrderedDict)


# We need to do a bunch of checking to make sure that scheduling is plausibly feasible.
# things like: we don't have two posters in two minisymposia. 
function _check_for_duplicate_posters_in_minisymposia()
  # make sure that each poster-id associated with a Minisymposium
  # is assigned to only one minisymposium
  poster2mini = Dict{Int, Vector{Int}}()
  for (i, ms) in enumerate(keys(miniposters))
    for poster in miniposters[ms]["poster-ids"]
      if haskey(poster2mini, poster)
        push!(poster2mini[poster], i)
      else
        poster2mini[poster] = [i]
      end
    end
  end
  for poster in keys(poster2mini)
    if length(poster2mini[poster]) > 1
      println("Poster $poster is assigned to multiple minisymposia: ", poster2mini[poster])
    end
  end
end 
_check_for_duplicate_posters_in_minisymposia()

function _all_emails()
  emails = Set{String}()
  for ms in values(mini)
    for email in ms["emails"]
      push!(emails, email)
    end
  end
  for ps in values(miniposters)
    for email in ps["poster-emails"]
      push!(emails, email)
    end
  end 
  for ps in values(posters)
    push!(emails, ps["email"])
  end
  return emails
end 
emails = _all_emails()

## check how many emails are in multiple mini symposia
function _index_emails()
  email2mini = Dict{String, Vector{Int}}()
  for email in emails
    email2mini[email] = []
  end
  for (i, ms) in enumerate(keys(mini))
    for email in mini[ms]["emails"]
      push!(email2mini[email], i)
    end
  end
  for (i, ps) in enumerate(keys(miniposters))
    for email in miniposters[ps]["poster-emails"]
      push!(email2mini[email], i)
    end
  end
  return email2mini
end
email2mini = _index_emails()
# build an index of poster ids
posterindex = Dict{Int, Int}(p["id"] => i for (i, p) in enumerate(values(posters)))

# some of the posters were added later, so they don't exist...
for (i, ms) in enumerate(keys(mini))
  ps = miniposters[ms] 
  for posterid in ps["poster-ids"]
    # some of the posters were added later, so they don't exist... 
    if !haskey(posterindex, posterid)
      # we need to add this to pindex 
      push!(posters, Dict("email" => "unknown-$(posterid)", "id" => posterid, "title"=>"unknown", "first_name"=>"unknown", "last_name"=>"unknown"))
      posterindex[posterid] = length(posters)
    end 
  end
end

# NOTE: It's okay if an email address doesn't have a mini associated with It
# that gives the number of "free" posters...
println("Free people: $(length(filter(x->length(x[2]) == 0, email2mini)))")

## Setup constraints and variable sizes 
# this is the number of distinct rooms we have 
nrooms = 10 
# this is the number of time slots. 
nslots = 10 
# this is the number of poster slots. 
nposterslots = 5
maxposters = 150
days = [ [1,2], [3,4], [5,6], [7,8], [9,10] ] 
nmini = length(mini)
nposters = length(posters)
nemails = length(emails)


# index the minisymposia
mini_id = Dict(keys(mini) .=> 1:nmini)
id2mini = collect(keys(mini))

## 
# This was a really nasty thing to debug if this isn't true. 
function _check_days()
  # flatted the array days
  #d = [ i for i in v for v in days]
  alldays = Set()
  ndays = 0 
  for d in days
    for s in d 
      push!(alldays, s)
      ndays += 1
    end 
  end 
  @assert(ndays == length(alldays))
end
_check_days()


function compute_topic_penalty(sim, assignments)
  penalty = 0
  for slot in 1:nslots
    for m in 1:nmini, m2 in 1:nmini
      if sum(assignments[m,:,slot]) > 0 &&  sum(assignments[m2,:,slot]) > 0
        penalty += sim[m,m2]
      end
    end
  end
  return penalty
end
##
#m = Model(optimizer_with_attributes(Gurobi.Optimizer, "TimeLimit" => timelimit, "Presolve" => presolve_level))
# replaced with GLPK for public codes. I used the line above. 
m = Model(optimizer_with_attributes(GLPK.Optimizer, "tm_lim" => timelimit))
@variable(m, assignments[1:nmini,1:nrooms,1:nslots], Bin)
@variable(m, postersessions[1:nposters,1:nposterslots], Bin)
@variable(m, sametime[1:nmini,1:nmini,1:nslots], Bin)
@variable(m, conflict[1:nmini,1:nmini], Bin)

# All minisymposia must be scheduled
for i in 1:nmini
  @constraint(m, sum(assignments[i,:,:]) == 1)
end
# All poseters must be scheduled
for i in 1:nposters
  @constraint(m, sum(postersessions[i,:]) == 1)
end 
# Each room can only be used once in the same timeslot
for i in 1:nrooms, j in 1:nslots
  @constraint(m, sum(assignments[:,i,j]) <= 1)
end
# There are not too many posters in a given session_info
for j in 1:nposterslots
  @constraint(m, sum(postersessions[:,j]) <= maxposters)
end 
# Posters for a mini are scheduled on the same day
for (i, ms) in enumerate(keys(mini))
  ps = miniposters[ms] 
  for posterid in ps["poster-ids"]
    pindex = posterindex[posterid]
    for (dayindex, d) in enumerate(days)
      @constraint(m, postersessions[pindex,dayindex] <= sum(assignments[i,:,d[1]]) + sum(assignments[i,:,d[2]]))
    end
  end
end
# Enforce prerequisites
for (i, ms) ∈ enumerate(keys(mini))
  if haskey(mini[ms], "prereq")
    for (j, ms2) ∈ enumerate(keys(mini))
      if ms2 == mini[ms]["prereq"]
        print(ms, " has a prerequisite of ", mini[ms]["prereq"], "; ", i, " must come after ", j, "\n")
        @constraint(m, sum([s*sum(assignments[j,:,s]) for s in 1:nslots]) + 1 <= sum([s*sum(assignments[i,:,s]) for s in 1:nslots]))
        break
      end
    end
  end
end
# Enforce speaker availability constraints
for (i, ms) ∈ enumerate(keys(mini))
  if haskey(mini[ms], "available-slots")
      print(ms, "(", i, ") is only available during the timeslots ", mini[ms]["available-slots"], "\n")
      for s ∈ 1:nslots
          if s ∉ mini[ms]["available-slots"]
              @constraint(m, sum(assignments[i,:,s]) == 0)
          end
      end
  end
end
# Don't oversubscribe a given speaker/organizer
for (i, ms) ∈ enumerate(keys(mini)), (j, ms2) ∈ enumerate(keys(mini)), email ∈ mini[ms]["emails"]
  if j <= i
    continue
  end
  if email ∈ mini[ms2]["emails"]
    print(i, " and ", j, " cannot occur at the same time due to ", email, "\n")
    for s=1:nslots
      @constraint(m, sum(assignments[i,:,s]) + sum(assignments[j,:,s]) <= 1)
    end
  end
end
# Don't oversubscribe a poster presenter
for (i, ms) ∈ enumerate(keys(mini)), (j, ms2) ∈ enumerate(keys(mini)), poster ∈ miniposters[ms]["poster-emails"]
  if j <= i
      continue
  end
  if poster ∈ miniposters[ms2]["poster-emails"]
    print(i, " and ", j, " cannot be on the same day due to sharing a poster ", poster, "\n")
    for d in days
      @constraint(m, sum(assignments[i,:,d[1]]) + sum(assignments[i,:,d[2]]) + sum(assignments[j,:,d[1]]) + sum(assignments[j,:,d[2]]) <= 1)
    end  
  end
end
# Don't overscribe a poster-only presenter...
for (i, p) in enumerate(posters), (j, p2) in enumerate(posters)
  if j <= i 
    continue
  end
  if p["email"] == p2["email"]
    print("Poster ", i, " and ", j, " cannot be on the same day due to ", p["email"], "\n")
    for p in 1:nposterslots
      @constraint(m, sum(postersessions[i,p]) + sum(postersessions[j,p]) <= 1)
    end
  end
end 

# Setup the poster session so we aren't too far out of balance
for i in 1:nposterslots
  for j in i+1:nposterslots
    # add the constraints
    # -poster_balance <= nposters on day i - nposters on day j <= poster_balance
    @constraint(m, sum(postersessions[:,i]) - sum(postersessions[:,j]) <= poster_balance)
    @constraint(m, -poster_balance <= sum(postersessions[:,i]) - sum(postersessions[:,j]))
    # alternative form of the second constraint... 
    #@constraint(m, sum([sum(postersessions[p,j]) for p in 1:nposters]) - sum([sum(postersessions[p,i]) for p in 1:nposters]) <= 1)
  end 
end 

# Setup the same time matrix
for i in 1:nmini, j in 1:nmini, t in 1:nslots
  @constraint(m, sametime[i,j,t] >= sum(assignments[i,:,t]) + sum(assignments[j,:,t]) - 1)
  @constraint(m, sametime[i,j,t] <= sum(assignments[i,:,t]))
  @constraint(m, sametime[i,j,t] <= sum(assignments[j,:,t]))
end

# add span variables for each email
@variable(m, upperspan[1:nemails])
@variable(m, lowerspan[1:nemails])
@variable(m, span)

for (p, email) in enumerate(emails) 
  for (i, ms) in enumerate(keys(mini))
    if email in mini[ms]["emails"] && !(email in span_exceptions)
      @constraint(m, upperspan[p] >= sum([s*sum(assignments[i,:,s]) for s in 1:nslots]))
      @constraint(m, lowerspan[p] <= sum([s*sum(assignments[i,:,s]) for s in 1:nslots]))
    end
  end
  for (i, ps) in enumerate(posters)
    if email == ps["email"] && !(email in span_exceptions)
      # assign poster session to the last session of the day. 
      @constraint(m, upperspan[p] >= sum([2s*sum(postersessions[i,s]) for s in 1:nposterslots]))
      @constraint(m, lowerspan[p] <= sum([2s*sum(postersessions[i,s]) for s in 1:nposterslots]))
    end 
  end 
end 
for p in 1:nemails
  @constraint(m, span >= upperspan[p] - lowerspan[p])
end
println("Constrainined to span $max_span")
@constraint(m, span <= max_span)


# setup the conflict matrix
for i in 1:nmini, j in 1:nmini
  @constraint(m, conflict[i,j] == sum(sametime[i,j,:]))
end

hard_edges = [
  [80452, 80608], 
  [80336, 80341], 
  [80514, 80554], 
  [80517, 80598], 
  [80558, 80605], 
  [80518, 80608], 
  [80688, 80565], 
  [80517, 80601], 
  [80400, 80608], 
  [80551, 80598], 
  [80452, 80518], 
  [80756, 80605], 
  [80336, 80346], 
  [80341, 80346], 
  [80287, 80427], 
  [80551, 80601], 
  [80688, 80587], 
  [80688, 80632], 
  [80400, 80518], 
  [80445, 80610], 
  [80587, 80609], 
  [80433, 80620], 
  [80582, 80608], 
  [80343, 80597], 
  [80346, 80521], 
  [80565, 80609], 
  [80604, 80625], 
  [80514, 80608], 
  [80265, 80625], 
  [80398, 80445], 
  [80578, 80635], 
  [80265, 80756], 
  [80441, 80534], 
  [80598, 80601], 
  [80436, 80610], 
  [80514, 80518], 
  [80400, 80452], 
  [80725, 80603], 
  [80803, 80427], 
  [80426, 80580], 
  [80452, 80514], 
  [80554, 80582], 
  [80587, 80632], 
  [80265, 80604], 
  [80559, 80597], 
  [80565, 80587], 
  [80340, 80427], 
  [80565, 80632], 
  [80265, 80558], 
  [80510, 80559], 
  [80400, 80514], 
  [80601, 80634], 
  [80558, 80625], 
  [80287, 80340], 
  [80517, 80634], 
  [80452, 80582], 
  [80756, 80625], 
  [80551, 80634], 
  [80518, 80582], 
  [80400, 80582], 
  [80517, 80551], 
  [80558, 80604], 
  [80604, 80605], 
  [80452, 80554], 
  [80343, 80510], 
  [80398, 80436], 
  # [80509, 80511],  removed 80511
  [80265, 80605], 
  [80756, 80604], 
  [80436, 80445], 
  [80518, 80554], 
  [80605, 80625], 
  [80803, 80340], 
  [80400, 80554], 
  [80554, 80608], 
  [80510, 80597], 
  [80756, 80558], 
  [80398, 80610], 
  [80514, 80582], 
  [80598, 80634], 
  [80609, 80632], 
  [80343, 80559], 
  [80688, 80609], 
  [80803, 80287], 
  [80336, 80521], 
  [80341, 80521], 
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
  #[80618, 80742], 
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
  #[80742, 80618], 
  [80514, 80541], 
  [80615, 80287], 
  [80492, 80615], 
  [80523, 80557], 
  [80343, 80562], 
  [80445, 80426], 
  [80578, 80618], 
  [80557, 80397], 
]

# add additional constraints for conflict groups
noconflict_groups = [# not at same time 
  [80562, 80598, 80541], 
  [80398, 80440, 80547, 80445, 80430, 80436, 80336, 80346, 80610, 80426], # SciML group may be hard to schedule... 
  hard_edges... 
]  



for group in noconflict_groups
  for rawi in group
    i = mini_id[rawi]
    for rawj in group 
      j = mini_id[rawj]
      #if i != j
      #  @constraint(m, conflict[mini_id[i],mini_id[j]] == 0)
      #end
      if i > j 
        for s=1:nslots
          @constraint(m, sum(assignments[i,:,s]) + sum(assignments[j,:,s]) <= 1)
        end
      end 
    end
  end
end

# build up the simialrity matrix from the class codes. 
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

# now directly enumerate all paths and weight them in a decaying fashion. 
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
scweight = all_paths_weight(scmat, 0.5)

sim = sim + scweight

# round sim, round each entry to one choice of [0,0.01,0.1,1,5,10,20,40]
# Cindy Phillips suggested this to make the problem more discrete
# and easier to solve. (Not these particular values, but just having
# a small set of discrete values to choose from.)
simorig = copy(sim) 
function nearest_rounded_value(x)
  set = (0,0.01,0.1,1,5,10,20,40)
  return set[argmin(abs.(set .- x))]
end
sim = nearest_rounded_value.(sim) 
# remove the diagonal from sim too.. 
sim = sim .- Diagonal(sim) 


@objective(m, Min, sum([sim[m,m2]*conflict[m,m2] for m in 1:nmini, m2 in 1:nmini]))
## run async... 

# Note, GLPK seems to fail when I call it with this objective :( 
# I had to use Gurobi. 
task = Threads.@spawn JuMP.optimize!(m)


## Wait for the task to finish
fetch(task)

## Record result
ass = JuMP.value.(assignments)
posterass = JuMP.value.(postersessions)

for i=1:nmini, j=1:nrooms, k=1:nslots
  if ass[i,j,k] > 0
    print(id2mini[i], " is assigned to room ", j, " in slot ", k, "\n")
  end
end

## check solution
function check_solution(A, P)
  nvio = 0 # number of violations 
  for i in 1:nmini
    if sum(A[i,:,:]) != 1
      @warn "Mini $i not assigned"
      nvio += 1
    end 
  end
  for i in 1:nrooms, j in 1:nslots
    if sum(A[:,i,j]) > 1
      @warn "Room $i assigned too many in timeslot $j"
      nvio += 1
    end
  end
  for i in 1:nposters
    if sum(P[i,:]) != 1
      @warn "Poster $i not assigned"
      nvio += 1
    end
  end

  for (i, ms) ∈ enumerate(keys(mini))
    if haskey(mini[ms], "available-slots")
      #print(ms, "(", i, ") is only available during the timeslots ", mini[ms]["available-slots"], "\n")
      for s in 1:nslots
        if !(s in mini[ms]["available-slots"])
          if sum(A[i,:,s]) != 0 
            @warn "Mini $i not available in slot $s"
            nvio += 1
          end 
        end
      end
    end
  end
  # Don't oversubscribe a given speaker/organizer
  for (i, ms) ∈ enumerate(keys(mini)), (j, ms2) ∈ enumerate(keys(mini)), email ∈ mini[ms]["emails"]
    if j <= i
      continue
    end
    if email ∈ mini[ms2]["emails"]
      #print(i, " and ", j, " cannot occur at the same time due to ", email, "\n")
      for s=1:nslots
        if sum(A[i,:,s]) + sum(A[j,:,s]) > 1
          @warn "Conflict for $email between $i and $j in slot $s "
          nvio += 1
        end
      end
    end
  end
  # make sure the poster presenters are on the same day as the minisymposium
  for (i, ms) ∈ enumerate(keys(mini))
    ps = miniposters[ms] 
    for posterid in ps["poster-ids"]
      pindex = posterindex[posterid]
      for (dayindex, d) in enumerate(days)
        if sum(A[i,:,d[1]]) + sum(A[i,:,d[2]]) != sum(P[pindex,dayindex])
          @warn "Poster $pindex / $posterid not assigned to the same day as minisymposium $i / $ms"
          nvio += 1
        end
      end
    end
  end
  # compute the topic penalty
  tp = compute_topic_penalty(sim, A)
  @info("Topic penalty: ", tp)
  # find the largest topic penalty... 
  for slot in 1:nslots
    for m in 1:nmini, m2 in 1:nmini
      if m > m2 && sum(A[m,:,slot]) > 0 &&  sum(A[m2,:,slot]) > 0
        if sim[m,m2] > 1
          @info "Soft conflict between ($m, $m2) in slot $slot with penalty $(sim[m,m2])"
          @info " - $(mini[id2mini[m]]["title"])"
          @info " - $(mini[id2mini[m2]]["title"])"
         # nvio += 1
        end
      end
    end
  end

  # check the span of any email address
  emails = _all_emails()

  # for each email, look over all mini symposium
  # and flag which slots the person is assigned to 
  # then look at the difference between the first and last
  # entry in the list.
  for email in emails
    schedule = zeros(Bool, nslots)
    for i in 1:nmini
      if email in mini[id2mini[i]]["emails"]
        for s in 1:nslots
          if sum(A[i,:,s]) > 0
            schedule[s] = 1
          end
        end
      end
    end
    for p in 1:nposters
      if email == posters[p]["email"]
        for s in 1:nposterslots
          if P[p,s] > 0
            schedule[last(days[s])] = 1
          end
        end
      end 
    end 
    emailspan = findlast(schedule) - findfirst(schedule)
    if emailspan > 6
      @warn "Email $email spans $emailspan slots"
      nvio += 1
    end
    if emailspan > 3
      @info "Email $email spans $emailspan slots"
    end
  end

  return nvio
end
check_solution(ass, posterass)

## Print the schedule
session_info = [
  "Monday AM"
  "Monday PM"
  "Tuesday AM"
  "Tuesday PM"
  "Wednesday AM"
  "Wednesday PM"
  "Thursday AM"
  "Thursday PM"
  "Friday AM"
  "Friday PM"
]
function _remove_newlines(str)
  str = replace(str, "\n" => " ")
  return str
end 
function print_schedule(A)
  for t in 1:nslots
    # find all mini's assigned to this
    assignments  = findall(A[:,:,t] .== 1)
    println()
    println("## $(session_info[t])")
    println()
    for I in assignments
      mini_id = I[1]; room = I[2]; 
      miniinfo = mini[id2mini[mini_id]]
      title = miniinfo["title"]
      orgs = join(miniinfo["organizers"], ", ")
      speakers = join(miniinfo["speakers"], ", ")
      println("  - $(_remove_newlines(title)) - $(id2mini[mini_id])")
      println("    by $(orgs)")
      println("    with $(speakers)")
      println()
    end 
    println()
  end 
end
print_schedule(ass)

## 
# Make a list of free posters
function _find_free_posters(posters, miniposters)
  allposters = Set(p["id"] for p in posters)
  miniposters = Set(id for ms in values(miniposters) for id in ms["poster-ids"] )
  freeposters = setdiff(allposters, miniposters)
  return freeposters
end 
freeposters = _find_free_posters(posters, miniposters)
freepeople = setdiff(Set(posters[posterindex[id]]["email"] for id in freeposters), 
                     Set(e for ms in values(mini) for e in ms["emails"]))

## Print out the schedule so I can cut/paste It
function _remove_newlines(str)
  str = replace(str, "\n" => " ")
  return str
end 
function print_schedule(A)
  for t in 1:nslots
    # find all mini's assigned to this
    assignments  = findall(A[:,:,t] .== 1)
    println()
    println()
    for I in assignments
      mini_id = I[1]; room = I[2]; 
      miniinfo = mini[id2mini[mini_id]]
      title = miniinfo["title"]
      id = id2mini[mini_id]
      print("$id,")
    end 
    println()
    for I in assignments
      mini_id = I[1]; room = I[2]; 
      miniinfo = mini[id2mini[mini_id]]
      title = _remove_newlines(miniinfo["title"])
      id = id2mini[mini_id]
      print("\"$title\",")
    end 
    println()
  end 
end
print_schedule(ass)

## print out the poster session so I can cut/paste It
function print_posters(P)
  for t in 1:nposterslots
    assignments  = findall(P[:,t] .== 1)
    println()
    println()
    for I in assignments
      posterid = I[1]; 
      posterinfo = posters[posterid]
      title = _remove_newlines(posterinfo["title"])
      id = posterinfo["id"]
      println("$t,$id,\"$title\"")
    end
  end
end
print_posters(posterass)