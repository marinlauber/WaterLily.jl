using WaterLily
using ParametricBodies
using Splines
using StaticArrays
using LinearAlgebra
using SparseArrays
include("examples/TwoD_plots.jl")
include("Coupling.jl")

function force(b::DynamicBody,sim::Simulation)
    reduce(hcat,[NurbsForce(b.surf,sim.flow.p,s) for s ∈ integration_points])
end

Ca2Young(Ca, h, L, U=1, ρ=1, ν=0.3) = Ca*(12*(1.0-ν^2)*ρ*U^2*L^3)/(h^3)
Mρ2Density(Mᵨ, h, L) = Mᵨ*L/h

# Material properties and mesh
numElem=4
degP=3
ptLeft = 0.0
ptRight = 1.0
L=1.0

# parameters
Ca = 0.35
Mᵨ = 0.5
nu = 0.0
h = L/64
E = Ca2Young(Ca, h, L, 1, 1, nu)
EI = 0.35
EA = 100.0
density(ξ) = 5.0

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
struc = GeneralizedAlpha(FEOperator(mesh, gauss_rule, EI, EA, Dirichlet_BC, Neumann_BC; ρ=density); ρ∞=0.5)

## Simulation parameters
L=2^5
Re=500
U=1
ϵ=0.5
thk=2ϵ+√2

# overload the distance function
ParametricBodies.dis(p,n) = √(p'*p) - thk/2

# construct from mesh, this can be tidy
u⁰ = MMatrix{2,size(mesh.controlPoints,2)}(mesh.controlPoints[1:2,:]*L.+[2L,3L])
nurbs = NurbsCurve(copy(u⁰),mesh.knots,mesh.weights)

# flow sim
body = DynamicBody(nurbs, (0,1));
sim = Simulation((8L,6L),(U,0),L;U,ν=U*L/Re,body,ϵ,T=Float64)
sim.flow.Δt[end] = 0.2

t₀ = round(sim_time(sim))
duration =1.0
tstep = 0.1
ωᵣ = 0.05

# force function
integration_points = Splines.uv_integration(struc.op)

# intialise coupling
f_old = force(body,sim); f_new = copy(f_old)
pnts_old = zero(u⁰); pnts_new = copy(pnts_old)

# set up coupling
# QNCouple = Relaxation(dⁿ(struc),f_old;relax=1.0)
QNCouple = IQNCoupling(dⁿ(struc),f_old;relax=ωᵣ)
updated_values = zero(QNCouple.x)

# time loop
@time for tᵢ in range(t₀,t₀+duration;step=tstep)
    
    global f_old, pnts_old, pnts_new, f_new, updated_values;

    # update until time tᵢ in the background
    t = sum(sim.flow.Δt[1:end-1])

    while t < tᵢ*sim.L/sim.U

        # save at start of iterations
        WaterLily.store!(sim.flow)
        cache =  struc.u
        
        # time steps
        Δt = sim.flow.Δt[end]/sim.L*sim.U
        tⁿ = t/sim.L*sim.U; # previous time instant

        # implicit solve
        iter = 1; firstIteration = true; converged=false

        # iterative loop 
        while !converged

            #  integrate one in time
            solve_step!(struc, f_old, Δt)

            # get the results
            pnts_new .= reshape(struc.u[1][1:2mesh.numBasis],(mesh.numBasis,2))'

            # update the body
            ParametricBodies.update!(body,u⁰+pnts_old.*L,sim.flow.Δt[end])
            
            # update the flow
            measure!(sim,t); mom_step!(sim.flow,sim.pois)
            sim.flow.Δt[end] = 0.2

            # compute forces
            f_new .= force(body,sim)
            if tⁿ<=1.0
                f_new[2,:] .= -1.0
            end
            
            # # check that residuals have converged
            # rd = res(pnts_old,pnts_new); rf = res(f_old,f_new);
            # println("    Iter: ",iter,", rd: ",round(rd,digits=12),", rf: ",round(rf,digits=12))
            # if ((rd<1e-2) && (rf<1e-2)) || iter+1 > 4 # if we converge, we exit to avoid reverting the flow
            #     println("  Converged...")
            #     # if time step converged, reset coupling preconditionner
            #     concatenate!(updated_values, pnts_new, f_new, QNCouple.subs)
            #     finalize!(QNCouple, updated_values)
            #     f_old .= f_new; pnts_old .= pnts_new
            #     firstIteration = true
            #     break
            # end

            #check convergence
            # if firstIteration || norm_f==0.0
            #     norm_f = norm(f_new-f_old)
            # end
            # if firstIteration || norm_d==0.0
            #     norm_d = norm(pnts_new-pnts_old)
            # end

            converged_d = norm(pnts_new-pnts_old) <= norm(pnts_new) * 1e-2
            converged_f = norm(f_new-f_old) <= norm(f_new) * 1e-2
            converged = all([converged_d,converged_f])

            println("iteration $iter")
            println("relative two-norm diff of data Displacements = ",
            round(norm(pnts_new-pnts_old)/norm(pnts_new),digits=12),", limit = 1.00e-02, normalization = ",
            round(norm(pnts_old),digits=12),", conv = $converged_d")
            println("relative two-norm diff of data        Forces = ",
            round(norm(f_new-f_old)/norm(f_new),digits=12),", limit = 1.00e-02, normalization = ",
            round(norm(f_new),digits=12),", conv = $converged_f")

            # update or finaliz
            concatenate!(updated_values, pnts_new, f_new, QNCouple.subs)
            if converged || iter+1 > 10
                finalize!(QNCouple, updated_values)
                f_old .= f_new; pnts_old .= pnts_new
                converged = true
                break;
            else
                updated_values = update(QNCouple, updated_values, firstIteration)
                revert!(updated_values, pnts_old, f_old, QNCouple.subs)
            end

            # writetxt("residuals_$iter",QNCouple.r)
            # writetxt("Vmatrix_$iter",QNCouple.V)
            # writetxt("Wmatrix_$iter",QNCouple.W)
            # writetxt("c_$iter",QNCouple.c)


            # if we have not converged, we must revert
            WaterLily.revert!(sim.flow)
            struc.u[1] .= cache[1]
            struc.u[2] .= cache[2]
            struc.u[3] .= cache[3]
            iter += 1
            firstIteration = false
        end

        # finalize
        t += sim.flow.Δt[end]
    end
    
    # println("tU/L=",round(tᵢ,digits=4),", Δt=",round(sim.flow.Δt[end],digits=3))
    # # get_omega!(sim);plot_vorticity(sim.flow.σ, limit=10)
    # flood(sim.flow.p[inside(sim.flow.p)], clims=(-1,1))
    # plot!(body.surf)
    # plot!(title="tU/L $tᵢ")
end