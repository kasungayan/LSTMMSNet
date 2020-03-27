library(forecast)
set.seed(1234)

df_train <- read.csv("solar_train.txt", header = FALSE)

OUTPUT_DIR = "Mean_Moving_window"
input_size = 24*1.25
max_forecast_horizon <- 24
seasonality_period_1 <- 24
seasonality_period_2 <- 168
seasonality_period_3 <- 8766

start_time <- Sys.time()


for (idr in 1 : nrow(df_train)) {
  print(idr)
  OUTPUT_PATH = paste(OUTPUT_DIR, "energy_baseline_test", sep = '/')
  OUTPUT_PATH = paste(OUTPUT_PATH, max_forecast_horizon, sep = '')
  OUTPUT_PATH = paste(OUTPUT_PATH, 'i', input_size, sep = '')
  OUTPUT_PATH = paste(OUTPUT_PATH, 'txt', sep = '.')
  
  time_series_data <- as.numeric(df_train[idr,])
  time_series_mean <- mean(time_series_data)
  
  time_series_data <- time_series_data/(time_series_mean)
  
  time_series_log <- log(time_series_data + 1)
  time_series_length = length(time_series_log)
  
  input_windows = embed(time_series_log[1 : (time_series_length)], input_size)[, input_size : 1]
  
  meanvalues <- rowMeans(input_windows)
  input_windows <- input_windows - meanvalues
  
  sav_df = matrix(NA, ncol = (4 + input_size), nrow = nrow(input_windows))
  sav_df = as.data.frame(sav_df)
  sav_df[, 1] = paste(idr - 1, '|i', sep = '')
  sav_df[, 2 : (input_size + 1)] = input_windows
  sav_df[, (input_size + 2)] = '|#'
  sav_df[, (input_size + 3)] = time_series_mean
  sav_df[, (input_size + 4)] = meanvalues
  
  write.table(sav_df, file = OUTPUT_PATH, row.names = F, col.names = F, sep = " ", quote = F, append = TRUE)
}

end_time <- Sys.time()

print(paste0("Total time", (end_time - start_time)))
