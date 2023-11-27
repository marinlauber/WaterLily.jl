using WaterLily
using ParametricBodies
using Splines
using StaticArrays
using LinearAlgebra
# using SparseArrays
include("examples/TwoD_plots.jl")
include("Coupling.jl")

# function force(b::DynamicBody,sim::Simulation)
#     reduce(hcat,[NurbsForce(b.surf,sim.flow.p,s) for s ∈ integration_points])
# end
function force(b::DynamicBody,flow::Flow)
    reduce(hcat,[NurbsForce(b.surf,flow.p,s) for s ∈ integration_points])
end

# Material properties and mesh
numElem=4
degP=3
ptLeft = 0.0
ptRight = 1.0

# parameters
EI = 0.35         # Cauhy number
EA = 100_000.0  # make inextensible
density(ξ) = 0.3  # mass ratio

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
struc = GeneralizedAlpha(FEOperator(mesh, gauss_rule, EI, EA, 
                         Dirichlet_BC, Neumann_BC; ρ=density);
                         ρ∞=0.0)

## Simulation parameters
L=2^4
Re=200
U=1
ϵ=0.5
thk=2ϵ+√2

# spline distance function
dis(p,n) = √(p'*p) - thk/2

# construct from mesh, this can be tidy
u⁰ = MMatrix{2,size(mesh.controlPoints,2)}(mesh.controlPoints[1:2,:].*L.+[2L,3L].+1.5)
nurbs = NurbsCurve(copy(u⁰),mesh.knots,mesh.weights)

# flow sim
body = DynamicBody(nurbs, (0,1); dist=dis);
sim = Simulation((8L,6L),(U,0),L;U,ν=U*L/Re,body,ϵ,T=Float64)
# sim.flow.Δt[end] = 0.1

t₀ = round(sim_time(sim))
duration = 30.0
step = 0.2
ωᵣ = 0.05

# force function
integration_points = Splines.uv_integration(struc.op)

# intialise coupling+
f_old = force(sim.body,sim.flow); f_new = copy(f_old)
pnts_old = zero(u⁰); pnts_new = copy(pnts_old)

# set up coupling
# QNCouple = Relaxation(dⁿ(struc),f_old;relax=0.8)
QNCouple = IQNCoupling(dⁿ(struc),f_old;relax=ωᵣ,maxCol=6)
updated_values = zero(QNCouple.x)

# time loop
coupling_iter = []
@time @gif for tᵢ in range(t₀,t₀+duration;step)

    global f_old, pnts_old, updated_values;

    # update until time tᵢ in the background
    t = sum(sim.flow.Δt[1:end-1])

    while t < tᵢ*sim.L/sim.U
        
        println("  tᵢ=$tᵢ, t=$(round(t,digits=2)), Δt=$(round(sim.flow.Δt[end],digits=2))")

        # save at start of iterations
        WaterLily.store!(sim.flow);
        ParametricBodies.store!(sim.body);
        cache = (copy(struc.u[1]),copy(struc.u[2]),copy(struc.u[3]))
        
        # time steps
        Δt = sim.flow.Δt[end]/sim.L*sim.U
        tⁿ = t/sim.L*sim.U; # previous time instant
        
        # implicit solve
        iter=1; firstIteration=true

        # iterative loop
        while true

            #  integrate once in time
            solve_step!(struc, f_old, Δt)
            pnts_new = dⁿ(struc)
            
            # update flow, this requires scaling the displacements
            ParametricBodies.update!(body,u⁰.+L*pnts_old,sim.flow.Δt[end])
            measure!(sim,t); mom_step!(sim.flow,sim.pois)
            # sim.flow.Δt[end] = 0.2
            f_new = force(sim.body,sim.flow)

            if tⁿ<2.0
                f_new .-= 0.5
            end

            # check that residuals have converged
            rd = res(pnts_old,pnts_new); rf = res(f_old,f_new);

            concatenate!(updated_values, pnts_new, f_new, QNCouple.subs)

            println("    Iter: ",iter,", rd: ",round(rd,digits=8),", rf: ",round(rf,digits=8))
           if ((rd<1e-2) && (rf<1e-2)) || iter+1 > 50 # if we converge, we exit to avoid reverting the flow
                println("  Converged...")
                # if time step converged, reset coupling preconditionner
                concatenate!(updated_values, pnts_new, f_new, QNCouple.subs)
                finalize!(QNCouple, updated_values)
                f_old .= f_new; pnts_old .= pnts_new
                firstIteration = true
                push!(coupling_iter,iter)
                break
            end

            # accelerate coupling
            concatenate!(updated_values, pnts_new, f_new, QNCouple.subs)
            updated_values = update(QNCouple, updated_values, firstIteration)
            revert!(updated_values, pnts_old, f_old, QNCouple.subs)
        
            # if we have not converged, we must revert
            WaterLily.revert!(sim.flow)
            ParametricBodies.revert!(sim.body);
            struc.u[1] .= cache[1]
            struc.u[2] .= cache[2]
            struc.u[3] .= cache[3]
            iter += 1
            firstIteration = false
        end

        # finish the time step
        t += sim.flow.Δt[end]
    end

    println("tU/L=",round(tᵢ,digits=4),", Δt=",round(sim.flow.Δt[end],digits=3))
    get_omega!(sim); plot_vorticity(sim.flow.σ, limit=10)
    plot!(sim.body.surf)
    plot!(title="tU/L $tᵢ")
end
