# Julia RF & Antenna Analysis

A Julia educational repository for **one-port RF S-parameter analysis** and basic antenna measurement workflows.

## Features
- Complex reflection coefficient and impedance conversion
- Return loss, VSWR, mismatch efficiency
- Resonance detection and sampled -10 dB contiguous bandwidth
- Basic Touchstone v1 `.s1p` parser (`RI`, `MA`, `DB`)
- Synthetic reflection-coefficient demo (not an EM antenna solver)
- Unit tests and GitHub Actions

## Run
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. examples/demo.jl
julia --project=. test/runtests.jl
```

## Research extension
Replace `examples/demo.s1p` with your **own** VNA-exported one-port file, verify the reference impedance and calibration plane, and compare with an HFSS-exported S11 file. S11 alone does not establish antenna gain, radiation efficiency, or axial ratio. The parser is deliberately limited to simple Touchstone v1 files.

## Status
Learning-oriented code; verify locally before claiming experimental results. MIT licensed.
