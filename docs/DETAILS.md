# Detailed results

Numbers behind the summary in the [README](../README.md). All models include plant and year–week fixed effects, with standard errors clustered by city. Coefficients are in log points.

## Reproduction of Table 3

| Table 3 column | Model | Effects / standard errors matched | Observations | R²: reproduction / paper |
|---|---|---|---:|---:|
| 1 | Unweighted; three periods | 3 / 3 | 42,309 | 0.769 / 0.766 |
| 2 | Author weights; three periods | 3 / 3 | 31,582 | 0.741 / 0.739 |
| 4 | Unweighted; two post-inspection periods | 4 / 4 | 42,309 | 0.772 / 0.768 |
| 5 | Author weights; two post-inspection periods | 4 / 4 | 31,582 | 0.743 / 0.741 |

The unweighted estimation sample contains 1,281 plants after incomplete observations and singleton groups are removed; the archive covers 1,308 plants. Every model is cross-checked against an independent QR solution and `fixest`. The R² audit compares overall, adjusted and within R²; none matches the published value at three decimals.

[Regression comparison](../results/table3_comparison.csv) · [R² audit](../results/r_squared_audit.csv)

## Leaving out cities and provinces

Every exclusion refits the plant and year–week fixed effects; the authors' weights are held fixed.

| Inspection-period coefficient (three-period model) | Full sample | Excluding each city | Excluding each province |
|---|---:|---:|---:|
| Unweighted (column 1) | −0.524 | −0.554 to −0.484 | −0.831 to −0.198 |
| Author weights (column 2) | −0.427 | −0.463 to −0.354 | −0.718 to −0.195 |

Sign changes across province exclusions:

- Announcement period: excluding Shanxi turns the unweighted estimate positive (columns 1 and 4); weighted estimates stay negative.
- Weeks 6–10 after inspection: the unweighted estimate (column 4) changes sign in two province exclusions; the weighted estimate (column 5) changes sign when Shanxi is excluded.

[City and province checks](../results/deletion_summary.csv)

## Rebound after inspection

The difference between weeks 6–10 after inspection and the inspection period is +0.345 without weights and +0.282 with weights. With province-level centered jackknife (CV3J) standard errors and t(7) critical values, the 95% interval is 0.004 to 0.686 without weights (barely excluding zero) and −0.068 to 0.632 with weights. Eight-cluster inference is fragile.

[Post-inspection comparison](../results/attenuation_contrast.csv)
