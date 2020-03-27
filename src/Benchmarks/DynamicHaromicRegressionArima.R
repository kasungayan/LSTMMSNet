library(forecast)
set.seed(1234)

df_train <- read.csv("solar_train.txt", header = FALSE)
df_test <- read.csv("solar_test.txt", header = FALSE)

forecast_df = matrix(nrow = 300, ncol = 24)
actual_df = matrix(nrow = 300, ncol = 24)

start_time <- Sys.time()

for(index in 1 : length(hourly_M4)){
  print("start")
  #time series data.
  cust_df <- as.numeric(df_train[1,])
  actual_series <- as.numeric(df_test[1,])
  
  arima_ts = msts(cust_df, seasonal.periods = c(24,168,8766))
  
  xreg <- fourier(arima_ts, K =c(10,20,20))
  fit <- auto.arima(arima_ts, xreg = xreg, seasonal = FALSE)
  
  arima_forecast = forecast(fit, xreg = fourier(arima_ts, K= c(10,20,20),h=24))
  arima_forecast_mean <- as.numeric(arima_forecast$mean)
  arima_forecast_mean <- (arima_forecast_mean)
  
  end_time <- Sys.time()
  
  print(paste0("Total time", (end_time - start_time)))
  
  forecast_df[index, ] <- arima_forecast_mean
  actual_df[index, ] <- actual_series
}


write.table(forecast_df, "dynamicregression_arima_forecasts.txt", row.names = FALSE, col.names = FALSE)

sMAPE <- rowMeans(2*abs(forecast_df - actual_df)/(abs(forecast_df) + abs(actual_df)))
print(mean(sMAPE))
print(median(sMAPE))


