library(forecast)
library(xts)
library(prophet)
set.seed(1234)
library(lubridate)

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
  
  ts <- seq(from = as.POSIXct("2010-01-01 00:00"), length.out = length(cust_df_log), by = "hour")
  
  history <- data.frame(ds = ts, y = cust_df_log)
  
  future_start <-  ts[length(cust_df_log)] + 3600
  
  future <- data.frame(ds = seq(from = future_start , length.out = 24, by = "hour"))
  
    m <- prophet(history, daily.seasonality = TRUE, weekly.seasonality = TRUE, yearly.seasonality = TRUE)
  forecast_prophet <- predict(m,future)
  
  prophet_forecast_mean <- as.numeric(forecast_prophet$yhat)
  prophet_forecast_mean[prophet_forecast_mean <0] <-0
  
  forecast_df[i, ] <- prophet_forecast_mean
  actual_df[i, ] <- actual_series
}

end_time <- Sys.time()
  
print(paste0("Total time", (end_time - start_time)))

write.table(forecast_df, "prophet_forecasts.txt", row.names = FALSE, col.names = FALSE)

sMAPE <- rowMeans(2*abs(forecast_df - actual_df)/(abs(forecast_df) + abs(actual_df)))
print(mean(sMAPE))
print(median(sMAPE))