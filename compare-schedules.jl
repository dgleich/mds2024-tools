## Compare schedules
include("schedule-2024-06-21.jl")
s1 = (minis=deepcopy(minisessions), posters=deepcopy(postersessions))
include("schedule-2024-07-26.jl")
s2 = (minis=deepcopy(minisessions), posters=deepcopy(postersessions))

function  _compare_posters(p1, p2)
  # posters in p1 but not in p2
  p1_not_p2 = setdiff(p1,p2)
  p2_not_p1 = setdiff(p2,p1)
  if length(p1_not_p2) > 0
    println("Posters in p1 but not in p2: ", p1_not_p2)
  end
  if length(p2_not_p1) > 0
    println("Posters in p2 but not in p1: ", p2_not_p1)
  end

end 

function compare_schedules(s1,s2)
  for (i, (m1, m2)) in enumerate(zip(s1.minis, s2.minis))
    if m1 != m2
      println("Minisession $i is different")
      println("  Schedule 1: $m1")
      println("  Schedule 2: $m2")
    end
  end
  for (i, (p1, p2)) in enumerate(zip(s1.posters, s2.posters))
    p1 = Set(p1)
    p2 = Set(p2) 
    if p1 != p2
      println("Postersession $i is different")
      _compare_posters(p1, p2)
    end
  end
end 
compare_schedules(s1,s2)