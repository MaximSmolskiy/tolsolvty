using DelimitedFiles: readdlm

include("tolsolvty.jl")

path_folder = "../example"

infA = readdlm(path_folder * "/infA.txt")
supA = readdlm(path_folder * "/supA.txt")

infb = readdlm(path_folder * "/infb.txt")
supb = readdlm(path_folder * "/supb.txt")

(tolmax, argmax, envs, ccode) = tolsolvty(infA, supA, infb, supb)
println("tolmax = ", tolmax)
println("argmax = ", argmax)
println("envs = ", envs)
println("ccode = ", ccode)
