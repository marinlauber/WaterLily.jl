#!/usr/bin/env julia

# Root of the repository
const repo_root = dirname(@__DIR__)

# Make sure docs environment is active and instantiated
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

# Communicate with docs/make.jl that we are running in live mode
push!(ARGS, "liveserver")

# Run LiveServer.servedocs(...)
import LiveServer
LiveServer.servedocs(;
    host = "0.0.0.0",
    # Documentation root where make.jl and src/ are located
    foldername = joinpath(repo_root, "docs"),
    # Extra source folders to watch for changes
    include_dirs = [
        # Watch src and ext so docstrings can be Revise'd
        joinpath(repo_root, "src"),
        joinpath(repo_root, "ext"),
    ],
    skip_dirs = [
        # Skip the folder where Literate.jl output is written. This is needed
        # to avoid infinite loops where running make.jl updates watched files,
        # which then triggers a new run of make.jl etc.
        joinpath(repo_root, "docs/src/examples"),
        joinpath(repo_root, "docs/src/gallery"),
    ],
    include_files = [
        joinpath(repo_root, "docs/generate.jl"),
        joinpath(repo_root, "docs/copy_assets.jl"),
        # Watch the index file in the skip_dirs folder
        joinpath(repo_root, "docs/src/examples/index.md"),
        joinpath(repo_root, "docs/src/gallery/index.md"),
    ],
)
