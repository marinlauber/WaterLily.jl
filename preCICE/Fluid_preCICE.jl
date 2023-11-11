using PreCICE
using WaterLily
using ParametricBodies
using Splines
using StaticArrays
using LinearAlgebra
include("../examples/TwoD_plots.jl"); gr();

function force(b::DynamicBody,sim::Simulation)
    reduce(hcat,[ParametricBodies.NurbsForce(b.surf,sim.flow.p,s) for s ∈ integration_points])'
end

# Material properties and mesh
numElem=4
degP=3
ptLeft = 0.0
ptRight = 1.0

# mesh
mesh, gauss_rule = Mesh1D(ptLeft, ptRight, numElem, degP)

## Simulation parameters
L=2^4
Re=500
U=1
ϵ=0.5
thk=2ϵ+√2

# overload the distance function
ParametricBodies.dis(p,n) = √(p'*p) - thk/2

# construct from mesh, this can be tidy
u⁰ = MMatrix{2,size(mesh.controlPoints,2)}(mesh.controlPoints[1:2,:]*L.+[3L,2L].+1.5)
nurbs = NurbsCurve(copy(u⁰),mesh.knots,mesh.weights)

# flow sim
body = DynamicBody(nurbs, (0,1));

# make a simulation
sim = Simulation((4L,8L), (0,U), L; ν=U*L/Re, body, T=Float64)


# make a problem
Dirichlet_BC = [
    Boundary1D("Dirichlet", ptRight, 0.0; comp=1),
    Boundary1D("Dirichlet", ptRight, 0.0; comp=2)
]
Neumann_BC = [
    Boundary1D("Neumann", ptRight, 0.0; comp=1),
    Boundary1D("Neumann", ptRight, 0.0; comp=2)
]
p = EulerBeam(1, 1, x->0.0, mesh, gauss_rule, Dirichlet_BC, Neumann_BC)

# location of integration points
integration_points = Splines.uv_integration(p)

# coupling
createSolverInterface("WaterLily", "./precice-config.xml", 0, 1)
dimensions = PreCICE.getDimensions()
numberOfVertices = 3
writeData = force(body,sim)

vertices_n = Array{Float64,2}(undef, size(u⁰')...)
vertices_f = Array{Float64,2}(undef, size(writeData)...)
vertices_n .= mesh.controlPoints[1:2,:]'
vertices_f[:,1] = integration_points
vertices_f[:,2] .= 0.0


# get mesh ID
ID_n = PreCICE.getMeshID("Nurbs-Mesh-Fluid")
ID_f = PreCICE.getMeshID("Force-Mesh-Fluid")
DataID_n = PreCICE.getDataID("Displacements", ID_n)
DataID_f = PreCICE.getDataID("Forces", ID_f)

# set mesh vertex
vertexIDs_n = PreCICE.setMeshVertices(ID_n, vertices_n)
vertexIDs_f = PreCICE.setMeshVertices(ID_f, vertices_f)

let # setting local scope for dt outside of the while loop
    ids = 1
    PreCICE.initialize()

    dt = 0.2
    PreCICE.writeBlockVectorData(DataID_f, vertexIDs_f, writeData)
    markActionFulfilled(actionWriteInitialData())

    # intialise the coupling
    PreCICE.initializeData()

    # reading initial data
    if PreCICE.isReadDataAvailable()
        # println("WaterLily: Reading initial data")
        readData = PreCICE.readBlockVectorData(DataID_n, vertexIDs_n)
        readData .= u⁰' + readData.*L
        ParametricBodies.update!(body,Matrix(readData'),dt)
    end

    # simulations time
    t = 0.0 

    while PreCICE.isCouplingOngoing()

        if PreCICE.isActionRequired(PreCICE.actionWriteIterationCheckpoint())
            # println("WaterLily: Writing iteration checkpoint")
            WaterLily.store!(sim.flow)
            markActionFulfilled(actionWriteIterationCheckpoint())
        end

        if PreCICE.isReadDataAvailable()
            # println("WaterLily: Reading data")
            readData = PreCICE.readBlockVectorData(DataID_n, vertexIDs_n)
            display(readData)
            readData .= u⁰' + readData.*L
            ParametricBodies.update!(body,Matrix(readData'),dt)
        end
        
        # solver update
        measure!(sim,t); mom_step!(sim.flow,sim.pois)
        
        if PreCICE.isWriteDataRequired(dt)
            # println("WaterLily: Writing data")
            writeData = force(body,sim)
            display(writeData)
            PreCICE.writeBlockVectorData(DataID_f, vertexIDs_f, writeData)
        end
        
        PreCICE.advance(dt)

        if PreCICE.isActionRequired(PreCICE.actionReadIterationCheckpoint())
            # println("WaterLily: Reading iteration checkpoint")
            WaterLily.revert!(sim.flow)
            markActionFulfilled(actionReadIterationCheckpoint())
        end

        if PreCICE.isTimeWindowComplete()
            t += dt
        end

    end # while

    get_omega!(sim); plot_vorticity(sim.flow.σ',limit=10)
    # plot!(body.surf, show_cp=false)
    c = [body.surf(s,0.0) for s ∈ 0:0.01:1]
    plot!(getindex.(c,2).+0.5,getindex.(c,1).+0.5,linewidth=2,color=:black,yflip=true)
    savefig("Waterlily_preCICE.png")
end # let

PreCICE.finalize()
println("WaterLily: Closing Julia solver...")