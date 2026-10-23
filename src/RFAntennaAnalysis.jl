module RFAntennaAnalysis
export gamma_from_impedance, impedance_from_gamma, return_loss_db, vswr, mismatch_efficiency, analyze_s11, read_touchstone_s1p, synthetic_s11

function gamma_from_impedance(z::Number; z0::Real=50.0)
    z0 > 0 || throw(ArgumentError("z0 must be positive"))
    return (z-z0)/(z+z0)
end
function impedance_from_gamma(g::Number; z0::Real=50.0)
    z0 > 0 || throw(ArgumentError("z0 must be positive"))
    abs(1-g) > 1e-14 || throw(DomainError(g,"reflection coefficient too close to 1"))
    return z0*(1+g)/(1-g)
end
function return_loss_db(g::Number)
    a=abs(g)
    a <= 1+1e-10 || throw(DomainError(a,"passive one-port |S11| should be <= 1"))
    return a==0 ? Inf : -20*log10(a)
end
function vswr(g::Number)
    a=abs(g)
    a <= 1+1e-10 || throw(DomainError(a,"passive one-port |S11| should be <= 1"))
    return a >= 1 ? Inf : (1+a)/(1-a)
end
mismatch_efficiency(g::Number) = 1-abs2(g)
function analyze_s11(freq_hz::AbstractVector, gamma::AbstractVector; threshold_db=-10.0)
    length(freq_hz)==length(gamma) && !isempty(freq_hz) || throw(ArgumentError("equal nonempty vectors required"))
    all(diff(freq_hz).>0) || throw(ArgumentError("frequencies must increase"))
    all(abs.(gamma).<=1+1e-10) || throw(ArgumentError("passive S11 magnitude exceeds one"))
    db=20 .* log10.(abs.(gamma))
    i=argmin(db)
    pass=db .<= threshold_db
    # Bandwidth here is sampled contiguous interval containing the resonance.
    lo=i; hi=i
    if pass[i]
        while lo>1 && pass[lo-1];lo-=1;end
        while hi<length(pass) && pass[hi+1];hi+=1;end
    end
    return (resonance_hz=freq_hz[i], minimum_s11_db=db[i],
            bandwidth_hz=pass[i] ? freq_hz[hi]-freq_hz[lo] : 0.0,
            threshold_met=pass[i], vswr_at_resonance=vswr(gamma[i]),
            mismatch_efficiency_at_resonance=mismatch_efficiency(gamma[i]))
end
# Minimal Touchstone v1 .s1p parser. Supports # Hz/kHz/MHz/GHz S RI/MA/DB R z0.
# Expects one-port data, no v2 sections, and exactly one record per line.
function read_touchstone_s1p(path::AbstractString)
    unit=1.0; fmt="MA"; z0=50.0
    freqs=Float64[]; gamma=ComplexF64[]
    for raw in eachline(path)
        line=strip(first(split(raw,'!';limit=2)))
        isempty(line) && continue
        if startswith(line,"#")
            tokens=uppercase.(split(strip(line[2:end])))
            length(tokens)>=3 || throw(ArgumentError("invalid Touchstone option line"))
            unit=get(Dict("HZ"=>1.0,"KHZ"=>1e3,"MHZ"=>1e6,"GHZ"=>1e9),tokens[1],NaN)
            isfinite(unit) || throw(ArgumentError("unsupported frequency unit"))
            tokens[2]=="S" || throw(ArgumentError("only S parameters supported"))
            fmt=tokens[3];fmt in ("RI","MA","DB") || throw(ArgumentError("unsupported data format"))
            idx=findfirst(==("R"),tokens)
            if idx!==nothing
                idx<length(tokens) || throw(ArgumentError("missing reference impedance"))
                z0=parse(Float64,tokens[idx+1])
            end
            continue
        end
        startswith(line,"[") && throw(ArgumentError("Touchstone v2 not supported"))
        vals=parse.(Float64,split(line))
        length(vals)==3 || throw(ArgumentError("expected frequency and two S11 fields"))
        f,a,b=vals
        g=fmt=="RI" ? complex(a,b) : (fmt=="MA" ? a : 10^(a/20))*cis(deg2rad(b))
        push!(freqs,f*unit);push!(gamma,g)
    end
    isempty(freqs) && throw(ArgumentError("no S11 records found"))
    return (frequency_hz=freqs,s11=gamma,z0=z0)
end
function synthetic_s11(; fstart=1.8e9, fstop=2.7e9, n=901, f0=2.4e9, q=8.0, min_gamma=0.12)
    f=collect(range(fstart,fstop;length=n))
    # Toy reflection model for software demos, NOT a full-wave antenna model.
    x=q .* (f./f0 .- f0./f)
    g=ComplexF64.((min_gamma .+ im.*x)./(1 .+ im.*x))
    return f,g
end
end
