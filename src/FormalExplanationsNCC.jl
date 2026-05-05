module FormalExplanationsNCC

export
    PrimeImplicantExplainer,
    CounterfactualExplainer,
    fit,
    explain,
    explain_all,
    fitted_params,
    fitted_decisions



include("MaximalityUtils.jl")
include("PrimeImplicantExplanations/PrimeImplicantExplanations.jl")
using .PrimeImplicantExplanations
include("CounterfactualExplanations/CounterfactualExplainer.jl")
using .CounterfactualExplanations


end
