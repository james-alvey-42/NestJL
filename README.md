# NestJL
Nested sampling algorithm written in pure Julia

## How to run
1. Generate a config file, see e.g. configs/gaussian.jl specifying the nested sampling settings, priors and likelihood function
2. `cd` to the `src/` folder and run `julia -i nestjl.jl [path/to/config.jl]`
3. This will open an interactive session, the iterations can be stopped gracefully at any time using `ctrl-c`
