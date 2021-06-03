# Validation and accuracy measurements in SITS

---

This chapter presents the validation and accuracy measures available in the SITS package.

---



## Validation techniques

Validation is a process undertaken on models to estimate some error associated with them, and hence has been used widely in different scientific disciplines. Here, we are interested in estimating the prediction error associated to some model. For this purpose, we concentrate on the *cross-validation* approach, probably the most used validation technique [@Hastie2009].

Cross-validation estimates the expected prediction error. It uses part of the available samples to fit the classification model, and a different part to test it. The so-called *k-fold* validation, we split the data into $k$ partitions with approximately the same size and proceed by fitting the model and testing it $k$ times. At each step, we take one distinct partition for test and the remaining ${k-1}$ for training the model, and calculate its prediction error for classifying the test partition. A simple average gives us an estimation of the expected prediction error. 

A natural question that arises is: *how good is this estimation?* According to @Hastie2009, there is a bias-variance trade-off in choice of $k$. If $k$ is set to the number of samples, we obtain the so-called *leave-one-out* validation, the estimator gives a low bias for the true expected error, but produces a high variance expectation. This can be computational expensive as it requires the same number of fitting process as the number of samples. On the other hand, if we choose ${k=2}$, we get a high biased expected prediction error estimation that overestimates the true prediction error, but has a low variance. The recommended choices of $k$ are $5$ or $10$, which somewhat overestimates the true prediction error.

`sits_kfold_validate()` gives support the k-fold validation in `sits`. The following code gives an example on how to proceed a k-fold cross-validation in the package. It perform a five-fold validation using SVM classification model as a default classifier. We can see in the output text the corresponding confusion matrix and the accuracy statistics (overall and by class).


```
#> Confusion Matrix and Statistics
#> 
#>           Reference
#> Prediction Cerrado Pasture
#>    Cerrado     396      13
#>    Pasture       4     333
#>                                      
#>           Accuracy : 0.9772          
#>             95% CI : (0.9638, 0.9867)
#>                                      
#>              Kappa : 0.9541          
#>                                      
#>  Prod Acc  Cerrado : 0.9900          
#>  Prod Acc  Pasture : 0.9624          
#>  User Acc  Cerrado : 0.9682          
#>  User Acc  Pasture : 0.9881          
#> 
```

## Comparing different machine learning methods using k-fold validation

One useful function in SITS is the capacity to compare different validation methods and store them in an XLS file for further analysis. The following example shows how to do this, using the Mato Grosso data set. We take five models: random forests(`sits_rfor`), support vector machines (`sits_svm`), extreme gradient boosting (`sits_xgboost`), multi-layer perceptron (`sits_mlp`) and temporal convolutional neural network (`sits_TempCNN`). For simplicity, we use the default parameters provided by sits. After computing the confusion matrix and the statistics for each model, we store the result in a list. When the calculation is finished, the function `sits_to_xlsx` writes all of the results in an Excel-compatible spreadsheet.



The resulting Excel file can be opened with R or using spreadsheet programs. The figure below shows a printout of what is read by Excel. As shown below, each sheet corresponds to the output of one model. For simplicity, we show only the result of TempCNN, that has an overall accuracy of 97% and is the best-performing model. 

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth,height=0.9\textheight]{images/k_fold_validation_xlsx} 

}

