module NestModel

using Distributions

export nlive, niter, ntest, πd, logℓ, gifname

# Nested Sampler Settings
nlive = 500
niter = 500
ntest = 1000

# Priors and Parameters
a = 5.
π1 = Uniform(-a, a)
π2 = Uniform(-a, a)

πd = Product([π1, π2])

# Log-likelihood

function logℓ(θ1::Float64, θ2::Float64)
    return cos((θ1^2 + θ2^2) / π)
end
function logℓ(θ::Vector{Float64})
    return cos((θ[1]^2 + θ[2]^2) / π)
end
function logℓ(θsample::Matrix{Float64})
    return logℓ.([θsample[:, i] for i in 1:size(θsample)[2]])
end

# Output

gifname = "../gifs/trig.gif"

end