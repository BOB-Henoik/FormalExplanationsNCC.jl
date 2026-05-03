module PrimeImplicantExplanations

include("maximality/PIMaximality.jl")
using .PIMaximality

export 
    PrimeImplicantExplainer,
    fit,
    explain,
    explain_all,
    fitted_params,
    fitted_decisions

using NaiveCredalClassifier
import FormalExplanationsBase: AbstractExplainer, fit, explain, explain_all, fitted_decisions, fitted_params
import RobustClassifiersBase: compute_dominance_matrix, DecisionRuleTypes, IncomparablePair, DominancePair, Maximality
import FormalExplanationsNCC: decode_pred
using ResumableFunctions

mutable struct PrimeImplicantExplainer <: AbstractExplainer
    decisionRule::DecisionRuleTypes
    PrimeImplicantExplainer(ncc::NCClassifier) = new(ncc.decisionRule)
end

fit(E::PrimeImplicantExplainer, class_fitresult, x) = fit(E.decisionRule, class_fitresult, x)

@resumable function explain(E::PrimeImplicantExplainer, fitresult, i::String)
    if E.decisionRule isa Maximality
        explain_maximality(fitresult, decode_pred(E.decisionRule, fitresult, i))
    else
        @error("Predict method not implemented for decisionRule $M")
    end
end

explain_all(E::PrimeImplicantExplainer, fitresult, i::String) = explain_all(E.decisionRule, fitresult, decode_pred(E.decisionRule, fitresult, i))

fitted_params(E::PrimeImplicantExplainer, fitresult) = fitted_params(E.decisionRule, fitresult)

fitted_decisions(E::PrimeImplicantExplainer, fitresult) = fitted_decisions(E.decisionRule, fitresult)



end