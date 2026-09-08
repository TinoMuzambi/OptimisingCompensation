# Optimising compensation

An agent-based NetLogo experiment exploring how job-changing behaviour,
negotiation, inflation, salary increases, and labour-market capacity interact
over time. R is used to aggregate BehaviourSpace runs and compare average
salaries for employees who tend to change jobs with those who tend to stay.

## Repository map

- `Optimising Compensation.nlogo` — the interactive agent-based model
- `Optimising Compensation Analysis.Rmd` — analysis and faceted experiment plots
- `data/` — committed BehaviourSpace outputs used by the analysis
- `Optimising Compensation.drawio` — model/process diagram source

## Run the experiment

1. Open the model in NetLogo 6.3 or newer.
2. Use the interface for an interactive run, or use the embedded BehaviourSpace
   experiments for repeated parameter sweeps.
3. Export results into `data/` using the existing two-digit parameter prefixes.
4. Render `Optimising Compensation Analysis.Rmd` with R, `rmarkdown`, and
   `tidyverse`.

The checked-in outputs make the analysis inspectable without rerunning every
simulation. They are generated model results, not personal or production data.

## Correctness notes

The maintained model samples application outcomes independently per employee,
uses NetLogo's `nobody` value for unemployed agents, clamps initial salaries at
zero, and advances tenure once per tick. The analysis extracts experiment
parameters from file basenames rather than fragile full-path character offsets.

This is an exploratory model, not compensation or employment advice. Code,
model, and generated experiment data are MIT licensed.
