# The WaterLily docstring splices in the README, which links images from the
# repository `assets/` folder using relative paths. Copy them into `docs/src/assets/`
# so those links resolve in the built documentation.

recursive_find(directory, pattern) =
    mapreduce(vcat, walkdir(directory)) do (root, dirs, files)
        joinpath.(root, filter(contains(pattern), files))
    end

const ASSETS_IN = joinpath(@__DIR__, "..", "assets")
const ASSETS_OUT = joinpath(@__DIR__, "src", "assets")
mkpath(ASSETS_OUT)

@timeit dto "copy assets" for pattern in (r"\.gif$", r"\.jpg$", r"\.png$", r"\.svg$"),
        file in recursive_find(ASSETS_IN, pattern)
    cp(file, joinpath(ASSETS_OUT, basename(file)); force = true)
end
