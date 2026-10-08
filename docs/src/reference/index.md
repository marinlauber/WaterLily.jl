# [API reference](@id api-reference)

The reference is split by the layer of the solver each function belongs to. If you are
looking for a specific name rather than browsing, the [complete index](#Index) at the bottom
of this page lists every documented binding.

- **[Simulation](simulation.md)** — the top-level object and its time loop. This is the
  entire public interface for most users.
- **[Bodies and geometry](bodies.md)** — immersed geometry: signed distance functions,
  coordinate maps, set operations, and how the solver measures a body onto the grid.
- **[Flow and time stepping](flow.md)** — the velocity and pressure fields, and the
  fractional-step momentum integrator that advances them.
- **[Pressure Poisson solvers](poisson.md)** — the projection step: the Poisson operator and
  the geometric multigrid solver that inverts it.
- **[Flow metrics](metrics.md)** — measuring the flow: forces and moments on a body,
  vorticity and other velocity-gradient quantities, and time averaging.
- **[Grid, loops and boundary conditions](grid.md)** — the Cartesian grid conventions, the
  loop macros that every kernel is written with, and the domain boundary conditions.
- **[Input and output](io.md)** — writing and restarting simulations (ParaView and JLD2).
- **[Plotting](plotting.md)** — the plotting helpers used throughout the examples.
- **[Utilities](utilities.md)** — interpolation, sub-grid-scale modelling, and 2D-to-3D
  field spreading.

```@contents
Pages = [
    "simulation.md",
    "bodies.md",
    "flow.md",
    "poisson.md",
    "metrics.md",
    "grid.md",
    "io.md",
    "plotting.md",
    "utilities.md",
]
Depth = 2
```

## Index

```@index
```
