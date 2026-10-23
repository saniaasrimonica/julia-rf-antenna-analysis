using RFAntennaAnalysis
f,g=synthetic_s11()
result=analyze_s11(f,g)
println("Synthetic antenna response (not measured data):")
println(result)
println("Impedance at 50 ohm match: ",impedance_from_gamma(0.0+0im))
