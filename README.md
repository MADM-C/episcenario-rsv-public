# Midwest EpiScenario: RSV Public Dashboard

An interactive R Shiny dashboard for exploring respiratory syncytial virus (RSV) scenario projections for Minnesota, developed by the [Midwest Analytics and Disease Modeling Center (MADMC)](https://www.sph.umn.edu/research/centers/midwest-analytics-and-disease-modeling/about/) at the University of Minnesota.

**Live app:** https://madmc.sph.umn.edu/midwest-episcenario/rsv

## Overview

Midwest EpiScenario: RSV estimates statewide and regional RSV hospital admissions, ICU admissions, and deaths under different immunization strategies and season severities. It is intended to support respiratory disease response planning by letting users compare "what if" scenarios, for example how much RSV burden would be averted if immunization uptake increased.

This is a **scenario planning** tool. It is not a real-time forecasting tool and cannot predict outcomes for a specific RSV season.

## Features

- **Outcomes:** RSV hospital admissions, ICU admissions, and deaths.
- **Display options:** total values, incremental differences from the status quo, or outcomes averted relative to the status quo.
- **Season severity:** *Typical* (based on the 2024-2025 RSV season) or *Severe* (an additional 20% increase in baseline transmission and age-specific probabilities of hospitalization).
- **Stratifications:** all ages combined or individual age groups (<1, 1-4, 5-17, 18-49, 50-74, 75+), and statewide or by one of seven IDEPC regions (Central, Metropolitan, Northeast, Northwest, Southeast, Southwest, West Central).
- **Strategy comparison:** up to 11 strategies at once, with optional 50% uncertainty intervals.
- **Three result views:** Season Totals (bar plot), Cumulative, and Incidence (time series).
- **Downloads:** each view offers a PNG figure and a CSV of the underlying data.

## Immunization strategies

| Strategy | Description |
|----------|-------------|
| Status Quo | Same uptake as the 2024-2025 season: 35% monoclonal antibody, 23% maternal vaccine, 3% older adult vaccine (ages 50-74), 15% older adult vaccine (ages 75+) |
| No Immunizations | No immunization uptake in the current season (regular uptake assumed in prior seasons) |
| Maternal Vaccination +10% / +20% / +30% | Increases maternal vaccine uptake to 33%, 43%, 53% |
| Monoclonal Antibodies +10% / +20% / +30% | Increases monoclonal antibody uptake to 45%, 55%, 65% |
| Older Adult Vaccination +5% / +15% / +25% | Increases older adult vaccine uptake |

Status Quo is the primary comparator.

## Model

The dashboard displays results from a compartmental Susceptible-Exposed-Infected-Recovered (SEIR) model, with additional states for hospitalization, ICU stay, and death. The model is modular, with six modules: demography, transmission, disease progression, healthcare, post-infection, and immunity. Population stratifications are age group, IDEPC region, and immunization status (no immunization, vaccinated, monoclonal antibodies, maternal antibodies).

**Key assumptions**

- Contact patterns that spread RSV vary by age and are estimated from the MADMC Social Contact Survey; between-region mixing was estimated through model calibration.
- Regions differ in demographics and immunization uptake, but not in risk of hospitalization or death.
- Hospital and ICU admission risk depend only on age group and immunization status.
- Deaths occur only among cases requiring hospital care, with higher risk for ICU care and with increasing age.
- Immunization reduces infection risk and hospitalization risk, but does not affect length of stay or probability of death once hospitalized.
- Immunity from both immunization and infection wanes over time.
- Timing of immunization uptake follows historical patterns.

**Limitations**

The model follows the population rather than individuals, and only age and region affect outcomes. It does not model outpatient visits, asymptomatic vs. symptomatic cases, RSV A vs. B strains, contact-reducing interventions (e.g., masking), setting-specific scenarios, or sociodemographic factors other than age and region. It is calibrated to hospital admissions (including ICU), not total case burden, because RSV is substantially undertested outside the hospital setting.

More detail is available on the dashboard's **Technical Details** and **FAQs** tabs.

## Data

| Data | How it is Used | Availability |
|---------|----------|-------|
| Model output files (`data/*.fst`) | Summary of results to produce dashboard figures | Included in this repository |
| MADMC Social Contact Survey | Used in model development | Potentially available upon request |
| Minnesota Electronic Health Record Consortium (MNEHRC) | Used in model development | **not publicly available** |
| MDH Minnesota Immunization Information Connection | Used in model development | **not publicly available** |
| Published literature | Used for additional model parameters | Can share sources upon request |

The repository contains only the precomputed scenario results used by the dashboard, not the model code or the restricted input data.

## Repository structure

```
.
├── app.R                          # Shiny UI and server
├── styles.R                       # App styling (sourced by app.R)
├── data/                          # Precomputed results (.fst)
├── www/                           # Static assets (logos, model diagram)
├── episcenario-rsv-public.Rproj   # RStudio project file
├── LICENSE
└── README.md
```

The `data/` folder holds 16 result files named `dashboard_results_{nostrat|age|reg|all}_{inc|cum}[_diff].fst`:

- `inc` / `cum`: incidence or cumulative results
- `nostrat`, `age`, `reg`, `all`: no stratification, by age group, by region, or by age and region
- `_diff`: differences relative to the status quo

## Funding

This work was supported by cooperative agreement CDC-RFA-FT-23-0069 from the Center for Forecasting and Outbreak Analytics of the U.S. Centers for Disease Control and Prevention (CDC). Its contents are solely the responsibility of the authors and do not necessarily represent the official views of the CDC.

## Contact

Questions or feedback: [madmc@umn.edu](mailto:madmc@umn.edu)

## License

Released under the [MIT License](LICENSE).
