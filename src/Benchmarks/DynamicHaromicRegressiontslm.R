library(forecast)
set.seed(1234)

df_train <- read.csv("solar_train.txt", header = FALSE)
df_test <- read.csv("solar_test.txt", header = FALSE)

forecast_df = matrix(nrow = 300, ncol = 24)
actual_df = matrix(nrow = 300, ncol = 24)

start_time <- Sys.time()

for(i in 1: nrow(df_train)){
  print(i)
  cust_df <- as.numeric(df_train[i,])
  #cust_df <-  cust_df + 1
  cust_df_log <- (cust_df)
  
  actual_series <- as.numeric(df_test[i,])
  
  arima_ts = msts(cust_df_log, seasonal.periods = c(24,168,8766))
  fit <- tslm(arima_ts ~ fourier(arima_ts, K =c(10,20,20)))
  
  arima_forecast = forecast(fit, newdata = data.frame(fourier(arima_ts, K= c(10,20,20),h=24)))
  
  arima_forecast_mean <- as.numeric(arima_forecast$mean)
  arima_forecast_forecast <- (arima_forecast_mean)
  arima_forecast_forecast[arima_forecast_forecast <0] <- 0
  
  forecast_df[i, ] <- arima_forecast_forecast
  actual_df[i, ] <- actual_series
}
end_time <- Sys.time()

print(paste0("Total time", (end_time - start_time)))

write.table(forecast_df, "dynamicHarmonic_forecasts_tslm.txt", row.names = FALSE, col.names = FALSE)

sMAPE <- rowMeans(2*abs(forecast_df - actual_df)/(abs(forecast_df) + abs(actual_df)))
print(mean(sMAPE))
print(median(sMAPE))

