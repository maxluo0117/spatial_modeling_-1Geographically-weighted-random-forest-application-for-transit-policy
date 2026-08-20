# ==============================================================================
# 1. Load Required Libraries
# ==============================================================================
library(SpatialML)   # For spatial prediction using the trained GWRF model
library(openxlsx)    # For batch reading and writing Excel (.xlsx) files

# ==============================================================================
# 2. Directory and Input File Discovery
# ==============================================================================
# Path to the directory containing counterfactual scenario datasets
scenario_dir <- "D:/Research_Data/Simulation_Scenarios/"

# Batch retrieve all Excel scenario files matching the specified extension
scenario_files <- list.files(
  path       = scenario_dir, 
  pattern    = "\\.xlsx$", 
  full.names = TRUE
)

# ==============================================================================
# 3. Batch Counterfactual Prediction Loop
# ==============================================================================
for (file_path in scenario_files) {
  
  # Read current counterfactual scenario dataset
  data_scenario <- read.xlsx(file_path)
  
  # Extract spatial coordinates matrix (X: Longitude/Easting, Y: Latitude/Northing)
  scenario_coords <- data_scenario[, c("coord_x", "coord_y")] 
  
  # --------------------------------------------------------------------------
  # Spatial Prediction under Intervention Scenario
  # --------------------------------------------------------------------------
  # Predict target variable using the pre-trained GWRF model object (gwrf_final)
  # local.w = 1 and global.w = 0 applies 100% localized weighting for spatial accuracy
  target_pred <- predict.grf(
    gwrf_final, 
    data_scenario, 
    x.var.name = "coord_x", 
    y.var.name = "coord_y", 
    local.w    = 1, 
    global.w   = 0
  )
  
  # --------------------------------------------------------------------------
  # Result Compilation and File Export
  # --------------------------------------------------------------------------
  # Bind spatial unit identifier with counterfactual prediction outputs
  result_df <- data.frame(
    unit_id       = data_scenario$unit_id,
    predicted_co2 = target_pred
  )
  
  # Construct output file path with a standardized scenario suffix
  output_file <- gsub("\\.xlsx$", "_predicted_scenario.xlsx", file_path)
  
  # Export prediction results to an Excel file
  write.xlsx(result_df, output_file, overwrite = TRUE)
  
  # Output progress log to console
  cat("Scenario prediction completed and saved to:", output_file, "\n")
}