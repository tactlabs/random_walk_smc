# utilities

function elMax!{T<:Real}(x::Array{T},y::T)
  x[:] = max.(x,y)
end


function elMin!{T<:Real}(x::Array{T},y::T)
  x[:] = min.(x,y)
end

function resetArray!{T<:Real}(A::Array{T})
  A[:] = zero(eltype(A))
end


function logSumExpWeightsNorm(log_w::Vector{T} where T <: AbstractFloat)
  # function uses log-sum-exp trick to compute normalized weights of a
  # vector of numbers stored as logs, avoiding underflow
  max_entry = maximum(log_w)

  shifted_weights = log_w - max_entry
  return normalized_weights = exp.(shifted_weights)./sum(exp.(shifted_weights))

end

function logSumExpWeightsNorm!(p::Vector{T},log_w::Vector{T}) where T <: AbstractFloat
  # function uses log-sum-exp trick to compute normalized weights of a
  # vector of numbers stored as logs, avoiding underflow
  max_entry = maximum(log_w)

  shifted_weights = log_w - max_entry
  p[:] = exp.(shifted_weights)./sum(exp.(shifted_weights))

end

function logSumExpWeights(log_w::Vector{T} where T <: AbstractFloat)
  # function uses log-sum-exp trick to compute UNnormalized weights of a
  # vector of numbers stored as logs, avoiding underflow
  max_entry = maximum(log_w)

  shifted_weights = exp.(log_w .- max_entry)

end

function logSumExpWeights!(lse_w::Vector{T},log_w::Vector{T}) where T <: AbstractFloat
  # function uses log-sum-exp trick to compute UNnormalized weights of a
  # vector of numbers stored as logs, avoiding underflow
  max_entry = maximum(log_w)

  lse_w[:] = exp.(log_w .- max_entry)

end

function OneHot(n::Int64,k::Int64)

  onehotvector = spzeros(n)
  onehotvector[k] = 1
  return onehotvector

end


function stratifiedResample(weights::Vector{Float64},n_resample::Int64)::Vector{Int64}
  sample_idx = zeros(Int64,n_resample)
  stratifiedResample!(sample_idx,weights,n_resample)
  return sample_idx
end

function stratifiedResample!(sample_idx::Vector{Int64},weights::Vector{Float64},n_resample::Int64)
"""
 Implements stratified resampling as described in Appendix B of
 Fearnhead and Clifford (2003), JRSSB 65(4) 887--899

 weights is a vector of weights; n_resample is the number of resampled
 indices to return
"""
  norm_weights = cumsum(weights./sum(weights))::Vector{Float64} # normalize
  buckets = collect(0.0:(1.0/n_resample):1.0)[1:n_resample]
  locs = rand(n_resample)./n_resample .+ buckets

  sample_idx[:] = [ findfirst( locs[i] .<= norm_weights ) for i in 1:n_resample ]
  # return sample_idx
end

function systematicResample(weights::Vector{Float64},n_resample::Int64)::Vector{Int64}
  sample_idx = zeros(Int64,n_resample)
  systematicResample!(sample_idx,weights,n_resample)
  return sample_idx
end

function systematicResample!(sample_idx::Vector{Int64},weights::Vector{Float64},n_resample::Int64)

  norm_weights = cumsum(weights./sum(weights))
  buckets = collect(0.0:(1.0/n_resample):1.0)[1:n_resample]
  U = rand()*1.0/n_resample
  locs = (buckets .+ U)

  sample_idx[:] = [ findfirst( locs[i] .<= norm_weights ) for i in 1:n_resample ]
  # return sample_idx
end


function tally_ints(Z::Vector{Int},K::Int)
    """
    counts occurrences in `Z` of integers 1 to `K`
    - `Z`: vector of integers
    - `K`: maximum value to count occurences in `Z`
    """
    ret = zeros(Int,K)
    n = size(Z,1)
    idx_all = 1:n
    idx_j = trues(n)
    for j in 1:K
      for i in idx_all[idx_j]
        if Z[i]==j
          ret[j] += 1
          idx_j[i] = false
        end
      end
    end
    return ret
end

# function adj2edgelist(A::Array{Int64,2},multigraph::Bool)
# """
#   Convert binary adjacency matrix A to edge list
# """
#
#   M,N,V = findnz(triu(A))
#   if multigraph
#     return hcat(M,N),V
#   else
#     return hcat(M,N)
#   end
# end

function adj2edgelist(A::T where T<:Union{Array{Int64,2},SparseMatrixCSC{Int64,Int64}})::Array{Int64,2}
  adj2edgelist(A,false)
end

