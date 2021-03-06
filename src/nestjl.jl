config = ARGS[1]
println("[nestjl.jl] Loading config file: ", config)
include(config)
using Main.NestModel: nlive, niter, empirical_vol, ntest, πd, logℓ, gifname
using KernelDensity
using Distributions
using Plots
using ProgressMeter

function snapshot(a::Animation, θlive_s::Matrix{Float64}, logℓ_s::Vector{Float64}, 
                  xlims::Tuple{Float64,Float64}, ylims::Tuple{Float64,Float64}, contour::Bool)
    plt = scatter(θlive_s[1, :], θlive_s[2, :], marker_z=logℓ_s, xlims=xlims, ylims=xlims)
    if contour    
        contour!(plt, range(xlims[1], xlims[2], length=200), range(ylims[1], ylims[2], length=200), logℓ)
    end        
    frame(a, plt)
end

function main()
    # Plotting settings
    show = true
    contour = true
    if show
        a = Animation()
    end

    # Initialise volume and evidence
    X = 1.
    Z = 0.

    # Initialise volume distribution and log-like
    Xd = Beta(nlive, 1)

    # Initialise strage arrays
    volumes = [X]
    evidence = [Z]
    critical = []
    live_point_time = []

    # Generate first sample from full prior
    θlive_s = rand(πd, nlive)
    logℓ_s = logℓ(θlive_s)
    if show
        snapshot(a, θlive_s, logℓ_s, (-5., 5.), (-5., 5.), contour)
    end

    # Sort arrays by the value of the log likelihood
    order = sortperm(logℓ_s)
    θlive_s = θlive_s[:, order]
    logℓ_s = logℓ_s[order]

    # Obtain critical value and drop dead points
    logℓ_star = logℓ_s[1]
    critical = append!(critical, logℓ_star)

    # Remove dead point
    θdead_s = θlive_s[:, 1]
    θlive_s = θlive_s[:, 2:size(θlive_s)[2]]
    logℓ_s = logℓ_s[2:length(logℓ_s)]

    # Estimate the volume of the constrained prior and increment evidence
    if empirical_vol
        θ_test = rand(πd, ntest)
        logℓ_test = logℓ(θ_test)
        Xnew = length(logℓ_test[logℓ_test .> logℓ_star]) / ntest
        volumes = append!(volumes, Xnew)
        Z = Z + exp(logℓ_star) * (X - Xnew)
        evidence = append!(evidence, Z)
        X = Xnew

        θlive = [-5., -5.]
        for idx in 1:ntest
            if logℓ_test[idx] > logℓ_star
                θlive = θ_test[:, idx]
                break
            end  
        end
    else
        Xnew = rand(Xd, 1)[1] * X
        volumes = append!(volumes, Xnew)
        Z = Z + exp(logℓ_star) * (X - Xnew)
        evidence = append!(evidence, Z)
        X = Xnew
        
        # Find new live point
        counter = 1
        θnew = rand(πd, 1)[:, 1]
        lℓ = logℓ(θnew)
        while lℓ < logℓ_star
            θnew = rand(πd, 1)[:, 1]
            lℓ = logℓ(θnew)
            counter += 1
        end
        θlive = θnew
        live_point_time = append!(live_point_time, counter)
    end

    θlive_s = hcat(θlive_s, θlive)
    logℓ_s = append!(logℓ_s, logℓ(θlive))
    println("[nestjl.jl] Completed first pass")
    p = Progress(niter, 
                 barglyphs=BarGlyphs('|','█', ['▁' ,'▂' ,'▃' ,'▄' ,'▅' ,'▆', '▇'],' ','|',),
                 barlen=25; 
                 showspeed=true)

    # Allow for early stopping when running in -i mode
    try
    for it in 1:niter
        next!(p, showvalues=[(:Iteration, it),
                             (:X, X),
                             (:Z, Z),
                             (:logℓ, logℓ_star),
                             (:SearchPts, counter)])
        # Sort arrays by the value of the log likelihood
        order = sortperm(logℓ_s)
        θlive_s = θlive_s[:, order]
        logℓ_s = logℓ_s[order]
        if show
            snapshot(a, θlive_s, logℓ_s, (-5., 5.), (-5., 5.), contour)
        end

        # Obtain critical value and drop dead points
        logℓ_star = logℓ_s[1]
        critical = append!(critical, logℓ_star)

        # Remove dead point
        θdead_s = hcat(θdead_s, θlive_s[:, 1])
        θlive_s = θlive_s[:, 2:size(θlive_s)[2]]
        logℓ_s = logℓ_s[2:length(logℓ_s)]

        # Estimate the volume of the constrained prior and increment evidence
        if empirical_vol
            θ_test = rand(πd, ntest)
            logℓ_test = logℓ(θ_test)
            Xnew = length(logℓ_test[logℓ_test .> logℓ_star]) / ntest
            volumes = append!(volumes, Xnew)
            Z = Z + exp(logℓ_star) * (X - Xnew)
            evidence = append!(evidence, Z)
            X = Xnew
    
            θlive = [-5., -5.]
            for idx in 1:ntest
                if logℓ_test[idx] > logℓ_star
                    θlive = θ_test[:, idx]
                    break
                end  
            end
        else
            Xnew = rand(Xd, 1)[1] * X
            volumes = append!(volumes, Xnew)
            Z = Z + exp(logℓ_star) * (X - Xnew)
            evidence = append!(evidence, Z)
            X = Xnew
            
            # Find new live point
            counter = 1
            θnew = rand(πd, 1)[:, 1]
            lℓ = logℓ(θnew)
            while lℓ < logℓ_star
                θnew = rand(πd, 1)[:, 1]
                lℓ = logℓ(θnew)
                counter += 1
            end
            θlive = θnew
            live_point_time = append!(live_point_time, counter)
        end
        θlive_s = hcat(θlive_s, θlive)
        logℓ_s = append!(logℓ_s, logℓ(θlive))
    end

    if show
        gif(a, gifname)
    end
    println("[nestjl.jl] Z = ", Z)
    return Z, volumes, evidence, critical, live_point_time, θdead_s

    catch InterruptException
    if show
        gif(a, gifname)
    end
    println("[nestjl.jl] Z = ", Z)
    return Z, volumes, evidence, critical, live_point_time, θdead_s
    end
end
 
if abspath(PROGRAM_FILE) == @__FILE__
    Z, volumes, evidence, critical, live_point_time, θdead_s = main()
end