\caption{Result of 5-fold cross validation of Mato Grosso dataset using TempCNN}(\#fig:unnamed-chunk-4)
\end{figure}

## Accuracy assessment 

### Time series

Users can perform accuracy assessment in *sits* both in time series datasets or in classified images using the `sits_accuracy` function. In the case of time series, the input is a sits tibble which has been classified by a sits model. The input tibble needs to contain valid labels in its "label" column. These labels are compared to the results of the prediction to the reference values. This function calculates the confusion matrix and then the resulting statistics using the R package "caret". 


```
#> 
#> Overall Statistics
#>                        
#>  Accuracy : 1          
#>    95% CI : (0.9951, 1)
#>                        
#>     Kappa : 1
```
The detailed accuracy measures can be obtained by printing the accuracy object.


```
#> Confusion Matrix and Statistics
#> 
#>           Reference
#> Prediction Cerrado Pasture
#>    Cerrado     400       0
#>    Pasture       0     346
#>                                 
#>           Accuracy : 1          
#>             95% CI : (0.9951, 1)
#>                                 
#>              Kappa : 1          
#>                                 
#>  Prod Acc  Cerrado : 1          
#>  Prod Acc  Pasture : 1          
#>  User Acc  Cerrado : 1          
#>  User Acc  Pasture : 1          
#> 
```

### Classified images 

To measure the accuracy of classified images, the `sits_accuracy` function uses an area-weighted technique, following the best practices proposed by @Olofsson2013. The need for area-weighted estimates arises from the fact the land use and land cover classes are not evenly distributed in space. In some applications (e.g., deforestation) where the interest lies in assessing how much of the image has changed, the area mapped as deforested is likely to be a small fraction of the total area. If users disregard the relative importance of small areas where change is taking place, the overall accuracy estimate will be inflated and unrealistic. For this reason, @Olofsson2013 argue that *"mapped areas should be adjusted to eliminate bias attributable to map classification error and these error-adjusted area estimates should be accompanied by confidence intervals to quantify the sampling variability of the estimated area"*.

With this motivation, when measuring accuracy of classified images, the function `sits_accuracy` follows @Olofsson2013 and @Olofsson2014.  The following explanation is extracted from the paper of @Olofsson2013, and users should refer to this paper for further explanation.

Given a classified image and a validation file, the first step is to calculate the confusion matrix in the traditional way, i.e., by identifying the commission and omission errors. Then we calculate the unbiased estimator of the proportion of area in cell $i,j$ of the error matrix

$$
\hat{p_{i,j}} = W_i\frac{n_{i,j}}{n_i}
$$
where the total area of the map is $A_{tot}$, the mapping area of class $i$ is $A_{m,i}$ and the proportion of area mapped as class $i$ is $W_i = {A_{m,i}}/{A_{tot}}$. Adjusting for area size allows producing an unbiased estimation of the total area of class $j$, defined as a stratified estimator
$$
\hat{A_j} = A_{tot}\sum_{i=1}^KW_i\frac{n_{i,j}}{n_i}
$$
This unbiased area estimator includes the effect of false negatives (omission error) while not considering the effect of false positives (commission error). The area estimates also allow producing an unbiased estimate of the user's and producer's accuracy for each class. Following @Olofsson2013, we can also estimate the 95% confidence interval for $\hat{A_j}$. 

To use the `sits_accuracy` function to produce the adjusted area estimates, users have to provide the classified image together with a csv file containing a set of labeled points. The csv file should have the same format as the one used to obtain samples, as discussed earlier. 

In what follows, we show a simple example of using the accuracy function to estimate the quality of the classification

```
#> Area Weigthed Statistics
#> Overall Accuracy = 0.763\begin{table}
#> 
#> \caption{(\#tab:unnamed-chunk-7)Area-Weighted Users and Producers Accuracy}
#> \centering
#> \begin{tabular}[t]{l|r|r}
#> \hline
#>   & User & Producer\\
#> \hline
#> Cerrado & 1.00 & 0.66\\
#> \hline
#> Forest & 0.60 & 1.00\\
#> \hline
#> Pasture & 0.75 & 0.62\\
#> \hline
#> Soy\_Corn & 0.86 & 0.72\\
#> \hline
#> \end{tabular}
#> \end{table}
#> \begin{table}
#> 
#> \caption{(\#tab:unnamed-chunk-7)Mapped Area x Estimated Area (ha)}
#> \centering
#> \begin{tabular}[t]{l|r|r|r}
#> \hline
#>   & Mapped Area (ha) & Error-Adjusted Area (ha) & Conf Interval (ha)\\
#> \hline
#> Cerrado & 31667.4 & 47969.6 & 31952.3\\
#> \hline
#> Forest & 81511.0 & 48906.6 & 39133.4\\
#> \hline
#> Pasture & 19812.9 & 23901.4 & 20206.7\\
#> \hline
#> Soy\_Corn & 63291.9 & 75505.6 & 37805.6\\
#> \hline
#> \end{tabular}
#> \end{table}
```

This is an illustrative example to express the situation where there is a limited number of ground truth points. As a result of a limited validation sample, the estimated confidence interval in area estimation is large. This indicates a questionable result. We recommend that users follow the procedures recommended by @Olofsson2014 to estimate the number of ground truth measures per class that are required to get a reliable estimate. 


