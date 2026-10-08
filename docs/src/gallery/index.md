# Code gallery

This page gives an overview of the code gallery. Compared to the [Examples](../examples/index.md),
these programs do not focus on teaching WaterLily itself. They show what WaterLily can do *in
combination with the rest of its ecosystem* -- the companion packages that add geometry,
boundary-condition and coupling machinery the solver deliberately leaves out.

!!! note "Contribute to the gallery!"
    Most of the gallery is user contributed. If you use WaterLily, and have something you want to
    share, please contribute to the gallery! This could be the solver for a published paper, a
    coupling to another code, or just a nice trick.

!!! note "Dependencies outside WaterLily"
    Every program here needs at least one package beyond WaterLily, named at the top of its page.
    Those are separate projects with their own release cycles, so a gallery program is a snapshot
    of how the packages fit together rather than a tested part of WaterLily. Only packages in the
    General registry can be executed when these docs are built; see the note at the end of this
    page for the rest.

---

#### [A flexible plate with ParametricBodies](ParametricBodies_FlexiblePlate.md)

A thin plate whose shape is a NURBS curve, deforming in a cross-flow while the simulation runs.
`AutoBody` needs a signed distance function, which a deforming spline does not readily give you;
[ParametricBodies.jl](https://github.com/WaterLily-jl/ParametricBodies.jl) supplies the distance
and the body velocity for smooth parametric curves instead, in 2D and 3D.

**Packages**: [ParametricBodies.jl](https://github.com/WaterLily-jl/ParametricBodies.jl).

---

## The wider ecosystem

These are the packages a gallery program is most likely to reach for:

- [**ParametricBodies.jl**](https://github.com/WaterLily-jl/ParametricBodies.jl) -- bodies defined
  by parametric curves and NURBS rather than by a distance function, including bodies that deform
  while the simulation runs. Registered, so the program above is executed when these docs build.
- [**BiotSavartBCs.jl**](https://github.com/WaterLily-jl/BiotSavartBCs.jl) -- replaces the domain
  boundary condition with a Biot-Savart evaluation of the velocity induced by the vorticity in the
  domain, which lets a much smaller domain behave as if it were unbounded. Useful for free bodies
  and for forces that are sensitive to blockage.
- [**ForcePartition.jl**](https://github.com/WaterLily-jl/ForcePartition.jl) -- splits a measured
  force into the physical mechanisms that produce it (vortex-induced, added-mass, viscous), rather
  than reporting a single number.
- [**WaterLilyPreCICE.jl**](https://github.com/WaterLily-jl/WaterLilyPreCICE.jl) -- couples
  WaterLily to a structural solver through [preCICE](https://precice.org), for fluid-structure
  interaction where the structure needs a code of its own.

!!! note "Adding a program that needs an unregistered package"
    Only ParametricBodies is in the General registry today. A gallery program that needs one of
    the others cannot simply list it in `docs/Project.toml`, so either add it by URL in
    `docs/make.jl` before the build, or write the page so that its code is shown but not run. The
    trade-off is the usual one: a program that is not executed cannot produce its own figures, and
    will go stale without anything failing to warn you.