function adj2edgelist(A::T where T<:Union{Array{Int64,2},SparseMatrixCSC{Int64,Int64}},multigraph::Bool)::Array{Int64,2}
"""
  Convert binary adjacency matrix A to edge list
"""

  M,N,V = findnz(tril(A))
  if multigraph
    return hcat(M,N),V
  else
    return hcat(M,N)
  end
end

function edgelist2adj(edgelist::Array{Int64,2})::SparseMatrixCSC{Int64,Int64}
"""
  Convert edge list to binary adjacency matrix
"""

  edgelist2adj(edgelist,Int64)
end

function edgelist2adj(edgelist::Array{Int64,2},value_type::DataType)
"""
  Convert edge list to binary adjacency matrix, with non-zero values of type value_type
"""
  nv = maximum(edgelist)
  A = sparse([edgelist[:,1];edgelist[:,2]],[edgelist[:,2];edgelist[:,1]],ones(value_type,2*size(edgelist,1)),nv,nv)
end

function edgelist2adj!(A::Union{Array{Float64,2},SparseMatrixCSC{Int64,Int64},SparseMatrixCSC{Float64,Int64}},edge_list::Array{Int64,2})
"""
  Convert edge list to binary adjacency matrix, with non-zero values of type value_type
"""
  et = eltype(A)
  for i=1:size(edge_list,1)
    A[edge_list[i,1],edge_list[i,2]] = one(et)
    A[edge_list[i,2],edge_list[i,1]] = one(et)
  end

end

function normalizedLaplacian(edgelist::Array{Int64,2})::SparseMatrixCSC{Int64,Int64}
"""
  Construct (sparse) normalized Laplacian matrix
"""
  degrees = getDegrees(edgelist)
  nv = maximum(edgelist)
  L = sparse(1*I,nv,nv) - sparse(Diagonal( degrees.^(-1/2) )) * edgelist2adj(edgelist,Float64) * sparse(Diagonal( degrees.^(-1/2) ))
end

function denseNormalizedLaplacian!(L::Array{Float64,2},adj::SparseMatrixCSC{Float64,Int64},degrees::Array{Float64,1},nv::Int64)
"""
  Construct a symmetric (dense) normalized Laplacian matrix
"""
  # degrees = getDegrees(edgelist)
  # nv = maximum(edgelist)
  L[1:nv,1:nv] = Array(sparse(1*I,nv,nv) - sparse(Diagonal( degrees.^(-1/2) )) * adj * sparse(Diagonal( degrees.^(-1/2) )))
end

function denseNormalizedLaplacian!(L::Array{Float64,2},adj::SparseMatrixCSC{Int,Int64},degrees::Array{Float64,1},nv::Int64)
"""
  Construct a symmetric (dense) normalized Laplacian matrix
"""
  # degrees = getDegrees(edgelist)
  # nv = maximum(edgelist)
  L[1:nv,1:nv] = Array(sparse(1*I,nv,nv) - sparse(Diagonal( degrees.^(-1/2) )) * adj * sparse(Diagonal( degrees.^(-1/2) )))
end

function denseNormalizedLaplacian!(L::Array{Float64,2},edge_list::Array{Int64,2},degrees::Array{Float64,1},nv::Int64)
"""
  Construct a symmetric (dense) normalized Laplacian matrix. L should be all zeros.
"""
  # degrees = getDegrees(edgelist)
  # nv = maximum(edgelist)

  # set diagonal
  for n = 1:nv
    L[n,n] = 1.0
  end

  rt_deg = degrees.^(-1/2)
  for m = 1:size(edge_list,1)
    L[edge_list[m,1],edge_list[m,2]] = -(rt_deg[edge_list[m,1]]*rt_deg[edge_list[m,2]])
    L[edge_list[m,2],edge_list[m,1]] = -(rt_deg[edge_list[m,1]]*rt_deg[edge_list[m,2]])
  end

  # L[1:nv,1:nv] = Array(sparse(1*I,nv,nv) - sparse(Diagonal( degrees.^(-1/2) )) * adj * sparse(Diagonal( degrees.^(-1/2) )))
end

function getDegrees(edgelist::Array{Int64,2})::Array{Float64,1}
"""
  Compute degrees of edge list
"""
  return convert(Array{Float64,1},tally_ints(edgelist[:],maximum(edgelist)))
end

function nbPred!(pgf::Array{Float64,1},nv::Int64,a_lambda::Float64,b_lambda::Float64,evals::Union{Array{Float64,1},SparseVector{Float64,Int64}})

    for i=1:nv
      pgf[i] = ((1.0 - b_lambda)^(a_lambda))*( (1.0 .- evals[i])*((1.0 - b_lambda*(1.0 - evals[i])).^(-a_lambda)) )
      isinf(pgf[i]) ? pgf[i] = zero(Float64) : nothing # Moore-Penrose pseudo-inverse
    end

