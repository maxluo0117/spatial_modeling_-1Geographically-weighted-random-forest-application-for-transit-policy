# ==============================================================================
# 1. Load Required Libraries
# ==============================================================================
library(SpatialML)   # For Geographically Weighted Random Forest (GWRF) modeling
library(openxlsx)    # For reading and writing Excel (.xlsx) files
library(dplyr)       # For data manipulation and transformation

# ==============================================================================
# 2. Hyperparameters and File Paths Setup
# ==============================================================================
# Define input dataset path and output file destination
input_file  <- "D:/Research_Data/spatial_dataset.xlsx"
output_file <- "D:/Research_Data/GWRF_Sensitivity_Results.xlsx"

# Hyperparameter lists for model tuning and sensitivity analysis
mtry_list   <- c(10)            # Number of variables randomly sampled at each split
bw_list     <- c(120)           # Spatial kernel bandwidth (number of nearest neighbors or distance)
localw_list <- c(0, 1)          # Local weight parameter (0: global weighting, 1: local weighting)
ntree       <- 700              # Number of trees to grow in the random forest

set.seed(666)                   # Set seed for random number generation to ensure reproducibility

# ==============================================================================
# 3. Data Loading and Train/Validation Split
# ==============================================================================
data_all <- read.xlsx(input_file)  # Load the dataset

n <- nrow(data_all)
# Randomly sample 80% of rows for training and reserve 20% for validation
train_idx <- sample(
  1:n,
  size = floor(0.8 * n),
  replace = FALSE
)

TrainSet <- data_all[train_idx, ]   # Training dataset: used for model fitting
ValidSet <- data_all[-train_idx, ]  # Validation dataset: used for evaluating model generalization

# Initialize an empty data frame to store evaluation metrics across configurations
all_results <- data.frame()

# ==============================================================================
# 4. Sensitivity Analysis & Model Training Loop
# ==============================================================================
for(bw in bw_list) {
  for(mtry in mtry_list) {
    
    # Print current hyperparameter combination progress
    cat("\nRunning GWRF -> Bandwidth (bw):", bw, "| mtry:", mtry, "\n")
    
    # Extract spatial coordinates for training set (X: Longitude/Easting, Y: Latitude/Northing)
    Train_Coords <- TrainSet[, c("coord_x", "coord_y")]
    
    # --------------------------------------------------------------------------
    # Fit Geographically Weighted Random Forest (GWRF)
    # --------------------------------------------------------------------------
    grf_model <- grf(
      # Target Variable ~ Explanatory Variables
      target_y ~ 
        pop_density + facility_diversity +
        land_agri + land_comm + land_resi + land_indu +
        dist_cbd + dist_subcenter +
        bus_stop_density + metro_station_density +
        road_density +
        road_len_highway + road_len_arterial + road_len_collector + road_len_local +
        eco_index + gdp_per_cap +
        age_0_14 + age_15_59 + age_60_plus +
        parking_public + parking_dedicated + parking_onstreet +
        elevation + slope_degree + slope_pedestrian,
      
      dframe  = TrainSet,      # Training data frame
      bw      = bw,            # Spatial kernel bandwidth
      kernel  = "adaptive",    # Adaptive bandwidth (fixed number of nearest neighbors)
      coords  = Train_Coords,  # Spatial coordinate matrix
      ntree   = ntree,         # Number of decision trees
      mtry    = mtry,          # Number of features randomly sampled at split
      forests = TRUE           # Save local forest models for spatial prediction
    )
    
    # --------------------------------------------------------------------------
    # Prediction and Validation Evaluation
    # --------------------------------------------------------------------------
    for(local_w in localw_list) {
      
      # Predict on validation set using specified local/global weighting
      pred <- predict.grf(
        grf_model,
        ValidSet,
        x.var.name = "coord_x",
        y.var.name = "coord_y",
        local.w    = local_w,
        global.w   = 1 - local_w
      )
      
      observed  <- as.numeric(ValidSet$target_y)
      predicted <- as.numeric(pred)
      
      # Data cleaning: filter out missing (NA) or non-finite values
      valid_idx <- which(
        !is.na(observed) & 
          !is.na(predicted) & 
          is.finite(observed) & 
          is.finite(predicted)
      )
      
      # Skip iteration if fewer than 5 valid data points exist
      if(length(valid_idx) < 5) next
      
      observed  <- observed[valid_idx]
      predicted <- predicted[valid_idx]
      
      # ------------------------------------------------------------------------
      # Calculate Predictive Accuracy Metrics
      # ------------------------------------------------------------------------
      R2    <- cor(observed, predicted)^2           # Coefficient of determination (R-squared)
      MSE   <- mean((observed - predicted)^2)        # Mean Squared Error
      MAE   <- mean(abs(observed - predicted))       # Mean Absolute Error
      RMSE  <- sqrt(MSE)                             # Root Mean Squared Error
      rRMSE <- (RMSE / mean(observed)) * 100         # Relative RMSE (%)
      
      # Store metrics for current parameter configuration
      metrics_df <- data.frame(
        bw        = bw,
        mtry      = mtry,
        local_w   = local_w,
        Train_n   = nrow(TrainSet),
        Valid_n   = nrow(ValidSet),
        R2        = R2,
        MSE       = MSE,
        MAE       = MAE,
        RMSE      = RMSE,
        rRMSE     = rRMSE
      )
      
      # Append row to results summary
      all_results <- rbind(all_results, metrics_df)
    }
  }
}

# ==============================================================================
# 5. Export Results to Excel
# ==============================================================================
wb <- createWorkbook()
addWorksheet(wb, "Evaluation_Metrics")
writeData(wb, "Evaluation_Metrics", all_results)

saveWorkbook(wb, output_file, overwrite = TRUE)

cat("\nModel evaluation completed. Results saved to:\n", output_file, "\n")