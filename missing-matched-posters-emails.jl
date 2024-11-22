# This script is designed to write out emails for all the 
# matched posters that are missing in a simple setting.
# see check-matched-posters.jl for the script that generates
# lists of other other missing posters in more 
# complex settings.

csvinfo = """80555	A Unified Volume-optimization Framework for Unsupervised Learning	Huang	bfbf741ef34cca25			
80452	Active and Adaptive Sampling for Data-efficient Machine Learning	Miller	7a2115fab87c94f3			
80340	Advances in Fast and Scalable Bayesian Inference	Henneking, Chen, Ghattas	d5cd9a0aa5a5ecb8	8458684e34b30814	e81a9e015faa4551	
80521	Advances in PDE Operator Learning	Liu, Chen	f0cb8af2e57e3505	85cbdffe8a0ac0ae		
80549	Advances of SDEs in Machine Learning	Feng, Zhu	fee28deb59bb45e3	84690459448a286b		
80596	Algebraic Geometry and Machine Learning	Tang, Cooper, Montufar, Rodriguez	63c0b8e1dad7c2df	942a1dfc204100b1	904ee9dd5e0ea25d	d8108f454c0d7f02
80524	Blackbox Optimization Meets Machine Learning	Cai, Liu	96fa239f149073cb	c7558e5d0571e4ed		
80510	Challenges in Data-Driven Learning for Dynamical Systems	Yang, Sing-Long	931fc1cc81be58ed	9e7f808d58e76464		
80604	Communication-efficient and Privacy-preserving Federated Learning Algorithms	Laiu	6c107a136e8dc4bc			
80316	Complex Weights in Networks and Data Science	Boettcher, Porter	fbd92cadfd720d81	a3af64c2b36f1572		
80513	Compositional Foundations for Optimization and Data Science	Fairbanks	98742c34fa177512			
80635	Computational and Statistical Aspects of Distance-Based Dimension Reduction	Kümmerle, Tasissa	c3a752bde3c733e7	472d0df6a2f96e41		
80634	Computational Methods for Measure Transport and Generative Modeling	Baptista, Hosseini, Tao	97cb6add1328bb9	9fcf7a6480c320eb	d53be202a0c4ef72	
80559	Continuous-in-time Learning for and with Deterministic and Stochastic Dynamics	Peherstorfer, Ruthotto	95a094f3b0f95b7a	3888f93f0a2b0bf4		
80347	Continuous-Time Reinforcement Learning: Bridging Theory, Algorithms, and Applications	Zhu	98ae52e299b33846			
80544	Data Science Meets Neuroscience	Thomas, Curtu, Melland	48d062c4ee77616a	8266e59f609cc3e	218e4ba536c5beb	
80425	Data Science Over Groups	Bendory, Edidin	6f8a5cd36ef2ff5d	707ecc726b1607c8		
80523	Data-Driven Learning of Dynamical Systems from Partial Observations	Stepaniants, Levine, Urteaga	a44e78c40f67bb90	8a0d22406bd0cb34	fb26c7a482e9b8a9	
80560	Data-driven Methods in Mathematical Biology	Chu	efeac9586581d021			
80613	Data-driven PDE-based Inverse Problem	Jin	8429f27e3e66c9e4			
80615	Data-Driven Regularization: Theory and Applications	Leong, Soh, O'Reilly	e2ce81c6de0daa4e	70a73164d1906d55	ab7f72cd703807d3	
80445	Data-Driven Scientific Machine Learning for the Optimization of Complex Systems	Pestourie, Chen	e50f4e65e7bbf72f	8458684e34b30814		
80343	Distribution, Dynamics, and Deep Learning	Cai	1bcbf15e730b6a43			
80608	Efficient and Robust Optimization Techniques for Structured Data Learning	Rebrova, Huang	8535954f514f5798	b2419fa4e3a59f99		
80554	Efficient Computation and Learning with Randomized Sampling and Pruning	Dong, Chen, Lei	307dc3e804d31789	cf2d215d9601595f	6e9b110fa0f59fe8	
80607	Evaluation of Large Language Models: Challenges and Application	Singh, Sapkota	bfbcc7ef3b39b256	a58af350bc3f9c40		
80632	Exploring the Intersection of Topological and Geometric Data Analysis with Biological Applications	Wang	51c3060f7ce987f3			
80605	Foundational Mathematics for AI Model Correctness	Graziani, Wild	f692ca7f17d30a42	9c7ff3aa2b0bf7fb		
80601	Foundations of Structure-exploiting Flow-based Generative Models	Zhang	b532ab917086236e			
80582	From Miles to Microns: Combining Machine Learning and Higher-order Spatial Statistics for Scientific Problems in the Data-scarce Regime	Robertson, Schaefer	e419fbd4abf27f12	10510be9ba84bf17		
80517	Generative Machine Learning Models for Uncertainty Quantification	Zhang, Tran, Zhang	194d6062d47b9369	b6b8ccdfeda0b360	3bead878a4688c6	
80587	Geometric and Topological Methods in Data Science and Machine Learning	Hickok, Blumberg	f5ca61822954b95d	9fb8cf377f48e992		
80511	Graduated and Continuation Optimization Techniques in Data Science and Machine Learning	Webster	2572234eb3ec00ff			
80603	Graph Learning and Network Analytics: Framework, Information Flow and Applications	Agrahari, Lamichhane	24839fbb1cdf9762	7a290aa54c53e365		
80606	High-Precision Prediction of Health Metrics Using Machine Learning	Dhakal, Devkota	e4e9840f326deecf	f160d5e807941040		
80572	Incorporating Geometry in Machine Learning: Theory and Applications	Lai	b79013511a8d0a35			
80594	Incorporating Optimal Transport in Machine Learning: Theory and Applications	Cloninger, Yu	b8801a6bc51c85c8	909bb69a281dd597		
80580	Incorporating Scientific Computation in Machine Learning	Liao	51b59913f7a0adad			
80565	Integrating Topological Data Analysis and Data Science with Biological Applications	Hozumi	5baf577f64208adf			
80287	Integration of Model and Data-Driven Methods for Large-Scale Inverse Problems	Mang, Chung	eede46d2e41fa44e	4dc93993913a67f7		
80453	Interacting Particle Systems in Data Science: From Theory to Applications	Li, Riedl, Garcia Trillos	1d6ba3553bb9f173	84c5a259a0b6b9d5	4b0a7654364bc18d	
80338	Learning Dimension and Scale Invariant Algorithms	Levin	c4de7f80f36b094b			
80597	Learning Nonlinear Differential Equations from Data	Fisher, Jedynak	a6dbfb7fb0d039a1	b83a0e8a09c56299		
80426	Machine Learning Advances in Scientific Computing and Applications	Hong, Byung-Jun	263984634b22e2f8	a65ffefd554fe690		
80424	Machine Learning and Shape Optimization	Schulz	a4f1f887987196ec			
80614	Machine Learning on Graphs for Physical Sciences and Data Analysis	Actor, Gruber, Propp	876fa3f177149c66	7c4e18e3234c16b9	9f4c236b727905ce	
80578	Manifold Learning, Trajectory Inference, and Applications in Biology	Li, Moosmueller	5094acea3b03356	7e946a1a5441d730		
80624	Mathematical and Statistical Methods for Promoting Fairness and Equity in Algorithmic Decision-Making	Qian, Kolda	23ab6f0908539d65	db619d8d3e8c57a6		
80515	Mathematical Principles in Diffusion Models	Qu, Wang	9c12187c80069680	75c0f3ac2de038aa		
80543	Mathematical Principles in Foundation Models	Buchanan, Zhu	d6b0c8b10680ea83	ea98b812b30561e0		
80265	Mathematics of Explainable AI with Applications to Finance and Medicine	Miroshnikov, Ji	397ee1f8bc65ab13	d61f0b5e8d4b19f3		
80625	Mathematics of Trustworthy Machine Learning	Sulam	2482785ca2e68e56			
80610	Modern Scientific Machine Learning from a Statistical Perspective	Chen, Wang	1342cbee8b921175	28aa60c37ab3bbac		
80403	Modern Techniques for Big Data Inverse Problems in Data Science	Pasha, Onisk	8723e7d51e4cd6e3	effb12dae7e7196c		
80561	New Frontier of Graph Machine Learning	Li, Chien	d2b009047c312857	57aad19d26b59118		
80558	New Frontier of Privacy in Machine Learning	Chien, Li	57aad19d26b59118	d2b009047c312857		
80427	Non-intrusive Computational Methods to Incorporate Prior Knowledge for Improved Statistical Accuracy	Lee	7ebe6673e9071643			
80345	Nonlinear Optimization for Data Science	Brust	8890efc8220a36b7			
80557	Operator Learning for Dynamical Systems	Chandramoorthy, Zhang	f22d86d57407e44b	b532ab917086236e		
80516	Optimization Algorithms for Mean-field Games and Applications in Data Science	Liu, Chow	9e0dc37f2f2918bd	a9b44a3a6a883e9e		
80400	Optimization Meets Statistics	Diaz	56357c77371fe34e			
80545	PDE Techniques for Generative Modeling	Wang, Narayan	41ff063d03607679	a1deed6efd984638		
80441	Preconditioning for Kernel Matrices	Wagner, Xu	dbe33a443377e9af	f31e4e7689c01759		
80439	Probabilistic Methods in Machine Learning and Complex Systems	Huynh, Clancy, Lyu	b73265b6767b2126	38b0a0e636f5934	6e8cfeb302fdaebc	
80618	Processing Data with Geometric Structure: Optimal Transport and Manifold Learning	Kileel, Moscovich	ad57b325a7bb303f	c2043ca260e43034		
80619	Randomized Iterative Algorithms for Large-scale Matrix and Tensor Data	Haddock, Ma, Yacoubou Djima	8809877899317146	922173577079fbb9	f5b492249fdbbb2b	
80312	Randomized Matrix Computations for Large-scale Scientific and Machine Learning Problems	Epperly, Webber	dc00ad0d655c559e	ab41bfb683200972		
80620	Recent Advancements in Data-driven Model Reduction: Theory, Algorithms, and Applications	Farcas, Gugercin	f1e05da167760727	820235098d502c64		
80442	Recent Advances in Data Assimilation	Bao, Zhang, Chipilski	51ca70707946d071	3bead878a4688c6	4cf6ebda0540d383	
80534	Recent Advances in Gaussian Process and Kernel Methods	Yang, Sanz-Alonso	7c982c7aeac66fcf	86e4c8811415917b		
80571	Recent Advances in Learning from High-Dimensional Data	Wang, Zhong	1f9427718447b392	796e82e8a479f83		
80440	Recent Advances in Scientific Deep Learning	Bui-Thanh, Krishnanunni, Nguyen	d5a57485389d5dbb	b626e151d883a006	9e8cd255273c62ed	
80398	Recent Advances in Scientific Machine Learning for Data-Driven Discovery of Dynamical Systems	Shin, Bao, Lee	9aa29ef8afe1dd27	51ca70707946d071	2d04e3e9471b5c7e	
80397	Recent Advances of Operator Learning and Foundation-Model-Assisted Multi-Operator Learning	Zhang, Lu	c42045d61583c4ff	3c297c5153661e5a		
80551	Recent Trends in Generative Models for Solving Probabilistic Inverse Problems	Ray	7149b09caa64f860			
80514	Sampling Algorithms from An Optimization Perspective	Liang, Chen	98627bf92538956	1ca764e4232b5fa3		
80541	Sampling and Inferences with Multimodal Distributions	He, Tao	8fa658f3ead12ca4	d53be202a0c4ef72		
80346	Scientific Computation Meets Deep Learning	Ben-Yair, Goren, Treister	7e68397168b04951	3374f161a47a52ad	277f935f0dbea9cc	
80436	Scientific Machine Learning for Inference and Control of High-dimensional Systems	Cao	63c97c9dbd0ebe26			
80547	Scientific Machine Learning for Predictive Modeling of Spatiotemporal Physics	Wang, Lu	d0edd606d0b6e36a	3c297c5153661e5a		
80336	Scientific Machine Learning for Solving Differential Equations: Computation and Applications	Xi, Wang	1db7493a8cce58f6	6b8d24ea7de982d6		
80430	Scientific Machine Learning with Scarce Data	Adcock, Musco, Musco	767712cda733544	ceb8ebccc24a416c	9645dfd5ab792353	
80509	Smoothing-Based Optimization in Data Science and Machine Learning	Starnes	94bff02640599cc0			
80339	Sparse Solutions and Low Rank Methods for Unsupervised Learning	McKenzie, Lai	70cc29c542184a48	183c7ff54dd199c1		
80530	Statistical Methods and Uncertainty Quantification	Batlle, Darcy	d388a31385b4dc46	1dbb22c9a8d10bc5		
80598	Stochastic Transport in Finite and Infinite Dimensional Generative Models	Yang	6245905d1ff7a7c1			
80492	Structure in Data: Theory, Learning, and Algorithms	Hamm	4e1094ac1ad7c397			
80588	Systems-Theoretic Approaches to Learning: Applications to Estimation and Control	Narayanan, Raghavan	a6077edede8bcae	aff80a1be391414b		
80518	Tackling Intractable Optimization	Newman, Verma	45d57bdae1597d7b	1e28c8ac00edd684		
80562	The Dynamical View of Machine Learning	Wang, Tao	14a159f4493038ea	d53be202a0c4ef72		
80433	The Interplay Between Deep Learning and Model Reduction	Wang, Liang	c852127b3b45ea34	a4b5076456bc0cd7		
80341	Theoretical Advancements in Machine Learning for Solving Partial Differential Equations	Lu	40a5b5ad3654b50b			
80609	Topological Data Visualization	Percival, Belton, Alvarado	bdd8c22f6c5f2279	8070115b7e798a97	63f9302d6e26ee2d	
80623	Understanding Double Descent	Whitehead, Transtrum, Jarvis	8fde0ed2124fbfef	70d7e993bdb4cff9	be44e33f8fe3f931
80756	Trustworthiness and Privacy in Distributed Learning: Theoretical and Applied Perspectives	Reshniak, Kotevska, Shi, Singh	2356c9c910021f42	b07d56b82ed81f1f	60a4cfae504236bc	149d50312d60eb34"""

