# After the inspectors leave: environmental enforcement and lasting change

[English](README.md) · [中文](README_ZH.md)

Environmental inspections put firms under close scrutiny. The harder policy question is what happens once that scrutiny eases: does cleaner air during an inspection last, or does part of it disappear when the inspectors leave?

Karplus and Wu (2023) study this with China's central environmental inspections. They find that SO₂ pollution near coal power plants falls during inspections and then partly rebounds. I reproduce four of their main models and then check how much the average effect depends on which places are included.

[Paper (PNAS)](https://pmc.ncbi.nlm.nih.gov/articles/PMC10151602/) · [Author data and code](https://doi.org/10.7910/DVN/AXWNCY)

## Key findings

**The reproduction matches.** For four columns of the paper's Table 3, my estimates, standard errors and sample sizes match the published table. Measures of model fit (R²) differ slightly.

**The drop during inspections is robust in direction, less so in size.** Leaving out one city at a time barely changes the results. Leaving out a whole province changes the estimated reduction considerably, but it stays a reduction in every case.

![Estimates after leaving out each province](results/province_deletions.png)

*Each dot is the estimate after excluding the province on the left; the blue line is the full sample.*

## Open questions

- **The period after inspectors leave is the least stable.** The estimate for weeks 6–10 after an inspection changes sign when some provinces are excluded, and with only eight provinces the evidence for a rebound is weak. This is the part of the paper's story that matters most for whether effects last, so I would read it with care.
- **The announcement period is also sensitive.** Without the authors' weights, leaving out Shanxi turns the estimated decrease into an increase.
- **The R² gap is unexplained.** I have not found which definition the paper uses.
- I have not reproduced the paper's analyses of plant ownership and government oversight, Table 3 columns 3 and 6, or the construction of the weekly data and sample weights.

<details>
<summary>Expand: published Table 3 and reproduced results</summary>

Values below come directly from the repository's [regression comparison](results/table3_comparison.csv) and are shown to three decimals. Parentheses contain standard errors. Coefficients are in log points, not percentages. Columns 1 and 4 are unweighted; columns 2 and 5 use the authors' supplied weights.

| Paper column | Period | Paper: estimate (SE) | This project: estimate (SE) |
|---|---|---:|---:|
| 1 | Announcement | -0.233 (0.073) | -0.233 (0.073) |
| 1 | During inspection | -0.524 (0.093) | -0.524 (0.093) |
| 1 | After inspection | -0.295 (0.100) | -0.295 (0.100) |
| 2 | Announcement | -0.191 (0.092) | -0.191 (0.092) |
| 2 | During inspection | -0.427 (0.107) | -0.427 (0.107) |
| 2 | After inspection | -0.229 (0.109) | -0.229 (0.109) |
| 4 | Announcement | -0.209 (0.074) | -0.209 (0.074) |
| 4 | During inspection | -0.503 (0.094) | -0.503 (0.094) |
| 4 | Weeks 1–5 after inspection | -0.409 (0.095) | -0.409 (0.095) |
| 4 | Weeks 6–10 after inspection | -0.158 (0.110) | -0.158 (0.110) |
| 5 | Announcement | -0.178 (0.093) | -0.178 (0.093) |
| 5 | During inspection | -0.417 (0.107) | -0.417 (0.107) |
| 5 | Weeks 1–5 after inspection | -0.313 (0.111) | -0.313 (0.111) |
| 5 | Weeks 6–10 after inspection | -0.135 (0.119) | -0.135 (0.119) |

All 14 effect estimates and standard errors match at the paper's reported precision. Sample sizes also match in all four models. R² differs as follows:

| Paper column | Paper observations | Project observations | Paper R² | Project R² |
|---|---:|---:|---:|---:|
| 1 | 42,309 | 42,309 | 0.766 | 0.769 |
| 2 | 31,582 | 31,582 | 0.739 | 0.741 |
| 4 | 42,309 | 42,309 | 0.768 | 0.772 |
| 5 | 31,582 | 31,582 | 0.741 | 0.743 |

R² describes model fit. The discrepancy remains unexplained, so this is not an exact match of every entry in the table. The [R² audit](results/r_squared_audit.csv) checks several common definitions; none matches the published values at three decimals. This reproduction covers Table 3 columns 1, 2, 4 and 5.

The supplied archive covers 1,308 plants; the unweighted estimation retains 1,281 after incomplete observations and singleton groups are removed. Observation counts in the table are plant–week observations.

[City and province checks](results/deletion_summary.csv) · [Post-inspection comparison](results/attenuation_contrast.csv) · [Full numerical discussion](docs/DETAILS.md)

</details>

## Run the project

R 4.6.0 and Python 3.10+. Package versions are pinned in `renv.lock`.

```sh
Rscript setup.R
python3 run.py
```

Data are downloaded to `data/raw/` (use `python3 run.py --offline` for an existing copy); results are written to `results/`. Author data are shared through Harvard Dataverse under CC0 and are not redistributed here.
