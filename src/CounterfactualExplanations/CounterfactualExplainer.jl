module CounterfactualExplanations

include("maximality/CfMaximality.jl")
using .CfMaximality

export 
    CounterfactualExplainer,
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

mutable struct CounterfactualExplainer <: AbstractExplainer
    decisionRule::DecisionRuleTypes
    CounterfactualExplainer(ncc::NCClassifier) = new(ncc.decisionRule)
end

fit(E::CounterfactualExplainer, class_fitresult, x) = fit_cf(E.decisionRule, class_fitresult, x)

@resumable function explain(E::CounterfactualExplainer, fitresult, i::String)
    if E.decisionRule isa Maximality
        explain_maximality_cf(fitresult, decode_pred(E.decisionRule, fitresult, i))
    else
        @error("Predict method not implemented for decisionRule $M")
    end
end

explain_all(E::CounterfactualExplainer, fitresult, i::String) = explain_all_cf(E.decisionRule, fitresult, decode_pred(E.decisionRule, fitresult, i))

fitted_params(E::CounterfactualExplainer, fitresult) = fitted_params_cf(E.decisionRule, fitresult)

fitted_decisions(E::CounterfactualExplainer, fitresult) = fitted_decisions_cf(E.decisionRule, fitresult)



end