end

# function nbPred!(pgf::Array{Float64,1},a_lambda::Float64,b_lambda::Float64,evals::SparseVector{Float64,Int64})
#
#     pgf .= ((1.0 - b_lambda)^(a_lambda)).*( (1.0 .- evals).*((1.0 .- b_lambda.*(1.0 .- evals)).^(-a_lambda)) )
#
# end

# function randomWalkProbs!(W::Array{Float64,2},nv::Int64,degrees::Array{Float64,1},eig_pgf::Array{Float64,1},esys::Base.LinAlg.Eigen)
#   s = zeros(Float64,1)
#   for n = 1:nv # column index
#     for m = 1:n # row index
#       s[1] = zero(Float64)
#       for k = 1:nv
#         s[1] += esys[:vectors][m,k] * esys[:vectors][n,k] * eig_pgf[k]
#       end
#       W[m,n] = s[1]*sqrt(degrees[n]/degrees[m])
#       n==m ? nothing : W[n,m] = s[1]*sqrt(degrees[m]/degrees[n])
#     end
#
#   end
#   elMax!(W,zero(Float64)) # for numerical stability
#   elMin!(W,one(Float64)) # for numerical stability
# end

function randomWalkProbs!(W::Array{Float64,2},nv::Int64,degrees::Array{Float64,1},eig_pgf::Array{Float64,1},esys_vec::Union{Array{Float64,2},SparseMatrixCSC{Float64,Int64}})
  s = zeros(Float64,1)
  for n = 1:nv # column index
    for m = 1:n # row index
      s[1] = zero(Float64)
      for k = 1:nv
        s[1] += esys_vec[k,m] * esys_vec[k,n] * eig_pgf[k]
      end
      W[m,n] = s[1]*sqrt(degrees[n]/degrees[m])
      n==m ? nothing : W[n,m] = s[1]*sqrt(degrees[m]/degrees[n])
    end

  end
  elMax!(W,zero(Float64)) # for numerical stability
  elMin!(W,one(Float64)) # for numerical stability
end

function randomWalkProbs!(w::Array{Float64,2},vtx_pairs::Array{Int64,2},nv::Int64,degrees::Array{Float64,1},
    eig_pgf::Array{Float64,1},esys_vec::Union{Array{Float64,2},SparseMatrixCSC{Float64,Int64}})
"""
  Calculate random walk probabilities for vertex pairs in `vtx_pairs`
"""

  # w = zeros(Float64,size(vtx_pairs,1),2)
  resetArray!(w)
  for i in 1:size(vtx_pairs,1)
    for k in 1:nv
      w[i,1] += (esys_vec[k,vtx_pairs[i,1]] * esys_vec[k,vtx_pairs[i,2]] * eig_pgf[k])::Float64
    end

    w[i,2] = w[i,1]*(degrees[vtx_pairs[i,1]]/degrees[vtx_pairs[i,2]])^(0.5)::Float64
    w[i,1] *= ((degrees[vtx_pairs[i,2]]/degrees[vtx_pairs[i,1]])^(0.5))::Float64

    elMax!(w,zero(Float64)) # for numerical stability
    elMin!(w,one(Float64)) # for numerical stability

  end

end

function randomWalkProbs(root_vtx::Int64,neighbors::Array{Int64,1},nv::Int64,degrees::Array{Float64,1},eig_pgf::Array{Float64,1},esys_vec::Union{Array{Float64,2},SparseMatrixCSC{Float64,Int64}})::Float64
"""
  Calculate random walk probabilities for vertex pairs in `vtx_pairs`
"""

  w = zero(Float64)
  z = zeros(Float64,1)
  for i in 1:convert(Int64,degrees[root_vtx])
    z[:] = zero(Float64) # reset z
    for k in 1:nv
      z[1] += (esys_vec[k,root_vtx] * esys_vec[k,neighbors[i]] * eig_pgf[k])::Float64
    end
    z[1] *= sqrt(degrees[neighbors[i]]/degrees[root_vtx])::Float64
    w += z[1]::Float64
  end
  w = max(w,zero(Float64)) # for numerical stability
  w = min(w,one(Float64)) # for numerical stability
  return w

end

function fruitlessRWProb(W::Array{Float64,2},nbd_list::Array{SparseVector{Int64,Int64},1},root_vtx::Int64)::Float64

  p = zero(Float64)
  p += W[root_vtx,root_vtx]::Float64

  rnz = nbd_list[root_vtx].nzval
  for i in rnz
    p += W[root_vtx,i]
  end
  return p
