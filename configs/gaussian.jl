module NestModel

using Distributions

export nlive, niter, empirical_vol, ntest, πd, logℓ, gifname

# Nested Sampler Settings
nlive = 50
niter = 200

# Volume settings
empirical_vol = false
ntest = 1000

# Priors and Parameters
a = 5.
π1 = Uniform(-a, a)
π2 = Uniform(-a, a)

πd = Product([π1, π2])

# Log-likelihood

function logℓ(θ1::Float64, θ2::Float64)
    return -(θ1^2 + θ2 ^ 2)
end
function logℓ(θ::Vector{Float64})
    return -sum(θ .^ 2)
end
function logℓ(θsample::Matrix{Float64})
    return logℓ.([θsample[:, i] for i in 1:size(θsample)[2]])
end

gifname = "../gifs/gaussian.gif"

end