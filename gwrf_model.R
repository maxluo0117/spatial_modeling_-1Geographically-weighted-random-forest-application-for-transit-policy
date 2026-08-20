# ==============================================================================
# 1. Load Required Libraries
# ==============================================================================
library(SpatialML)   # For Geographically Weighted Random Forest (GWRF) modeling
library(openxlsx)    # For reading dataset from Excel files

# ==============================================================================
# 2. File Paths and Hyperparameters Setup
# ==============================================================================
# Define input dataset path and output destinations
input_file      <- "D:/Research_Data/spatial_dataset.xlsx"
output_text     <- "D:/Research_Data/GWRF_Local_Variable_Importance.txt"
output_model    <- "D:/Research_Data/GWRF_Final_Model.RData"

# Optimal hyperparameters identified from previous tuning / sensitivity analysis
optimal_bw    <- 100   # Optimal spatial bandwidth
optimal_mtry  <- 5     # Optimal number of split variables
ntree_val     <- 700   # Total trees per local forest

set.seed(666)          # Fixed seed for reproducibility

# ==============================================================================
# 3. Data Loading and Coordinate Extraction
# ==============================================================================
data_all <- read.xlsx(input_file)

# Extract spatial coordinates matrix (X: Longitude/Easting, Y: Latitude/Northing)
spatial_coords <- data_all[, c("coord_x", "coord_y")]

# ==============================================================================
# 4. Fit Final GWRF Model with Optimal Parameters
# ==============================================================================
gwrf_final <- grf(
  # Formula: Target Variable ~ Explanatory Variables
  target_y ~ 
    elevation + slope_degree + pop_density + dist_subcenter +
    transit_accessibility + eco_index + facility_diversity +
    land_agri + land_resi + land_indu + street_meshedness +
    dist_cbd + bus_lane_density + bus_stop_density + metro_station_density +
    road_density + housing_price + slope_pedestrian + land_comm,
  
  dframe  = data_all,       # Full dataset for full-area spatial fitting
  bw      = optimal_bw,     # Optimal adaptive bandwidth setting
  kernel  = "adaptive",     # Adaptive kernel (varies kernel radius to fix sample count)
  coords  = spatial_coords, # Spatial coordinate matrix
  ntree   = ntree_val,      # Number of decision trees
  mtry    = optimal_mtry,   # Number of variables sampled at each split
  forests = TRUE            # Store full local forests to enable spatial prediction and SHAP
)

# ==============================================================================
# 5. Inspect Model Diagnostic Outputs (Console Summaries)
# ==============================================================================
# Display spatial local variable importance matrix
gwrf_final$Local.Variable.Importance

# Display localized Random Forest model summaries
gwrf_final$LocalModelSummary

# Display local goodness-of-fit statistics (Local R2, residuals, etc.)
gwrf_final$LGofFit

# ==============================================================================
# 6. Export Model Results and Save Workspace Model File
# ==============================================================================
# Redirect console text output to a file for local feature importance logging
sink(output_text)
print(gwrf_final$Local.Variable.Importance, max = 10000000)
sink()

# Save the trained GWRF model object to an .RData file for downstream analysis
save(gwrf_final, file = output_model)

cat("\nFinal GWRF model training completed.")
cat("\nImportance results saved to:", output_text)
cat("\nModel object saved to:", output_model, "\n")