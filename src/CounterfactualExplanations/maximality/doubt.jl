@resumable function explain_maximality_cf(fitresult, i::IncomparablePair)
    (x, _, _, _, _, incomparability_oppponents, incomparability_thresholds, incomparability_contrib, decode_y, decode_x, names_x) = fitresult
	@assert haskey(incomparability_thresholds, i)
    iter_y1 = true
    iter_y2 = true
    all_explanations_y1 = all_explanations_maximality(incomparability_oppponents[i][1], incomparability_thresholds[i][1], sort(incomparability_contrib[i][1], rev=true), sortperm(incomparability_contrib[i][1], rev=true))
    all_explanations_y2 = all_explanations_maximality(incomparability_oppponents[i][2], incomparability_thresholds[i][2], sort(incomparability_contrib[i][2], rev=true), sortperm(incomparability_contrib[i][2], rev=true))
    expl_y1 = nothing
    expl_y2 = nothing
    d = Dict{Any,Union{Nothing,String}}(decode_y.classes[i.class1] => nothing, decode_y.classes[i.class2] => nothing)
    while iter_y1 || iter_y2
        if iter_y1 
            expl_y1 = iterate(all_explanations_y1)
            d[decode_y.classes[i.class1]] = !isnothing(expl_y1) ? join(("($(names_x[feature]), $(decode_x[feature].classes[value]))" for (feature, value) in expl_y1[1]), ", ") : nothing
        end
        if iter_y2 
            expl_y2 = iterate(all_explanations_y2)
            d[decode_y.classes[i.class2]] = !isnothing(expl_y2) ? join(("($(names_x[feature]), $(decode_x[feature].classes[value]))" for (feature, value) in expl_y2[1]), ", ") : nothing
        end
        @yield d       
        isnothing(expl_y1) && (iter_y1 = false)
        isnothing(expl_y2) && (iter_y2 = false)
        #!y1 && !y2 && return
    end
end

function explain_all_cf(m::Maximality, fitresult, i::IncomparablePair)
    (_, _, _, _, _, _, _, _, decode_y, _, _) = fitresult
    explanations = Dict{String, Vector{String}}(decode_y.classes[i.class1] => Vector{String}(), decode_y.classes[i.class2] => Vector{String}())
    for explanation in explain_maximality_cf(fitresult, i)
        for (class, expl) in explanation
            !isnothing(expl) && push!(explanations[class], expl)
        end
    end
    explanations
end