# parse CSV info 
function parse_csvinfo(csvinfo)
  lines = split(csvinfo, "\n")
  poster_info = Dict()
  for line in lines
    parts = split(line, "\t")
    emails = filter(x->length(x) > 0, parts[4:end])
    authors = split(parts[3], ", ")
    poster_info[parse(Int, parts[1])] = (id = parse(Int, parts[1]), title = parts[2], authors, emails)
  end
  return poster_info
end
miniinfo = parse_csvinfo(csvinfo)

function write_email(session_id, matched_posters, missing_posters)
  sessionindex = findfirst(x -> x.id == session_id, miniinfo)
  sessioninfo = miniinfo[sessionindex]
  orgemails = sessioninfo.emails
  orenames = sessioninfo.authors
  sessiontitle = sessioninfo.title 

  # dump the matched_posters as a YAML string
  good_posters = join(map(s -> " - "*s, matched_posters), "\n")
  bad_posters = join(map(s -> " - "*s, missing_posters), "\n")

  return """To: $(join(orgemails, ", "))
CC: dgleich@purdue.edu, echi@rice.edu, rward@math.utexas.edu
Subject: SIAM - MDS24 - Missing Poster Information

Dear organizers of the minisymposium $sessiontitle ($(join(orenames, ", ", ", and "))): 


On reviewing matches between the poster information associated with a minisymposium, we could not
find a match for one of the posters associated with your minisymposium. 

The information we have is:
Title: $(sessioninfo[1])
Link: https://meetings.siam.org/sess/dsp_programsess.cfm?SESSIONCODE=$session_id
Matched posters: 
$(good_posters)

MISSING poster(s):
$(bad_posters)

If the poster has been submitted under a different title or author name, please let us know the new title and presenter. 

If not, we have two options. 
 
1. Send Eva Donnelly (donnelly@siam.org) the poster information below on or before Tuesday, June 11, so she can enter the missing associated posters into the system.
 
- Title
- Abstract (1,450 characters or less, including spaces)
- Presenting author name, organization, and email
- Co-author names, organizations, and emails (if applicable)
 
2. If you do not supply the required associated poster information by Tuesday, June 11, or don't reply by the deadline, we will simply remove this poster associated with you mini symposium. There may be an opportunity to add the poster back to the program at a later date, but we cannot guarantee this and it will depend on if it causes any schedule conflicts. 
 
Apologies for the short deadline, but as this information is already late, we cannot delay scheduling sessions at the conference any longer. 
 
Thanks,
David Gleich (on behalf of the MDS Co-chairs and organizing committee.) 
"""
end 
  
##
using YAML

## read matched_posters.yaml
matched_posters = YAML.load_file("matched_posters.yaml")

## Just show one missing posters
for session in keys(matched_posters)
  session_poster_info = matched_posters[session]
  missing_posters = session_poster_info["missing-posters"]
  posters = session_poster_info["posters"]
  if length(missing_posters) > 1 || length(posters) < 3 
  elseif length(missing_posters) == 1
    println(write_email(session, posters, missing_posters))
    println()
    println("-------")
    println()
  end
end 

