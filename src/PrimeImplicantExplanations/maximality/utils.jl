import FormalExplanationsBase: AbstractExplainer, fit, explain, explain_all, fitted_decisions, fitted_params
import RobustClassifiersBase: compute_dominance_matrix, DecisionRuleTypes, IncomparablePair, DominancePair, Maximality, Prediction
import MLJModelInterface: int
import FormalExplanationsNCC: compute_opp, compute_contrib, compute_threshold, decode_pred, all_explanations_maximality
using ResumableFunctions
using JuMP, HiGHS

function fit_pi(m::Maximality, class_fitresult, x)
    (cond_prob, y_prob, decode_y, decode_x, names_x, cond_count, y_count) = class_fitresult
    n_y = length(y_prob)
    x_coded::Vector{Int64} = [Int64(int(x[i])) for i in range(1, size(x, 1))]
    
    pred::Prediction = Prediction(compute_dominance_matrix(m, class_fitresult, x_coded))
    dominance_oppponents::Dict{DominancePair, Vector{Int64}} = Dict(p => compute_opp(m, class_fitresult, x_coded, p) for p in pred.dominance_pairs)
    dominance_thresholds::Dict{DominancePair, Float32} = Dict(p => compute_threshold(m, class_fitresult, dominance_oppponents[p], p.dominant, p.dominate) for p in pred.dominance_pairs)
    dominance_contrib::Dict{DominancePair, Vector{Float32}} = Dict(p => compute_contrib(m, class_fitresult, x_coded, dominance_oppponents[p], p.dominant, p.dominate) for p in pred.dominance_pairs)

    incomparability_oppponents::Dict{IncomparablePair, Vector{Vector{Int64}}} = Dict(p => [compute_opp(m, class_fitresult, x_coded, p), compute_opp(m, class_fitresult, x_coded, p, reverse=true)] for p in pred.incomparable_pairs)
    incomparability_thresholds::Dict{IncomparablePair, Vector{Float32}} = 
        Dict(p => [compute_threshold(m, class_fitresult, incomparability_oppponents[p][1], p.class1, p.class2), 
                    compute_threshold(m, class_fitresult, incomparability_oppponents[p][2], p.class2, p.class1)]
                for p in pred.incomparable_pairs)
    incomparability_contrib::Dict{IncomparablePair, Vector{Vector{Float32}}} = 
        Dict(p => [compute_contrib(m, class_fitresult, x_coded, incomparability_oppponents[p][1], p.class1, p.class2), 
                    compute_contrib(m, class_fitresult, x_coded, incomparability_oppponents[p][2], p.class2, p.class1)] 
                for p in pred.incomparable_pairs)
    (x_coded, pred, dominance_oppponents, dominance_thresholds, dominance_contrib, incomparability_oppponents, incomparability_thresholds, incomparability_contrib, decode_y, decode_x, names_x)
end

function fitted_params_pi(m::Maximality, fitresult)
    (x_coded, pred, dominance_oppponents, dominance_thresholds, dominance_contrib, incomparability_oppponents, incomparability_thresholds, incomparability_contrib, decode_y, decode_x, names_x) = fitresult
    pred=fitted_decisions_pi(m, fitresult)
    return (; x=Vector{String}(collect("$(decode_x[index].classes[x_coded[index]])" for index in 1:length(x_coded))),
        predictions=pred,
        dominance_thresholds=Dict(d => dominance_thresholds[decode_pred(m, fitresult, d)] for d in pred.dominance_pairs),
        dominance_oppponents=Dict(d => Vector{String}(collect("$(decode_x[index].classes[dominance_oppponents[decode_pred(m, fitresult, d)][index]])" for index in 1:length(x_coded)))  for d in pred.dominance_pairs),
        dominance_contrib=Dict(d => dominance_contrib[decode_pred(m, fitresult, d)] for d in pred.dominance_pairs),
        incomparability_thresholds=Dict(d => Dict(split(d, " >< ")[1] => incomparability_thresholds[decode_pred(m, fitresult, d)][1], 
                                                    split(d, " >< ")[2] => incomparability_thresholds[decode_pred(m, fitresult, d)][2]) 
                                        for d in pred.incomparable_pairs),
        incomparability_oppponents=Dict(d => Dict(split(d, " >< ")[1] => Vector{String}(collect("$(decode_x[index].classes[incomparability_oppponents[decode_pred(m, fitresult, d)][1][index]])" for index in 1:length(x_coded))),  
                                                    split(d, " >< ")[2] => Vector{String}(collect("$(decode_x[index].classes[incomparability_oppponents[decode_pred(m, fitresult, d)][2][index]])" for index in 1:length(x_coded))))
                                        for d in pred.incomparable_pairs),
        incomparability_contrib=Dict(d => Dict(split(d, " >< ")[1] => incomparability_contrib[decode_pred(m, fitresult, d)][1], 
                                                split(d, " >< ")[2] => incomparability_contrib[decode_pred(m, fitresult, d)][2]) 
                                        for d in pred.incomparable_pairs)        
    )
end

function fitted_decisions_pi(m::Maximality, fitresult)
    (_, pred, _, _, _, _, _, _, decode_y, _, _) = fitresult
    return (; undominated=Vector{String}(collect("$(decode_y.classes[class])" for class in pred.undominated)),
        dominance_pairs=Vector{String}(collect("$(decode_y.classes[d.dominant]) > $(decode_y.classes[d.dominate])" for d in pred.dominance_pairs)),
        incomparable_pairs=Vector{String}(collect("$(decode_y.classes[d.class1]) >< $(decode_y.classes[d.class2])" for d in pred.incomparable_pairs)),
    )
end