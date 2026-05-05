@resumable function explain_maximality_pi(fitresult, i::IncomparablePair)
    (x, _, _, _, _, _, incomparability_thresholds, incomparability_contrib, _, decode_x, names_x) = fitresult
	@assert haskey(incomparability_thresholds, i)
	ex_model = Model(HiGHS.Optimizer)
	set_attribute(ex_model, "output_flag", false)

	partial = @variable(ex_model, [1:length(x)], Bin)
	@constraint(ex_model, sum(partial[j] * incomparability_contrib[i][1][j] for j in range(1,length(x))) + incomparability_thresholds[i][1] <= 0)
	@constraint(ex_model, sum(partial[j] * incomparability_contrib[i][2][j] for j in range(1,length(x))) + incomparability_thresholds[i][2] <= 0)
	@objective(ex_model, Min, sum(partial))

	optimize!(ex_model)
	while termination_status(ex_model) == JuMP.OPTIMAL
		@yield join(("($(names_x[j]), $(decode_x[j].classes[x[j]]))" for j in findall(v -> v > 0.5, value.(partial))), ", ")
		@constraint(ex_model, sum(partial[j] for j in findall(v -> v > 0.5, value.(partial))) <= sum(value.(partial)) - 1)
		optimize!(ex_model)
	end
end

function explain_all_pi(m::Maximality, fitresult, i::IncomparablePair)
    explanations = Vector{String}()
    for explanation in explain_maximality_pi(fitresult, i)
        push!(explanations, explanation)
    end
    explanations
end