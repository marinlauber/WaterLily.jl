```@meta
CurrentModule = WaterLily
```

# Flow metrics

These are the functions that turn a flow field into a number. Most are *cell-wise*: they take a
`CartesianIndex` and the velocity field and return the value at that cell, so they are used
inside an [`@inside`](@ref) loop writing into a scratch array (usually `sim.flow.σ`), which is
the pattern every example on these pages uses.

The forces and moments are the exception — they integrate over the immersed surface and return a
vector directly.

See [Flow over a circle](@ref examples-TwoD_Circle) for force measurement,
[Taylor-Green vortex](@ref examples-ThreeD_TaylorGreenVortex) for `λ₂` and energy, and
[many bodies at once](@ref examples-TwoD_MultipleBodies) for per-body forces.

## Forces and moments

Surface integrals over the immersed body, computed from the same kernel moments the solver uses
to apply the no-slip condition. `pressure_force(sim)` and friends take the force on the whole of
`sim.body`; pass a flow and a sub-body to get the force on one part of a composite geometry.

```@autodocs
Modules = [WaterLily]
Pages   = ["Metrics.jl"]
Filter  = f -> nameof(f) in (:pressure_force, :viscous_force, :total_force,
    :pressure_moment, :viscous_moment, :total_moment, :nds)
Order   = [:function]
```

## Velocity gradients, vorticity and vortex criteria

Cell-wise quantities derived from the velocity field and its gradient.

```@autodocs
Modules = [WaterLily]
Pages   = ["Metrics.jl"]
Filter  = f -> nameof(f) in (:ke, :∂, :S, :curl, :ω, :ω_mag, :ω_θ, :λ₂, :helicity, :shiftDir)
Order   = [:function]
```

## Time averaging

```@autodocs
Modules = [WaterLily]
Pages   = ["Metrics.jl"]
Filter  = f -> !(f isa Function) || !(nameof(f) in (:pressure_force, :viscous_force,
    :total_force, :pressure_moment, :viscous_moment, :total_moment, :nds, :ke, :∂, :S,
    :curl, :ω, :ω_mag, :ω_θ, :λ₂, :helicity, :shiftDir))
Order   = [:type, :function, :macro, :constant]
```
