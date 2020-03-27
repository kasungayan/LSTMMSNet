LSTM-MSNet: Leveraging Forecasts on Sets of Related Time Series with Multiple Seasonal Patterns
===================

This page contains the explanation of our **L**ong **S**hort-**T**erm **M**emory **M**ulti-**S**easonal **Net** (LSTM-MSNet) forecasting framework, which can be used to forecast a sets of time series with multiple seasonal patterns.

In the description, we first provide a breif introduction to our methdology, and then explain the steps to be followed to execute our code and use our framework for your research work.

# Methodology #

<img src ="Images/LSTM-MSNet-Framework.PNG" width="800" align="center">

The above figure gives an overview of the proposed LSTM-MSNet training paradigms. In the DS approach, deseasonalised time series are used to train the LSTM-MSNet. Here, a reseasonalisation phase is required as the target MW patches are seasonally adjusted. Whereas in the SE approach, the seasonal values extracted from the deseasonalisation phase are employed as exogenous variables, along with the original time series to train the LSTM-MSNet. Here a reseasonalisation phase is not required as the target MW patches contain the original distribution of the time series. A more detailed explaination of these training paradigms can be found in our [manuscript](https://arxiv.org/pdf/1909.04293.pdf). 

We used **DS** and **SE** naming conventions in our code repository to distinguish these training paradigms. Please note that this repo contains seperate preprocessing files for each of these training paradigms.

# Usage #

## Software Requirements ##

| Software  | Version |
| ------------- | ------------- |
| `Python`  |  `>=3.6`  |
| `Tensorflow`  | `1.12.0`  |
| `smac`  | `0.8.0` |

As illustrated in the above figure, the LSTM-MSNet framework consists of three main phases: i) pre-processing phase: using state-of-the-art multi-seasonal decomposition techniques, i.e., *MSTL*, *Prophet*, *Tbats* to extract the seasonal components. Additonally, for the **SE** approach *fourier terms* have used to denote the seasonal trajectories (in order to supplement the subsequent LSTM training phase) ii) training phase: LSTM-MSNet framework training and iii) post-processing phase: retransform the forecasts into original scale.

## Path Variables ##

Set the `PYTHONPATH` env variable of the system. Append absolute paths of both the project root directory and the directory of the `external_packages/cocob_optimizer` into the `PYTHONPATH`  

## Preprocessing the Data ##

### Generating Train, Validation, and Test Scripts ###

Three files need to be created for every model, one per training, validation and testing. For R scripts (under src/LSTM-Preprocessing-Scripts), make sure to set the working directory to the project root folder. As an example, *solar_train.txt* file is hardcoded in the scripts. The current source code supports for comma seperated data input, however this can be easily adjustable for other delimiters. 

We assume *solar_train.txt* contain hourly energy consumption observations of multiple households. Each time series consists of 2 years of hourly data, and may present three types of seasonalities; *daily*, *weekly*, and *yearly*. As explained earlier, **SE** and **DS** folders denote the two different paradigms.  Whereas, **Baseline** folder denotes a varaint that does not use any paradigm when training the LSTM-MSNet.

### Generating TFrecords ###
When training the LSTM-MSNet, we use the tfrecords function provided by the Tensorflow API for a faster execution of our models. The preprocessing scripts used to generate the tfrecords can be found in the `src/LSTM-Models/preprocess_scripts` directory.
