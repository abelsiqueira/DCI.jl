#December, 9th, T.M. comments:
using Krylov, LinearAlgebra, NLPModels, CUTEst, Test
#This package
using DCI
using DCI: compute_ρ, normal_step

atol = 1e-6
rtol = 1e-6
ctol = 1e-6

##
# 1st problem: check the case of an "infeasible" **unstable** initial point,
# when adding a perturbation is enough :).
#
@testset "Example 1" begin
    nlp = ADNLPModel(
        x->0.01 * (x[1] - 1)^2 + (x[2] - x[1]^2)^2,
        [2.0; 2.0; 2.0],
        #x->[x[1]^2 + x[3]^2 + 1.0],
        x->[x[1]^2 - x[3]^2 - 1.0],
        zeros(1),
        zeros(1)
    )

    x  = [0.; 1.; 0.]
    cx = cons(nlp, x)
    Jx = jac(nlp, x)
    #=
    ∇fx = grad(nlp, x)
    # λ = argmin ‖∇f + Jᵀλ‖
    λ = cgls(Jx', -∇fx)[1]

     ∇ℓxλ = ∇fx + Jx'*λ

    dualnorm = norm(∇ℓxλ)
    primalnorm = norm(cx)

    ρmax = max(ctol, 5primalnorm, 50dualnorm)
    ρ = compute_ρ(dualnorm, primalnorm, ∇fx, ρmax, ctol)
    @show primalnorm, dualnorm, ρmax, ρ
    =#
    ρ = 0.5

    z, cz, status = normal_step(nlp, ctol, x, cx, Jx, ρ;
                                η₁ = 1e-3, η₂ = 0.66, σ₁ = 0.25, σ₂ = 2.0,
                                max_eval = 1_000, max_time = 60,
                                )
    @test status == :infeasible

    xϵ = [0.; 1.; 0.] + rand(3)*ctol/norm(x)
    cx = cons(nlp, xϵ)
    Jx = jac(nlp, xϵ)
    z, cz, status = normal_step(nlp, ctol, xϵ, cx, Jx, ρ;
                                η₁ = 1e-3, η₂ = 0.66, σ₁ = 0.25, σ₂ = 2.0,
                                max_eval = 1_000, max_time = 60,
                                )
    @test status == :success
end

##
# 2nd problem: check the case of an "infeasible" **stable** initial point
#
@testset "Example 2, Mission: Impossible " begin
    nlp = ADNLPModel(
        x->0.01 * (x[1] - 1)^2 + (x[2] - x[1]^2)^2,
        [2.0; 2.0; 2.0],
        x->[x[1]^2 + x[3]^2 - 1.0],
        zeros(1),
        zeros(1)
    )

    x  = [0.; 1.; 0.]
    cx = cons(nlp, x)
    Jx = jac(nlp, x)
    ρ = 0.5

    z, cz, status = normal_step(nlp, ctol, x, cx, Jx, ρ;
                                η₁ = 1e-3, η₂ = 0.66, σ₁ = 0.25, σ₂ = 2.0,
                                max_eval = 1_000, max_time = 60,
                                )
    @test status == :infeasible

    xϵ = [0.; 1.; 0.] + rand(3)*ctol/norm(x)
    cx = cons(nlp, xϵ)
    Jx = jac(nlp, xϵ)
    z, cz, status = normal_step(nlp, ctol, xϵ, cx, Jx, ρ;
                                η₁ = 1e-3, η₂ = 0.66, σ₁ = 0.25, σ₂ = 2.0,
                                max_eval = 1_000, max_time = 60,
                                )
    @test status == :success
end

@testset "Example 3, MSS1 " begin
    nlp = CUTEstModel("MSS1")
    #obtained by running dci that stops at an infeasible point.
    x  = vcat(4.4916850028689986e-7*ones(18), 0.11624763874379575*ones(72))
    cx = cons(nlp, x)
    Jx = jac(nlp, x)
    ρ = 1e-6

    @test det(jac(nlp,x)*jac(nlp,x)') == 0.
    @test rank(jac(nlp, x)) == 45

    z, cz, status = normal_step(nlp, ctol, x, cx, Jx, ρ;
                                η₁ = 1e-3, η₂ = 0.66, σ₁ = 0.25, σ₂ = 2.0,
                                max_eval = 1_000, max_time = 60,
                                )
    @test norm(z - x) == 0.
    d = -Jx'*cz
    @test norm(d) ≤ 1.1e-7
    @test ctol*norm(cx) ≥ 1.6e-7
    @test status == :infeasible

    xϵ = x + rand(nlp.meta.nvar)*ctol/norm(x)
    cx = cons(nlp, xϵ)
    Jx = jac(nlp, xϵ)
    z, cz, status = normal_step(nlp, ctol, xϵ, cx, Jx, ρ;
                                η₁ = 1e-3, η₂ = 0.66, σ₁ = 0.25, σ₂ = 2.0,
                                max_eval = 1_000, max_time = 60,
                                )
    @show status, norm(x-z), norm(cz)
    @test status == :success
    finalize(nlp)
end