## write a routine to check a schedule
using YAML
include("schedule-2024-07-26-edit.jl")
miniposters = YAML.load_file("matched_posters.yaml")
minis = YAML.load_file("minisymposia-edit.yaml")
posterinfo = YAML.load_file("posters-info.yaml")

# This is a list of conflicts... 
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


# index the posters...
posters = Dict( (poster["poster"], poster) for poster in posterinfo ) 
days = [ [1,2], [3,4], [5,6], [7,8], [9,10] ]
allpeople = begin 
  people = Set{String}() 
  for (miniid, mini) in minis
    for email in mini["emails"]
      push!(people, email)
    end
    for poster in posterinfo
      push!(people, poster["email"])
    end
  end 
  people
end 

#
function _find_poster_schedule(id, postersessions)
  found = false
  for (day,posters) in enumerate(postersessions)
    if id in posters
      found = true
      return day 
    end
  end 
  return 0 
end
function _all_posters_have_info() 
  # make sure all the posters in the list of matched posters are in the other list
  all_ids = Set([poster["poster"] for poster in posterinfo])
  for session in minisessions
    for mini in session
      for id in miniposters[mini]["poster-ids"]
        if !(id in all_ids)
          @warn("Poster $id listed in minisymposium $mini not found in posterinfo")
        end
      end
    end
  end
  for (session, posterlist) in enumerate(postersessions)
    for id in posterlist
      if !(id in all_ids)
        @warn("Poster $id in postersession $session listed not found in posterinfo")
      end
    end
  end
end
function _all_posters_assigned()
  for poster in posterinfo
    id = poster["poster"]
    day = _find_poster_schedule(id, postersessions)
    if day == 0 
      if !(id in cancelled_posters)
        @warn("Poster $id not assigned")
      end 
    end
  end
end
function _posters_and_minis_sameday()
  for (day,sessionrange) in enumerate(days)
    for session in sessionrange
      for mini in minisessions[session]
        for id in miniposters[mini]["poster-ids"]
          if !(id in postersessions[day])
            posterday = _find_poster_schedule(id, postersessions)
            @warn("Poster $id assigned to mini $mini. The mini scheduled in session $session on day $day, but the poster is scheduled on day $posterday.")
          end
        end
      end
    end
  end
end 
function _check_for_person_conflicts()
  for email in allpeople
    posterschedule = zeros(Int, length(days))
    minischedule = zeros(Int, length(minisessions))
    for (day,sessionrange) in enumerate(days)
      for session in sessionrange
        for mini in minisessions[session]
          if email in minis[mini]["emails"]
            if minischedule[session] != 0
              @warn("Person $email assigned to multiple minis: $mini, $(minischedule[session]) in the same session")
            end
            minischedule[session] = mini 
          end
        end
      end
    end
    for (day,posterlist) in enumerate(postersessions)
      for poster in posterlist
        if !haskey(posters, poster)
          @error("Poster $poster not found in posterinfo!!")
          continue 
        end
        poster2 = posters[poster]
        if email == poster2["email"]
          if posterschedule[day] != 0
            @warn("Person $email assigned to multiple posters: $poster, $(posterschedule[day]) on the same day")
          end
          posterschedule[day] = poster
        end
      end
    end
  end
end 
function _poster_listed_twice()
  sessioncount = Dict{Int,Int}()
  for session in postersessions
    for poster in session
      if haskey(sessioncount, poster)
        sessioncount[poster] += 1
      else
        sessioncount[poster] = 1
      end
    end
  end
  for (poster,count) in sessioncount
    if count > 1
      @warn("Poster $poster listed $count times")
    end
  end
end 
function _mini_listed_twice()
  sessioncount = Dict{Int,Int}()
  for session in minisessions
    for mini in session
      if haskey(sessioncount, mini)
        sessioncount[mini] += 1
      else
        sessioncount[mini] = 1
      end
    end
  end
  for (mini,count) in sessioncount
    if count > 1
      @warn("Mini $mini listed $count times")
    end
  end
end

function _check_noconflict_groups()
  for group in noconflict_groups
    for m1 in group 
      for m2 in group 
        if m1 > m2 
          # make sure these aren't in the same minisession...
          for session in minisessions
            if m1 in session && m2 in session
              @error("Minis $m1 and $m2 are in the same session")
            end
          end
        end 
      end
    end
  end
end 
function _count_softconflicts()
  count = 0 
  for group in soft_edges
    for m1 in group 
      for m2 in group 
        if m1 > m2 
          # make sure these aren't in the same minisession...
          for session in minisessions
            if m1 in session && m2 in session
              count += 1
            end
          end
        end 
      end
    end
  end
  return count 
end 
function check_schedule()
  #_all_mini_posters_have_info() 
  _all_posters_have_info() 
  _all_posters_assigned()
  _posters_and_minis_sameday()
  _check_for_person_conflicts() 

  _poster_listed_twice()
  _mini_listed_twice() 
  _check_noconflict_groups()
  nsoft = _count_softconflicts()
  @info "Found $nsoft soft conflicts"
end 
check_schedule()