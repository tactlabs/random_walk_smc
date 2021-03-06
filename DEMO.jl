####################
####### DEMO #######
####################

## import required packages ##
using Distributions
import LightGraphs
import Gadfly
import Plots
Plots.gr()
using LaTeXStrings

include("rw_smc.jl")
include("utils.jl")
include("rand_rw.jl")
include("gibbs_updates.jl")

# set seed
srand(0)

########################
######### DATA #########
########################

######### SYNTHETIC #########
    syn_data = true
    # set synthetic data parameters
    n_edges_data = 25 # number of edges
    α = 0.25 # parameter for new vertex probability
    λ = 4.0 # paramter for random walk length distribution
    ld = Poisson(λ) # random walk length distribution (automatically shifted by +1 if minimum is zero)
    sb = true # degree-biased distribution for first vertex at each step (false for uniform distribution)

    # sample simple graph (returns edge list)
    g = randomWalkSimpleGraph(n_edges=n_edges_data,alpha_prob=α,length_distribution=ld,sizeBias=sb)

    # convert edge list to adjacency matrix
    A = edgelist2adj(g)
    Gadfly.spy(A)

######### REAL DATA #########
    syn_data = false
    # SJS
    # g = readcsv("data/sjsAdj.csv",Int64)
    # NIPS
    g = readcsv("data/nipsAdj_02_03.csv",Int64)
    # PPI
    # g = readcsv("data/interactomeAdj.csv",Int64)

    n_edges_data = size(g,1)
    # convert edge list to adjacency matrix
    A = edgelist2adj(g)
    Gadfly.spy(A)

######################################
# INTERFACE WITH LIGHTGRAPHS PACKAGE #
######################################

# create LightGraphs.Graph object for use with LightGraphs functions
    lg = LightGraphs.Graph(A)

    # Examples:
    lg_conn = LightGraphs.is_connected(lg)
    lg_diam = LightGraphs.diameter(lg)


#######################################
#### RUN SMC WITH FIXED PARAMETERS ####
#######################################

n_particles = 100

α_fixed = α
λ_fixed = λ

particle_paths,log_marginal = SMC(g,n_particles,α_fixed,λ_fixed,sb)

############################
#### RUN PARTICLE GIBBS ####
############################

# set sampler parameters
n_particles = 100
n_mcmc_iter = 500 # total number of iterations; includes burn-in
n_burn = 100 # burn-in
n_collect = 10 # collect a sample every n_collect iterations
k_trunc = 10*lg_diam # truncation for support of latent K distribution

# set starting values for sampling (can be anything)
α_start = convert(Float64,0.5*(maximum(g)-1)/(n_edges_data-1))
λ_start = convert(Float64,sqrt(lg_diam))

# set prior parameters
a_α = 1.0
b_α = 1.0
a_λ = 1.0
b_λ = 0.25

n_print = 1 # print progress updates every n_print iterations

samples = ParticleGibbs(g,n_particles,
                  a_α,b_α,a_λ,b_λ,
                  α_start,λ_start,sb,k_trunc,
                  n_mcmc_iter,n_burn,n_collect,n_print)

# plot samples
Plots.scatter(samples["lambda"],samples["alpha"],legend=false,
          ylims=[0,1],xlims=[0,15],
          markershape=:circle,markersize=5.5,markeralpha=0.7,markercolor=:grey,markerstrokewidth=0.0,
          xlabel=L"\lambda",ylabel=L"\alpha")
if syn_data
    Plots.scatter!([λ],[α],legend=false,marker=(:star4,12.0,1.0,:black))
end

# plot edge sequence
Plots.plot(samples["edge_sequence"]',legend=false,xlabel="Sampled arrival order",ylabel="Edge index")
