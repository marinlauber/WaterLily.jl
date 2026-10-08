```@meta
CurrentModule = WaterLily
```

# Plotting

These helpers live in a package extension and only exist once `Plots` is loaded. They are thin
wrappers — `flood` is a filled contour plot with the aspect ratio and colour limits a flow field
usually wants, and `sim_gif!` is the step-plot-repeat loop from the examples bundled into one
call. Every example on these pages uses them.

For interactive and 3D rendering — volumes, iso-surfaces, pathlines and videos — load a Makie
backend instead and use `viz!`.

```@autodocs
Modules = [Base.get_extension(WaterLily, :WaterLilyPlotsExt)]
Order   = [:function, :macro, :constant]
```
