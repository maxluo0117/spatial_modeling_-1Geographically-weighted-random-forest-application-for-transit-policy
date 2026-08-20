# Spatial Machine Learning for Transit Policy Simulation: A GWRF Framework

This project grew out of my Master's research on urban transport and carbon emissions.
One issue I kept running into was **spatial heterogeneity**. Urban observations come with locations, and nearby areas are often more similar than distant ones. More importantly, the same transport intervention may work differently across different parts of a city. That made a single city-wide relationship feel too restrictive for the policy simulations I wanted to run.
I therefore experimented with **Geographically Weighted Random Forest (GWRF)**, combining the flexibility of Random Forest with geographically weighted local models. The idea is fairly simple: instead of assuming one relationship for the entire study area, allow the model to learn relationships that vary across space.
Based on **Wu et al. (2024)** and the spatial modeling techniques discussed in **Thierry (2025)**, I organized the implementation into the three-step workflow below.

**References**
* **Wu, D., Zhang, Y., & Xiang, Q.** (2024). Could improving public transport accessibility reduce road traffic carbon dioxide emissions? A simulation-based counterfactual analysis. *Journal of Transport Geography*, 119, 103970. [https://doi.org/10.1016/j.jtrangeo.2024.103970](https://doi.org/10.1016/j.jtrangeo.2024.103970)
* **Warin, T.** (2025). *Geospatial Data Science with R: An Introduction*. HEC Montréal and Digital, Data and Design (D^3) Institute at Harvard Business School. [https://warin.ca/geospatial/](https://warin.ca/geospatial/)

---

## Workflow

### 1. Hyperparameter Tuning (`gwrf_sensitive_analysis.R`)
I first split the spatial dataset into 80% training and 20% validation data. I then tested different combinations of spatial bandwidth (`bw`) and `mtry` and compared their validation performance using $R^2$, $RMSE$, and $MAE$.

> **Goal:** Find a reasonable parameter combination before fitting the final model.

### 2. GWRF Model Training (`gwrf_model.R`)
With the selected parameters, I retrained the GWRF model using the full dataset (`ntree = 700`).

At this stage, I also extracted local variable importance and local $R^2$. These are useful because they show how both model performance and the importance of individual variables change across space. 

The fitted model is saved as an `.RData` file and reused in the simulation step rather than being retrained for every scenario.

### 3. Policy Intervention Simulation (`intervention_simulation.R`)
Finally, I modify selected transport or built-environment variables to represent different intervention scenarios and feed these scenario datasets into the trained model.

For prediction, I use pure local weighting (`local.w = 1`). The predicted values are then matched back to each spatial unit (`unit_id`), which makes it possible to map and compare the estimated outcomes across scenarios.
<img width="1774" height="887" alt="flow" src="https://github.com/user-attachments/assets/e30e1254-7ee0-4400-b9d0-8fc257ee331b" />

---

## What I Learned

The most interesting part of this project was not simply getting a better predictive model. It was seeing how strongly the estimated relationships can change depending on where and at what spatial scale the analysis is conducted. Two issues became particularly important:

### Variable Selection & Causality
GWRF can capture fairly complex local relationships, but that does not automatically make the resulting policy effects causal. 

This matters when choosing intervention variables. Spatially correlated or highly collinear predictors can affect local feature importance and, in turn, how a simulated intervention should be interpreted. For this reason, I treat the simulation results as **model-based counterfactual predictions**, rather than causal treatment effects.

### Spatial Scale & MAUP
I used a **1 km × 1 km grid** as the basic spatial unit in my empirical analysis. This choice turned out to matter more than I initially expected:

* **Smoothing Effect:** Aggregating variables to 1 km cells smooths some street-level variation. Bus-stop accessibility, pedestrian environments, and other built-environment characteristics can look quite different depending on the spatial resolution.
* **Artificial Divisions:** Grid boundaries also impose artificial divisions on processes that do not actually stop at those boundaries.

*For that reason, one extension I would like to explore is repeating the analysis at several spatial resolutions and comparing how the selected bandwidths, local relationships, and simulated policy effects change.*

---

## Possible Extensions

Although I developed the workflow around public transport and carbon emissions, the same setup could be tested for other spatial intervention problems, for example:

* **Urban Greening & Heat Mitigation:** Simulating localized microclimate cooling effects.
* **Charging-Station or Public-Facility Placement:** Optimizing infrastructure deployment based on local demand.
* **Land-Use & Zoning Scenarios:** Evaluating environmental or socio-economic trade-offs.
* **Accessibility Interventions:** Assessing micro-mobility and street-level pedestrian enhancements.

> **General Framework:**  
> Modify Selected Spatial Variables $\rightarrow$ Predict Locally $\rightarrow$ Compare Spatial Distribution of Outcomes