end

function fruitlessRWProb(W::Array{Float64,2},nbd_list::Array{Int64,2},root_vtx::Int64)::Float64

  p = zero(Float64)
  p += W[root_vtx,root_vtx]::Float64

  i = 1
  while nbd_list[root_vtx,i] > zero(Float64)
    p += W[root_vtx,nbd_list[root_vtx,i]]
    i += 1
  end

  return p
end

function fruitlessRWProb(W::Array{Float64,2},adj::Array{Int64,2},root_vtx::Int64,nv::Int64)::Float64

  # find neighborhood of root_vtx
  # nbd = find(adj[:,root_vtx])::Array{Float64,1}

  p = zero(Float64)
  p += W[root_vtx,root_vtx]::Float64

  for i = 1:nv
    adj[i,root_vtx]==one(Float64) ? p += W[root_vtx,i] : nothing
  end
  return p
end

function generateEigenSystem!(L::Array{Float64,2},nv::Int64)::Tuple{Array{Float64,1},Array{Float64,2}}
  LL = Symmetric(L[1:nv,1:nv])
  eigvec_tr = zeros(Float64,nv,nv)
  # THIS OVERWRITES L!
  esys_val,esys_vec = LAPACK.syevr!('V','A',LL.uplo,LL.data,-0.0,0.0,0,0,-1.0)
  transpose!(eigvec_tr,esys_vec) # transposed to optimize computation

  return esys_val,eigvec_tr
end

function generateEigenSystem(L::Array{Float64,2},nv::Int64)::Tuple{Array{Float64,1},Array{Float64,2}}
  Lcopy = copy(L)
  LL = Symmetric(Lcopy[1:nv,1:nv])
  eigvec_tr = zeros(Float64,nv,nv)
  # THIS OVERWRITES Lcopy!
  esys_val,esys_vec = LAPACK.syevr!('V','A',LL.uplo,LL.data,-0.0,0.0,0,0,-1.0)
  transpose!(eigvec_tr,esys_vec) # transposed to optimize computation

  return esys_val,eigvec_tr
end

function updateEigenSystem!(L::Array{Float64,2},nv::Int64,p_state::ParticleState)

  denseNormalizedLaplacian!(L,p_state.vertex_unmap[p_state.edge_list],p_state.degrees,nv)
  LL = Symmetric(L[1:nv,1:nv])
  # THIS OVERWRITES L!
  esys_val,esys_vec = LAPACK.syevr!('V','A',LL.uplo,LL.data,-0.0,0.0,0,0,-1.0)
  # esys = eigfact!(Symmetric(L[1:nv,1:nv]))
  esys_val[1] = zero(Float64) # for numerical stability
  esys_val[end] = min(esys_val[end],Float64(2.0)) # for numerical stability

  for i=1:nv
    p_state.eig_vals[i] = esys_val[i]
    for j=1:nv
      # THIS TRANSPOSES THE EIGENVECTOR MATRIX TO OPTIMIZE COMPUTATION
      # ROWS OF p_state.eig_vecs CORRESPOND TO EIGENVECTORS OF L
      p_state.eig_vecs[j,i] = esys_vec[i,j]
    end
  end
  p_state.has_eigensystem[:] = true

end

function saveSamples!(alpha_samples::Array{Float64,1},lambda_samples::Array{Float64,1},
                      particle_trajectory_samples::Array{Int64,2},edge_sequence_samples::Array{Int64,2},
                      s_state::SamplerState,particle_container::Array{Array{ParticleState,1},1},
                      p_idx::Int64,n_sample::Int64)

  alpha_samples[n_sample] = s_state.α[1]
  lambda_samples[n_sample] = s_state.λ[1]
  particle_trajectory_samples[n_sample,:] = s_state.particle_path[:]
  edge_sequence_samples[n_sample,:] = particle_container[p_idx][end].edge_idx_list[:]

end

function uniqueParticles!(unq::Array{Int64,2},t::Int64,ed_idx::Array{Int64,1},ancestors::Array{Int64,2})

  nunq = zero(Int64)
  anc = ancestors[t,:]
  for n = 1:length(ed_idx)
    if t==1
      root_pos = findfirst( ed_idx .== ed_idx[n] )
    else
      root_pos = findfirst( ( ed_idx .== ed_idx[n] ).*( unq[t-1,anc] .== unq[t-1,anc[n]] ) )
    end

    if root_pos == n
      nunq += one(Int64)
      unq[t,n] = nunq
    else
      unq[t,n] = unq[t,root_pos]
    end
  end

end
