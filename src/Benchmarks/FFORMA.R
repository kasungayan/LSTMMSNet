# For more details about FFORMA method/installation/configurations: https://github.com/robjhyndman/M4metalearning/
set.seed(1234)
library(M4metalearning)
library(tsfeatures)
library(xgboost)
library(rBayesianOptimization)


ts_df <- read.csv("solar_train.txt", header = FALSE, sep = ",")
horizon <- 24
ts_list = list()


for (i in 1 : nrow(ts_df)){
  print(i)
  time_series <- ts(as.numeric(ts_df[i,]))
  ts_list[[i]] <- list(st =paste0("D",i), x = time_series, h = horizon)
}


start_time <- Sys.time()
meta_M4 <- temp_holdout(ts_list)

print("Started Modelling")

meta_M4 <- calc_forecasts(meta_M4, forec_methods(), n.cores=4)
meta_M4 <- calc_errors(meta_M4)
meta_M4 <- THA_features(meta_M4, n.cores=4)

saveRDS(meta_M4, "metasolar.rds")

#meta_M4 <- readRDS("metaenergy.rds")

hyperparameter_search(meta_M4, filename = "solar_hyper.RData", n_iter=10)
load("solar_hyper.RData")
best_hyper <- bay_results[ which.min(bay_results$combi_OWA), ]

#Train the metalearning model with the best hyperparameters found

train_data <- create_feat_classif_problem(meta_M4)

param <- list(max_depth=best_hyper$max_depth,
              eta=best_hyper$eta,
              nthread = 3,
              silent=1,
              objective=error_softmax_obj,
              num_class=ncol(train_data$errors), #the number of forecast methods used
              subsample=bay_results$subsample,
              colsample_bytree=bay_results$colsample_bytree)


meta_model <- train_selection_ensemble(train_data$data,
                                       train_data$errors,
                                       param=param)

print("Done model training")

final_M4 <- ts_list

#just calculate the forecast and features
final_M4 <- calc_forecasts(final_M4, forec_methods())
final_M4 <- THA_features(final_M4)

#get the feature matrix
final_data <- create_feat_classif_problem(final_M4)
#calculate the predictions using our model
preds <- predict_selection_ensemble(meta_model, final_data$data)
#calculate the final mean forecasts
final_M4 <- ensemble_forecast(preds, final_M4)
saveRDS(final_M4, "FinalForecastsSolarYearly.rds")

#the combination predictions are in the field y_hat of each element in the list
#lets check one
end_time <- Sys.time()

print(paste0("Total time", (end_time - start_time)))

forecast_df = matrix(nrow = 300, ncol = 24)


for (idr in 1 : length(final_M4)){
  time_series_forecast <- as.numeric(final_M4[[idr]]$y_hat)
  time_series_forecast[time_series_forecast <0] <- 0
  forecast_df[idr,] <- time_series_forecast
}
write.table(forecast_df, "forma_solar_yearly_forecasts.txt", row.names = FALSE, col.names = FALSE)



