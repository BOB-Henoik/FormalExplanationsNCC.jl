module PIMaximality

export 
    fit,
    explain_maximality,
    explain_all,
    fitted_params,
    fitted_decisions

include("utils.jl")
include("doubt.jl")
include("dominance.jl")

end