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
    OUTPUT_PATH = paste(OUTPUT_DIR, "energy_fourierk1", sep = '/')
    
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
    
    n <- time_series_length
    freq1 <- 24
    freq2 <- 168
    freq3 <- 8766
    
    xs_1 <- seq(0, 2*pi, length=freq1+1)
    xs_2 <- seq(0, 2*pi, length=freq2+1)
    xs_3 <- seq(0, 2*pi, length=freq3+1)
    
    xsrep_1 <- rep(xs_1[-length(xs_1)], length=n)
    xsrep_2 <- rep(xs_2[-length(xs_2)], length=n)
    xsrep_3 <- rep(xs_3[-length(xs_3)], length=n)
    
    sin1 <- sin(xsrep_1)
    sin2 <- sin(xsrep_2)
    sin3 <- sin(xsrep_3)
    
    cos1 <- cos(xsrep_1)
    cos2 <- cos(xsrep_2)
    cos3 <- cos(xsrep_3)
    
    seasonality_sin1 <- sin1
    seasonality_sin2 <- sin2
    seasonality_sin3 <- sin3
    
    seasonality_cos1 <- cos1
    seasonality_cos2 <- cos2
    seasonality_cos3 <- cos3
    
    input_windows = embed(time_series_log[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    output_windows = embed(time_series_log[-(1:input_size)], max_forecast_horizon)[, max_forecast_horizon : 1]
    seasonality_sin1_windows = embed(seasonality_sin1[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    seasonality_sin2_windows = embed(seasonality_sin2[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    seasonality_sin3_windows = embed(seasonality_sin3[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    
    seasonality_cos1_windows = embed(seasonality_cos1[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    seasonality_cos2_windows = embed(seasonality_cos2[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    seasonality_cos3_windows = embed(seasonality_cos3[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    
    seasonality_sin1_windows =  seasonality_sin1_windows[, c(30)]
    seasonality_sin2_windows =  seasonality_sin2_windows[, c(30)]
    seasonality_sin3_windows =  seasonality_sin3_windows[, c(30)]
    
    seasonality_cos1_windows =  seasonality_cos1_windows[, c(30)]
    seasonality_cos2_windows =  seasonality_cos2_windows[, c(30)]
    seasonality_cos3_windows =  seasonality_cos3_windows[, c(30)]
    
    meanvalues <- rowMeans(input_windows)
    input_windows <- input_windows - meanvalues
    output_windows <- output_windows -meanvalues
    
    if (validation) {
      sav_df = matrix(NA, ncol = (5 + input_size + 6 + max_forecast_horizon), nrow = nrow(input_windows ))
      sav_df = as.data.frame(sav_df)
      sav_df[, 1] = paste(idr - 1, '|i', sep = '')
      sav_df[, 2] = seasonality_sin1_windows
      sav_df[, 3] = seasonality_sin2_windows
      sav_df[, 4] = seasonality_sin3_windows
      sav_df[, 5] = seasonality_cos1_windows
      sav_df[, 6] = seasonality_cos2_windows
      sav_df[, 7] = seasonality_cos3_windows
      sav_df[, 8 : (input_size + 6 + 1)] = input_windows
      sav_df[, (input_size + 6 + 2)] = '|o'
      sav_df[, (input_size + 6 + 3):(input_size + 6 + max_forecast_horizon  +2)] = output_windows
      sav_df[, (input_size + 6 + max_forecast_horizon  + 3)] = '|#'
      sav_df[, (input_size + 6 + max_forecast_horizon + 4)] = time_series_mean
      sav_df[, (input_size + 6 + max_forecast_horizon + 5)] = meanvalues
    }else {
      sav_df = matrix(NA, ncol = (2 + input_size + 6 + max_forecast_horizon), nrow = nrow(input_windows))
      sav_df = as.data.frame(sav_df) 
      sav_df[, 1] = paste(idr - 1, '|i', sep = '')
      sav_df[, 2] = seasonality_sin1_windows
      sav_df[, 3] = seasonality_sin2_windows
      sav_df[, 4] = seasonality_sin3_windows
      sav_df[, 5] = seasonality_cos1_windows
      sav_df[, 6] = seasonality_cos2_windows
      sav_df[, 7] = seasonality_cos3_windows
      sav_df[, 8 : (input_size + 6 + 1)] = input_windows
      sav_df[, (input_size + 6 + 2)] = '|o'
      sav_df[, (input_size + 6 + 3):(input_size + 6 + max_forecast_horizon  +2)] = output_windows
    }
    
    write.table(sav_df, file = OUTPUT_PATH, row.names = F, col.names = F, sep = " ", quote = F, append = TRUE)
  }
}

end_time <- Sys.time()

print(paste0("Total time", (end_time - start_time)))