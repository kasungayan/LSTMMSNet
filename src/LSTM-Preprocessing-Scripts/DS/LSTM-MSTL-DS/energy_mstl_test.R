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
  OUTPUT_PATH = paste(OUTPUT_DIR, "energy_mstl_test", sep = '/')
  OUTPUT_PATH = paste(OUTPUT_PATH, max_forecast_horizon, sep = '')
  OUTPUT_PATH = paste(OUTPUT_PATH, 'i', input_size, sep = '')
  OUTPUT_PATH = paste(OUTPUT_PATH, 'txt', sep = '.')
  
  time_series_data <- as.numeric(df_train[idr,])
  time_series_mean <- mean(time_series_data)
  
  time_series_data <- time_series_data/(time_series_mean)
  
  time_series_log <- log(time_series_data +1)
  time_series_length = length(time_series_log)
  
  stl_result = tryCatch({
    sstl = mstl(msts(time_series_log, seasonal.periods = c(seasonality_period_1,seasonality_period_2, seasonality_period_3)), s.window = "period")
    seasonal_vect_1 = as.numeric(sstl[, 3])
    seasonal_vect_2 = as.numeric(sstl[, 4])
    seasonal_vect_3 = as.numeric(sstl[, 5])
    levels_vect = as.numeric(sstl[, 2])
    values_vect = as.numeric(sstl[, 2] + sstl[, 6])
    cbind(seasonal_vect_1,seasonal_vect_2,seasonal_vect_3,levels_vect, values_vect)
  }, error = function(e) {
    seasonal_vect_1 = rep(0, length(time_series_length))
    seasonal_vect_2 = rep(0, length(time_series_length))
    seasonal_vect_3 = rep(0, length(time_series_length))
    levels_vect = time_series_log
    values_vect = time_series_log
    cbind(seasonal_vect_1, seasonal_vect_2,seasonal_vect_3,levels_vect, values_vect)
  })
  
  comp <- (sstl)
  periods <- c(24,168,8766)
  h <- max_forecast_horizon
  n <- time_series_length
  
  seasComps <- matrix(NA, nrow=h, ncol=length(periods))
  seasonality = tryCatch({
    for(i in 1:length(periods)) {
      m <- periods[i]
      seasComps[,i] <- rep(comp[n-(m:1)+1,2+i],trunc(1+(h-1)/m))[1:h]
    }
    seasComp <- rowSums(seasComps)
    seasonality_vector = (seasComp)
    c(seasonality_vector)
  }, error = function(e) {
    seasonality_vector = rep(0, max_forecast_horizon)   #stl() may fail, and then we would go on with the seasonality vector=0
    c(seasonality_vector)
  })
  
  input_windows = embed(stl_result[1 : time_series_length , 5], input_size)[, input_size : 1]
  level_values = stl_result[input_size : time_series_length, 4]
  input_windows = input_windows - level_values
  
  
  sav_df = matrix(NA, ncol = (4 + input_size + max_forecast_horizon), nrow = length(level_values))
  sav_df = as.data.frame(sav_df)
  
  sav_df[, 1] = paste(idr - 1, '|i', sep = '')
  sav_df[, 2 : (input_size + 1)] = input_windows
  
  sav_df[, (input_size + 2)] = '|#'
  sav_df[, (input_size + 3)] = time_series_mean
  sav_df[, (input_size + 4)] = level_values
  
  seasonality_windows = matrix(rep(t(seasonality),each=length(level_values)),nrow=length(level_values))
  sav_df[(input_size + 5) : ncol(sav_df)] = seasonality_windows
  
  write.table(sav_df, file = OUTPUT_PATH, row.names = F, col.names = F, sep = " ", quote = F, append = TRUE)
}

end_time <- Sys.time()

print(paste0("Total time", (end_time - start_time)))


