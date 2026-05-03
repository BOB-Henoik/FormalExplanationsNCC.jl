using FormalExplanationsBase
const FEB = FormalExplanationsBase

using RobustClassifiersBase
const RCB = RobustClassifiersBase

using ResumableFunctions

function decode_pred(m::RCB.Maximality, (_, _, _, _, _, _, _, _, decode_y, _, _), d::String)
    occursin(" >< ",d) && return IncomparablePair(map(s -> findfirst(==(s), String.(decode_y.classes)), split(d, " >< "))...)
    occursin(" > ",d) && return DominancePair(map(s -> findfirst(==(s), String.(decode_y.classes)), split(d, " > "))...)
    @error "Could not decode the given string $d as a decision between two classes"
end

"""
    Retourne la valeur de la contribution de obs par rapport à opp pour y1 contre y2
"""
function compute_contrib(m::RCB.Maximality, (cond_prob, y_prob, _), obs::Vector{Int64}, opp::Vector{Int64}, y1::Int64, y2::Int64)::Vector{Float32}
	contrib::Vector{Float32} = zeros(Float32, length(obs))
	for i in range(1, length(obs))
		if obs[i] != opp[i]
			contrib[i] = log10(cond_prob[i][obs[i], y1, 1]) - log10(cond_prob[i][obs[i], y2, 2])
			contrib[i] -= log10(cond_prob[i][opp[i], y1, 1]) - log10(cond_prob[i][opp[i], y2, 2])
		end
	end
	return contrib
end

function compute_threshold(m::RCB.Maximality, (cond_prob, y_prob, _), x::Vector{Int64}, y1::Int64, y2::Int64)::Float32
	threshold::Float32 = 0.0
	for i in range(1, length(x))
		threshold += log10(cond_prob[i][x[i], y1, 1]) - log10(cond_prob[i][x[i], y2, 2])
	end
	threshold += log10(y_prob[y1,1]) - log10(y_prob[y2,2])
	threshold
end

function compute_opp(m::RCB.Maximality, (cond_prob, _, _, decode_x, _), x::Vector{Int64}, decision::IncomparablePair; reverse=false)::Vector{Int64}
	worst_opp::Vector{Int64} = zeros(Int64, length(x))
    y1 = if (!reverse) decision.class1 else decision.class2 end
    y2 = if (!reverse) decision.class2 else decision.class1 end
	for i in range(1, length(x))
		worst_opp[i] = argmax(c -> log10(cond_prob[i][c, y1, 1]) - log10(cond_prob[i][c, y2, 2]), range(1, length(decode_x[i].classes)))
	end
	return worst_opp
end

function compute_opp(m::RCB.Maximality, (cond_prob, _, _, decode_x, _), x::Vector{Int64}, decision::DominancePair; reverse=false)::Vector{Int64}
	worst_opp::Vector{Int64} = zeros(Int64, length(x))
    y1 = if (!reverse) decision.dominant else decision.dominate end
    y2 = if (!reverse) decision.dominate else decision.dominant end
	for i in range(1, length(x))
		worst_opp[i] = argmin(c -> log10(cond_prob[i][c, y1, 1]) - log10(cond_prob[i][c, y2, 2]), range(1, length(decode_x[i].classes)))
	end
	return worst_opp
end

@resumable function all_explanations_maximality(sample, threshold, sorted_contributions, sigma)
    xpl, flip, idx, cv = [], -ones(length(sample)), 0, threshold
	direction = sorted_contributions[1] > 0.0
    while idx >= 0
        xpl, cv, idx = smallest_explanation(RCB.Maximality(), sample, xpl, cv, sorted_contributions, sigma, flip, idx, direction)
        @yield xpl
        flip, xpl, cv, idx = enter_valid_state(RCB.Maximality(), sample, xpl, cv, sorted_contributions, sigma, flip, idx, direction)
    end
end

function smallest_explanation(m::RCB.Maximality, sample, xpl, cv, sorted_contributions, sigma, flip, idx, direction)
	while (direction && cv < 0.0) || (!direction && cv > 0.0)
		idx += 1
		flip[idx] = 0
		push!(xpl, (sigma[idx], sample[sigma[idx]]))
		cv += sorted_contributions[idx]
	end
    return (xpl, cv, idx)
end

function enter_valid_state(m::RCB.Maximality, sample, xpl, cv, sorted_contributions, sigma, flip, idx, direction)
	while (direction && (cv > 0.0 || sum(sorted_contributions[idx+1:end]) + cv < 0.0)) || (!direction && (cv < 0.0 || sum(sorted_contributions[idx+1:end]) + cv > 0.0))
		while (idx > 0) && (flip[idx] == 1)
			flip[idx] = -1
			idx -= 1
		end
	(idx <= 0) && return (flip, xpl, cv, -1)
	filter!(e->e≠(sigma[idx], sample[sigma[idx]]),xpl)
	cv -= sorted_contributions[idx]
    flip[idx] = 1
	end
    return (flip, xpl, cv, idx)
end