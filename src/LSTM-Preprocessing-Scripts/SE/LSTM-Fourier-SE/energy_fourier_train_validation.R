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

for (validation in c(TRUE, FALSE)) {
  for (idr in 1 : nrow(df_train)) {
    print(idr)
    OUTPUT_PATH = paste(OUTPUT_DIR, "energy_fourier", sep = '/')
    
    OUTPUT_PATH = paste(OUTPUT_PATH, max_forecast_horizon, sep = '')
    OUTPUT_PATH = paste(OUTPUT_PATH, 'i', input_size, sep = '')
    if (validation) {
      OUTPUT_PATH = paste(OUTPUT_PATH, 'v', sep = '')
    }
    OUTPUT_PATH = paste(OUTPUT_PATH, 'txt', sep = '.')
    
    time_series_data <- as.numeric(df_train[idr,])
    time_series_mean <- mean(time_series_data)
    
    time_series_data <- time_series_data/(time_series_mean)
    
    time_series_log <- log(time_series_data + 1)
    time_series_length = length(time_series_log)
    
    if (! validation) {
      time_series_length = time_series_length - max_forecast_horizon
      time_series_log = time_series_log[1 : time_series_length]
    }
    
    regessor1 <- fourier(msts(time_series_log, seasonal.periods = c(seasonality_period_1)), K = c(10)) 
    regessor2 <- fourier(msts(time_series_log, seasonal.periods = c(seasonality_period_2)), K = c(20)) 
    regessor3 <- fourier(msts(time_series_log, seasonal.periods = c(seasonality_period_3)), K = c(20)) 
    seasonality1 <- rowSums(regessor1)
    seasonality2 <- rowSums(regessor2)
    seasonality3 <- rowSums(regessor3)
    
    input_windows = embed(time_series_log[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    output_windows = embed(time_series_log[-(1:input_size)], max_forecast_horizon)[, max_forecast_horizon : 1]
    seasonality1_windows = embed(seasonality1[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    seasonality2_windows = embed(seasonality2[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    seasonality3_windows = embed(seasonality3[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    
    seasonality1_windows =  seasonality1_windows[, c(30)]
    seasonality2_windows =  seasonality2_windows[, c(30)]
    seasonality3_windows =  seasonality3_windows[, c(30)]
    
    meanvalues <- rowMeans(input_windows)
    input_windows <- input_windows - meanvalues
    output_windows <- output_windows -meanvalues
    
    if (validation) {
      sav_df = matrix(NA, ncol = (5 + input_size + 3 + max_forecast_horizon), nrow = nrow(input_windows ))
      sav_df = as.data.frame(sav_df)
      sav_df[, 1] = paste(idr - 1, '|i', sep = '')
      sav_df[, 2] = seasonality1_windows
      sav_df[, 3] = seasonality2_windows
      sav_df[, 4] = seasonality3_windows
      sav_df[, 5 : (input_size + 3 + 1)] = input_windows
      sav_df[, (input_size + 3 + 2)] = '|o'
      sav_df[, (input_size + 3 + 3):(input_size + 3 + max_forecast_horizon  +2)] = output_windows
      sav_df[, (input_size + 3 + max_forecast_horizon  + 3)] = '|#'
      sav_df[, (input_size + 3 + max_forecast_horizon + 4)] = time_series_mean
      sav_df[, (input_size + 3 + max_forecast_horizon + 5)] = meanvalues
    }else {
      sav_df = matrix(NA, ncol = (2 + input_size + 3 + max_forecast_horizon), nrow = nrow(input_windows))
      sav_df = as.data.frame(sav_df) 
      sav_df[, 1] = paste(idr - 1, '|i', sep = '')
      sav_df[, 2] = seasonality1_windows
      sav_df[, 3] = seasonality2_windows
      sav_df[, 4] = seasonality3_windows
      sav_df[, 5 : (input_size + 3 + 1)] = input_windows
      sav_df[, (input_size + 3 + 2)] = '|o'
      sav_df[, (input_size + 3 + 3):(input_size + 3 + max_forecast_horizon  +2)] = output_windows
    }
    
    write.table(sav_df, file = OUTPUT_PATH, row.names = F, col.names = F, sep = " ", quote = F, append = TRUE)
  }
}

end_time <- Sys.time()

print(paste0("Total time", (end_time - start_time)))