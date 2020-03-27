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
    OUTPUT_PATH = paste(OUTPUT_DIR, "energy_tbats", sep = '/')
    
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
    
    # apply stl
    stl_result = tryCatch({
      sstl = tbats(msts(time_series_log, seasonal.periods = c(seasonality_period_1,seasonality_period_2, seasonality_period_3)))
      sstl_comp = tbats.components(sstl)
      seasonal_vect1 = as.numeric(sstl_comp[, 'season1'])
      seasonal_vect2 = as.numeric(sstl_comp[, 'season2'])
      seasonal_vect3 = as.numeric(sstl_comp[, 'season3'])
      levels_vect = as.numeric(sstl_comp[, 'level'])
      values_vect = sstl$errors + levels_vect
      cbind(seasonal_vect_1,seasonal_vect_2,seasonal_vect3,levels_vect, values_vect)
    }, error = function(e) {
      seasonal_vect1 = rep(0, length(time_series_length))
      seasonal_vect2 = rep(0, length(time_series_length))
      seasonal_vect3 = rep(0, length(time_series_length))
      levels_vect = time_series_log
      values_vect = time_series_log
      cbind(seasonal_vect1, seasonal_vect2, seasonal_vect3, levels_vect, values_vect)
    })
    
    input_windows = embed(time_series_log[1 : (time_series_length - max_forecast_horizon)], input_size)[, input_size : 1]
    output_windows = embed(time_series_log[-(1:input_size)], max_forecast_horizon)[, max_forecast_horizon : 1]
    seasonality1_windows = embed(stl_result[1 : (time_series_length - max_forecast_horizon), 1], input_size)[, input_size : 1]
    seasonality2_windows = embed(stl_result[1 : (time_series_length - max_forecast_horizon), 2], input_size)[, input_size : 1]
    seasonality3_windows = embed(stl_result[1 : (time_series_length - max_forecast_horizon), 3], input_size)[, input_size : 1]
    
    seasonality1_windows =  seasonality1_windows[, c(30)]
    seasonality2_windows =  seasonality2_windows[, c(30)]
    seasonality3_windows =  seasonality3_windows[, c(30)]
    
    meanvalues <- rowMeans(input_windows)
    input_windows <- input_windows - meanvalues
    output_windows <- output_windows -meanvalues
   
    if (validation) {
      # create the seasonality metadata
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

#forecast_24 = stlf(ts(sstl[, 3] , frequency = 24), "period", h = 48)