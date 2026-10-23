using Test, RFAntennaAnalysis
@testset "RF analysis" begin
    @test gamma_from_impedance(50+0im)≈0+0im
    @test impedance_from_gamma(0.2+0im)≈75+0im
    @test return_loss_db(0.1)≈20
    @test vswr(0.0)≈1
    @test mismatch_efficiency(0.1)≈0.99
    @test isinf(vswr(1.0))
    f,g=synthetic_s11()
    r=analyze_s11(f,g)
    @test abs(r.resonance_hz-2.4e9)<2e6
    @test r.threshold_met
    touch=read_touchstone_s1p(joinpath(@__DIR__,"..","examples","demo.s1p"))
    @test touch.z0==50
    @test length(touch.s11)==3
    @test touch.frequency_hz[2]≈2.4e9
    @test_throws ArgumentError analyze_s11([2.0,1.0],[0.1,0.2])
end
