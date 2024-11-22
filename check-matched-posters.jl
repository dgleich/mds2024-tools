using YAML

## read matched_posters.yaml
matched_posters = YAML.load_file("matched_posters.yaml")

## report any posters with more than one missing poster
for session in keys(matched_posters)
  session_poster_info = matched_posters[session]
  missing_posters = session_poster_info["missing-posters"]
  posters = session_poster_info["poster-ids"]
  poster_emails = session_poster_info["poster-emails"]
  duplicate_presenters = length(unique(poster_emails)) < length(poster_emails)  
  if length(missing_posters) > 1 || length(posters) < 3 
    println("Session: $session")
    println("  total matched posters: $(length(posters))")
    println("  missing posters:")
    for poster in missing_posters
      println("  - $poster")
    end
  end
  if duplicate_presenters
    println("Error: duplicate presenters in session $session")
    println("  $(poster_emails)")
  end 
end 

## Just show one missing posters
for session in keys(matched_posters)
  session_poster_info = matched_posters[session]
  missing_posters = session_poster_info["missing-posters"]
  posters = session_poster_info["poster-ids"]
  if length(missing_posters) > 1 || length(posters) < 3 
  elseif length(missing_posters) == 1
    println("Session: $session")
    println("  total matched posters: $(length(posters))")
    println("  missing poster:")
    println("  - $(missing_posters[1])")
  end
end 

## 
minilist = Set([80555
80452
80340
80521
80549
80596
80524
80510
80604
80316
80513
80635
80634
80559
80347
80544
80425
80523
80560
80613
80615
80445
80343
80608
80554
80607
80632
80605
80601
80582
80517
80587
80511
80603
80606
80572
80594
80580
80565
80287
80453
80338
80597
80426
80424
80614
80578
80624
80515
80543
80265
80625
80610
80403
80561
80558
80427
80345
80557
80516
80400
80545
80441
80439
80618
80619
80312
80620
80442
80534
80571
80440
80398
80397
80551
80514
80541
80346
80436
80547
80336
80430
80509
80339
80530
80598
80492
80588
80518
80562
80433
80341
80609
80623])
for session in keys(matched_posters)
  session_poster_info = matched_posters[session]
  missing_posters = session_poster_info["missing-posters"]
  posters = session_poster_info["poster-ids"]
  
  if length(missing_posters) > 1 || length(posters) < 3 
  elseif length(missing_posters) == 1
    if session in minilist
    else
      println("Session: $session")
    println("  total matched posters: $(length(posters))")
    println("  missing poster:")
    println("  - $(missing_posters[1])")

    end 
    
  end
end 
