# Code gallery

This page gives an overview of the code gallery. Compared to the [Examples](../examples/index.md),
these programs do not focus on teaching WaterLily itself. They show what WaterLily can do *in
combination with the rest of its ecosystem* -- the companion packages that add the geometry,
boundary-condition and coupling machinery the solver deliberately leaves out.

!!! note "Contribute to the gallery!"
    Most of the gallery is user contributed. If you use WaterLily, and have something you want to
    share, please contribute to the gallery! This could be the solver for a published paper, a
    coupling to another code, or just a nice trick.

!!! note "These programs are not run when the docs are built"
    Unlike the [Examples](../examples/index.md), gallery programs are shown but not executed. They
    depend on packages outside this documentation's environment, and several are far too large for
    a documentation build -- a Biot-Savart or fluid-structure run is not a thing you want on every
    commit. Each page lists the packages it needs and shows a figure produced by running it
    separately. The trade-off is the usual one: nothing here is checked by the build, so a program
    can go stale without anything failing to warn you.

```@raw html
<div class="gallery-card"><div class="gallery-card-figure">
```

![](ParametricBodies_FlexiblePlate.gif)

```@raw html
</div><div class="gallery-card-body">
```

#### [A flexible plate with ParametricBodies](ParametricBodies_FlexiblePlate.md)

A thin plate whose shape is a NURBS curve, deforming in a cross-flow while the simulation runs.
`AutoBody` needs a signed distance function, which a deforming spline does not readily give you;
[ParametricBodies.jl](https://github.com/WaterLily-jl/ParametricBodies.jl) supplies the distance
and the body velocity for smooth parametric curves instead, in 2D and 3D. This is also the
interface a structural solver drives in a fluid-structure problem.

**Packages**: [ParametricBodies.jl](https://github.com/WaterLily-jl/ParametricBodies.jl).

```@raw html
</div></div>
```

## The wider ecosystem

These are the packages a gallery program is most likely to reach for:

- [**ParametricBodies.jl**](https://github.com/WaterLily-jl/ParametricBodies.jl) -- bodies defined
  by parametric curves and NURBS rather than by a distance function, including bodies that deform
  while the simulation runs.
- [**BiotSavartBCs.jl**](https://github.com/WaterLily-jl/BiotSavartBCs.jl) -- replaces the domain
  boundary condition with a Biot-Savart evaluation of the velocity induced by the vorticity in the
  domain, so a much smaller domain behaves as if it were unbounded. Useful for freely moving bodies
  and for forces that are sensitive to blockage.
- [**ForcePartition.jl**](https://github.com/WaterLily-jl/ForcePartition.jl) -- splits a measured
  force into the mechanisms that produce it (vortex-induced, added-mass, viscous) rather than
  reporting a single number.
- [**WaterLilyPreCICE.jl**](https://github.com/WaterLily-jl/WaterLilyPreCICE.jl) -- couples
  WaterLily to a structural solver through [preCICE](https://precice.org), for fluid-structure
  interaction where the structure needs a code of its own.

Of these, only ParametricBodies is in the General registry; the others are installed from their
repository URL. Since gallery programs are not executed here, that makes no difference to the
documentation build -- it only matters when you run one yourself.

## Adding a program

Drop a Literate program into `docs/src/literate-gallery/`, add it to the `pages` list in
`docs/make.jl`, and give it a card above. Put the figure next to the program as a `.gif` or `.png`
with the same name: `docs/generate.jl` copies image files straight through, so it ends up beside
the generated page and both the page and this overview can link to it.

A card is the entry's markdown wrapped in two `@raw html` blocks:

````markdown
```@raw html
<div class="gallery-card"><div class="gallery-card-figure">
```

![](my_program.gif)

```@raw html
</div><div class="gallery-card-body">
```

#### [My program](my_program.md)

What it does, and why it needs the packages it needs.

**Packages**: [SomePackage.jl](https://github.com/...).

```@raw html
</div></div>
```
````

The links stay ordinary markdown so that Documenter rewrites them correctly; only the wrapper is
raw HTML. The styling lives in `docs/src/assets/custom.css`.
