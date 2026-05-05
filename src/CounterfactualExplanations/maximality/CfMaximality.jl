module CfMaximality

export 
    fit_cf,
    explain_maximality_cf,
    explain_all_cf,
    fitted_params_cf,
    fitted_decisions_cf

include("utils.jl")
include("doubt.jl")
include("dominance.jl")

end