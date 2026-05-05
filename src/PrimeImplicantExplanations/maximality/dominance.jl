@resumable function explain_maximality_pi(fitresult, d::DominancePair)
    (x, _, dominance_oppponents, dominance_thresholds, dominance_contrib, _, _, _, _, decode_x, names_x) = fitresult
	@assert haskey(dominance_thresholds, d)

	for explanation in all_explanations_maximality(x, dominance_thresholds[d], sort(dominance_contrib[d], rev=true), sortperm(dominance_contrib[d], rev=true))
        @yield join(("($(names_x[feature]), $(decode_x[feature].classes[value]))" for (feature, value) in explanation), ", ")
    end
end

function explain_all_pi(m::Maximality, fitresult, d::DominancePair)
    explanations = Vector{String}()
    for explanation in explain_maximality_pi(fitresult, d)
        push!(explanations, explanation)
    end
    explanations
end