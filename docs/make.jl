using TimerOutputs

dto = TimerOutput()
reset_timer!(dto)

const liveserver = "liveserver" in ARGS

if liveserver
    using Revise
    @timeit dto "Revise.revise()" Revise.revise()
end

# Headless GR: write plots to file without opening a window
ENV["GKSwstype"] = "100"

using Documenter, WaterLily, Plots, StaticArrays
using JLD2, ReadVTK, WriteVTK

# Parts of the API live in package extensions, and only exist once the corresponding package
# is loaded. Load them here so that their docstrings are documented and checked too.
const EXTENSIONS = map(
    ext -> Base.get_extension(WaterLily, ext),
    [:WaterLilyPlotsExt, :WaterLilyWriteVTKExt, :WaterLilyReadVTKExt, :WaterLilyJLD2Ext],
)

const is_ci = haskey(ENV, "GITHUB_ACTIONS")

# Copy the images referenced from the README (which is spliced into the WaterLily
# docstring, and therefore into the front page) next to the generated pages
include("copy_assets.jl")

# Generate the examples
include("generate.jl")

# Build documentation.
@timeit dto "makedocs" makedocs(
    modules = [WaterLily, EXTENSIONS...],
    format = Documenter.HTML(
        prettyurls = is_ci,
        canonical = "https://waterlily-jl.github.io/WaterLily.jl/stable",
        edit_link = "master",
        assets = ["assets/favicon.ico", "assets/custom.css"], # logo.png is picked up automatically
        mathengine = Documenter.MathJax3(),
        collapselevel = 1,
    ),
    sitename = "WaterLily.jl",
    draft = liveserver,
    # In draft mode the examples are not executed and the scripts/notebooks are not written,
    # so the links to them (and to the figures they produce) cannot resolve locally.
    warnonly = is_ci ? false : [:cross_references],
    pages = Any[
        "Home" => "index.md",
        "Examples" => [
            "Examples overview" => "examples/index.md",
            "examples/TwoD_Circle.md",
            "examples/TwoD_Square.md",
            "examples/TwoD_MultipleBodies.md",
            "examples/TwoD_SlowStartCircle.md",
            "examples/TwoD_OscillatingFlow.md",
            "examples/TwoD_Hover.md",
            "examples/ThreeD_TaylorGreenVortex.md",
            "examples/ThreeD_Sphere.md",
        ],
        "API reference" => [
            "Reference overview" => "reference/index.md",
            "reference/simulation.md",
            "reference/bodies.md",
            "reference/flow.md",
            "reference/poisson.md",
            "reference/metrics.md",
            "reference/grid.md",
            "reference/io.md",
            "reference/plotting.md",
            "reference/utilities.md",
        ],
        "Code gallery" => [
            "Code gallery overview" => "gallery/index.md",
            "gallery/ParametricBodies_FlexiblePlate.md",
        ]
    ],
)

# Insert a <br> in the side menu, before the code gallery
for (root, _, files) in walkdir(joinpath(@__DIR__, "build")), file in joinpath.(root, files)
    endswith(file, ".html") || continue
    str = read(file, String)
    ## matches both a leaf entry (<a>) and a collapsible section (<label>), whichever the
    ## gallery ends up being once it has sub-pages
    str = replace(
        str,
        r"""(<li(?: class="is-active")?>(?:<a class="tocitem"[^>]*>|<input[^>]*class="collapse-toggle"[^>]*/><label class="tocitem"[^>]*><span class="docs-label">)Code gallery<)""" => s"<br>\1",
    )
    write(file, str)
end

# Deploy built documentation
if !liveserver
    @timeit dto "deploydocs" deploydocs(
        repo = "github.com/WaterLily-jl/WaterLily.jl.git",
        devbranch = "master",
        target = "build",
        branch = "gh-pages",
        push_preview = true,
        versions = ["stable" => "v^", "v#.#", "dev" => "dev"],
    )
end

print_timer(dto)
