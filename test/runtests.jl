using FormalExplanationsNCC
using NaiveCredalClassifier
using FormalExplanationsBase
using MLJBase
using Test
using CSV
using DataFrames

T = CSV.read("./test/animal_dataset.csv", DataFrame)
T = coerce(T, :hair => Multiclass, :tail => Multiclass, :ear => Multiclass, :animal => Multiclass)
y, X = unpack(T, ==(:animal))

Xnew = DataFrame(ear=["Long"], tail=["Short"], hair=["Long"])
Xnew = coerce(Xnew, :hair => Multiclass, :tail => Multiclass, :ear => Multiclass)
levels!(Xnew.ear, ["Long", "Medium", "Short"])
levels!(Xnew.hair, ["Long", "Medium", "Short"])
levels!(Xnew.tail, ["Long", "Medium", "Short"])
#Xnew =  Xnew[1,:]

ncc = NaiveCredalClassifier.NCClassifier()
mach = machine(ncc, X, y)
MLJBase.fit!(mach)
MLJBase.predict(mach, Xnew)
pi_explainer = PrimeImplicantExplainer(ncc)
e = explainer(pi_explainer, mach, Xnew[1,:])
FormalExplanationsBase.fit!(e)
println(FormalExplanationsBase.fitted_params(e))
for p in fitted_decisions(e).incomparable_pairs
    println("$p : $(FormalExplanationsBase.explain_all(e,p))")
end
for p in fitted_decisions(e).dominance_pairs
    println("$p : $(FormalExplanationsBase.explain_all(e,p))")
end

cf_explainer = CounterfactualExplainer(ncc)
e2 = explainer(cf_explainer, mach, Xnew[1,:])
FormalExplanationsBase.fit!(e2)
println(FormalExplanationsBase.fitted_params(e2))
for p in fitted_decisions(e2).incomparable_pairs
    class1, class2 = split(p, " >< ")
    explanations = FormalExplanationsBase.explain_all(e2,p)
    println("$p  -> $class1 : $(explanations[class1]) \n $(' ' ^ textwidth(p)) -> $class2 : $(explanations[class2])")
end
for p in fitted_decisions(e2).dominance_pairs
    println("$p : $(FormalExplanationsBase.explain_all(e2,p))")
end