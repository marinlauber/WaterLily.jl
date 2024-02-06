using WaterLily
using ParametricBodies
using Splines
using StaticArrays
using LinearAlgebra
include("examples/TwoD_plots.jl")
include("Coupling.jl")

function force(b::DynamicBody,flow::Flow)
    reduce(hcat,[NurbsForce(b.surf,flow.p,s) for s ∈ integration_points])
end

# ENV["JULIA_DEBUG"] = Main

# overwrite the momentum function so that we get the correct BC
@fastmath function WaterLily.mom_step!(a::Flow,b::AbstractPoisson)
    a.u⁰ .= a.u; a.u .= 0
    # predictor u → u'
    WaterLily.conv_diff!(a.f,a.u⁰,a.σ,ν=a.ν)
    WaterLily.BDIM!(a); BC2!(a.u,a.U)
    WaterLily.project!(a,b); BC2!(a.u,a.U)
    # corrector u → u¹
    WaterLily.conv_diff!(a.f,a.u,a.σ,ν=a.ν)
    WaterLily.BDIM!(a); BC2!(a.u,a.U,2)
    WaterLily.project!(a,b,2); a.u ./= 2; BC2!(a.u,a.U)
    push!(a.Δt,WaterLily.CFL(a))
end

# BC function using the profile
function BC2!(a,A,f=1)
    N,n = WaterLily.size_u(a)
    for j ∈ 1:n, i ∈ 1:n
        if i==j # Normal direction, impose profile on inlet and outlet
            for s ∈ (1,2,N[j])
                @WaterLily.loop a[I,i] = f*A[i] over I ∈ WaterLily.slice(N,s,j)
            end
        else  # Tangential directions, interpolate ghost cell to no splip
            @WaterLily.loop a[I,i] = -a[I+δ(j,I),i] over I ∈ WaterLily.slice(N,1,j)
            @WaterLily.loop a[I,i] = -a[I-δ(j,I),i] over I ∈ WaterLily.slice(N,N[j],j)
        end
    end
end

# Material properties and mesh
numElem=4
degP=3
ptLeft = 0.0
ptRight = 1.0
EI = 4.0
EA = 400000.0
density(ξ) = 3

# mesh
mesh, gauss_rule = Mesh1D(ptLeft, ptRight, numElem, degP)

# boundary conditions
Dirichlet_BC = [
    Boundary1D("Dirichlet", ptRight, 0.0; comp=1),
    Boundary1D("Dirichlet", ptRight, 0.0; comp=2)
]
Neumann_BC = [
    Boundary1D("Neumann", ptRight, 0.0; comp=1),
    Boundary1D("Neumann", ptRight, 0.0; comp=2)
]

# make a structure
struc = DynamicFEOperator(mesh, gauss_rule, EI, EA, 
                          Dirichlet_BC, Neumann_BC, ρ=density; ρ∞=0.0)

## Simulation parameters
L=2^4
Re=100
U=1
ϵ=0.5
thk=2ϵ+√2

# overload the distance function
dis(p,n) = √(p'*p) - thk/2

# construct from mesh, this can be tidy
u⁰ = MMatrix{2,size(mesh.controlPoints,2)}(mesh.controlPoints[1:2,:]*L.+[3L,3L].+1.5)
nurbs = NurbsCurve(copy(u⁰),mesh.knots,mesh.weights)

# flow sim
body = DynamicBody(nurbs, (0,1); dist=dis);

# force function
integration_points = uv_integration(struc)

# make a simulation
sim = CoupledSimulation((4L,6L),(0,U),L,body,struc,Relaxation;
                         ν=U*L/Re,ϵ,ωᵣ=0.5,maxCol=6,T=Float64)

# duration of the simulation
t₀ = 0.0; duration = 1.0; step = 0.1

# time loop
@time @gif for tᵢ in range(t₀,t₀+duration;step)

    # integrate up to time tᵢ
    # sim_step!(sim,tᵢ)
    t = sum(sim.flow.Δt[1:end-1])
    # @show t
    while t < tᵢ*sim.L/sim.U
        store!(sim); iter=1
        # @show t
        while true
            # update structure
            solve_step!(sim.struc,sim.forces,sim.flow.Δt[end]/sim.L)
            # update body
            ParametricBodies.update!(sim.body,u⁰+L*sim.pnts,sim.flow.Δt[end])
            # update flow
            measure!(sim,t); mom_step!(sim.flow,sim.pois)
            # compute new coupling variable
            sim.forces.=force(sim.body,sim.flow); sim.pnts.=points(sim.struc)
            # check convergence and accelerate
            print("    iteration: ",iter)
            print(" ")
            @show sum(sim.forces,dims=2)
            converged = update!(sim.cpl,sim.pnts,sim.forces,0.0)
            # revert!(xᵏ,sim.pnts,sim.forces,sim.cpl.subs)
            (converged || iter+1 > 50) && break
            # revert if not convergend
            revert!(sim); iter+=1
        end
        #update time
        t += sim.flow.Δt[end]
        println("tU/L=",round(t*sim.U/sim.L,digits=4),
                           ", Δt=",round(sim.flow.Δt[end],digits=3))
    end

    # plot nice stuff
    get_omega!(sim); plot_vorticity(sim.flow.p', limit=1)
    c = [body.surf(s,0.0) for s ∈ 0:0.01:1]
    plot!(getindex.(c,2),getindex.(c,1),linewidth=2,color=:black,yflip = true)
    plot!(title="tU/L $tᵢ")
end
