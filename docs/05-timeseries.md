# Working with time series



---

This chapter describes how to access information from time series in SITS.

---

## Data structures for satellite time series

The *sits* package requires a set of time series data, describing properties in spatiotemporal locations of interest. For land use classification, this set consists of samples provided by experts that take in-situ field observations or recognize land classes using high-resolution images. The package can also be used for any type of classification, provided that the timeline and bands of the time series (used for training) match that of the data cubes. 

For handling time series, the package uses a `sits tibble` to organize time series data with associated spatial information. A `tibble` is a generalization of a `data.frame`, the usual way in R to organize data in tables. Tibbles are part of the `tidyverse`, a collection of R packages designed to work together in data manipulation [@Wickham2017]. As an example of how the sits tibble works, the following code shows the first three lines of a tibble containing $1,882$ labeled samples of land cover in Mato Grosso state of Brazil. The samples contain time series extracted from the MODIS MOD13Q1 product from 2000 to 2016, provided every $16$ days at $250$-meter spatial resolution in the Sinusoidal projection. Based on ground surveys and high-resolution imagery, it includes samples of nine classes: "Forest", "Cerrado", "Pasture", "Soybean-fallow", "Fallow-Cotton", "Soybean-Cotton", "Soybean-Corn", "Soybean-Millet", and "Soybean-Sunflower". 


```
#> # A tibble: 3 x 7
#>   longitude latitude start_date end_date   label   cube    time_series      
#>       <dbl>    <dbl> <date>     <date>     <chr>   <chr>   <list>           
#> 1     -55.2   -10.8  2013-09-14 2014-08-29 Pasture MOD13Q1 <tibble [23 x 5]>
#> 2     -57.8    -9.76 2006-09-14 2007-08-29 Pasture MOD13Q1 <tibble [23 x 5]>
#> 3     -51.9   -13.4  2014-09-14 2015-08-29 Pasture MOD13Q1 <tibble [23 x 5]>
```

A sits tibble contains data and metadata. The first six columns contain the metadata: spatial and temporal information, the label assigned to the sample, and the data cube from where the data has been extracted. The spatial location is given in longitude and latitude coordinates for the "WGS84" ellipsoid. For example, the first sample has been labeled "Cerrado, at location (-58.5631, -13.8844) and is considered valid for the period (2007-09-14, 2008-08-28). Informing the dates where the label is valid is crucial for correct classification. In this case, the researchers involved in labeling the samples chose to use the agricultural calendar in Brazil, where the spring crop is planted in the months of September and October, and the autumn crop is planted in the months of February and March. For other applications and other countries, the relevant dates will most likely be different from those used in the example. The `time_series` column contains the time series data for each spatiotemporal location. This data is also organized as a tibble, with a column with the dates and the other columns with the values for each spectral band. 

## Utilities for handling time series

The package provides functions for data manipulation and displaying information for sits tibble. For example, `sits_labels_summary()` shows the labels of the sample set and their frequencies.


```
#> # A tibble: 9 x 3
#>   label         count   prop
#>   <chr>         <int>  <dbl>
#> 1 Cerrado         379 0.200 
#> 2 Fallow_Cotton    29 0.0153
#> 3 Forest          131 0.0692
#> 4 Pasture         344 0.182 
#> 5 Soy_Corn        364 0.192 
#> 6 Soy_Cotton      352 0.186 
#> 7 Soy_Fallow       87 0.0460
#> 8 Soy_Millet      180 0.0951
#> 9 Soy_Sunflower    26 0.0137
```

In many cases, it is helpful to relabel the data set. For example, there may be situations when one wants to use a smaller set of labels, since samples in one label on the original set may not be distinguishable from samples with other labels. We then could use `sits_relabel()`, which requires a conversion list (for details, see `?sits_relabel`).

Given that we have used the tibble data format for the metadata and the embedded time series, one can use the functions from `dplyr`, `tidyr`, and `purrr` packages of the `tidyverse` [@Wickham2017] to process the data. For example, the following code uses `sits_select()` to get a subset of the sample data set with two bands (NDVI and EVI) and then uses the `dplyr::filter()` to select the samples labelled either as "Cerrado" or "Pasture". 



## Time series visualisation

Given a small number of samples to display, `plot` tries to group as many spatial locations together. In the following example, the first 12 samples of  "Cerrado" class refer to the same spatial location in consecutive time periods. For this reason, these samples are plotted together.

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{05-timeseries_files/figure-latex/cerrado-12-1} 

}

\caption{Plot of the first 'Cerrado' sample from data set}(\#fig:cerrado-12)
\end{figure}

For a large number of samples, where the number of individual plots would be substantial, the default visualization combines all samples together in a single temporal interval (even if they belong to different years). All samples with the same band and label are aligned to a common time interval. This plot is useful to show the spread of values for the time series of each band. The strong red line in the plot shows the median of the values, while the two orange lines are the first and third interquartile ranges. The documentation of `plot.sits()` has more details about the different ways it can display data.

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{05-timeseries_files/figure-latex/unnamed-chunk-5-1} 

}

\caption{Plot of all Cerrado samples from data set}(\#fig:unnamed-chunk-5)
\end{figure}

## Obtaining time series data from data cubes

To get a time series in sits, one has to create a data cube, as described previously.  Users can request one or more time series points from a data cube by using `sits_get_data()`. This function provides a general means of access to image time series. Given a data cube, the user provides the latitude and longitude of the desired location, the bands, and the start date and end date of the time series. If the start and end dates are not provided, it retrieves all the available periods. The result is a tibble that can be visualized using `plot()`.

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{05-timeseries_files/figure-latex/unnamed-chunk-6-1} 

}

\caption{NDVI and EVI time series fetched from local raster cube.}(\#fig:unnamed-chunk-6)
\end{figure}

A useful case is when a set of labelled samples are available to be used as a training data set. In this case, one usually has trusted observations that are labelled and commonly stored in plain text files in comma-separated values (CSV) or using shapefiles (SHP). Function `sits_get_data()` takes a CSV or SHP file path as an argument. In the case of CSV text file, they should provide, for each training sample, its latitude and longitude, the start and end dates, and a label associated with a ground sample. An example of a CSV file used is shown below. 


```
#>   id longitude  latitude start_date   end_date   label
#> 1  1 -55.65931 -11.76267 2013-09-14 2014-08-29 Pasture
#> 2  2 -55.64833 -11.76385 2013-09-14 2014-08-29 Pasture
#> 3  3 -55.66738 -11.78032 2013-09-14 2014-08-29  Forest
```

The main difference between the files used by *sits* to retrieve training samples from those used traditionally in remote sensing data analysis is that users are expected to provide the temporal information (`start_date` and `end_date`). In the simplest case, all samples share the same start and end data. That is not a strict requirement. Users can specify different dates, as long as they have a compatible duration. For example, the data set `samples_modis_4bands` provided with the sits package contains samples from different years covering the same duration. These samples were obtained from the MOD13Q1 product, which contains the same number of images per year. Thus, all time series in the data set `samples_modis_4bands` have the same number of instances. 


```
#> # A tibble: 5 x 7
#>   longitude latitude start_date end_date   label   cube    time_series      
#>       <dbl>    <dbl> <date>     <date>     <chr>   <chr>   <list>           
#> 1     -55.2   -10.8  2013-09-14 2014-08-29 Pasture MOD13Q1 <tibble [23 x 5]>
#> 2     -57.8    -9.76 2006-09-14 2007-08-29 Pasture MOD13Q1 <tibble [23 x 5]>
#> 3     -51.9   -13.4  2014-09-14 2015-08-29 Pasture MOD13Q1 <tibble [23 x 5]>
#> 4     -56.0   -10.1  2005-09-14 2006-08-29 Pasture MOD13Q1 <tibble [23 x 5]>
#> 5     -54.6   -10.4  2013-09-14 2014-08-29 Pasture MOD13Q1 <tibble [23 x 5]>
```

Given a suitably built sample file, reading the time series in *sits* is achieved using the `sits_get_data`. This function has two mandatory parameters for CSV and SHP file; (a) `cube` which is the name of the R object that describes the data cube; (b) `file` which is the name of the CSV or SHP file. 

```
#> # A tibble: 3 x 7
#>   longitude latitude start_date end_date   label   cube  time_series      
#>       <dbl>    <dbl> <date>     <date>     <chr>   <chr> <list>           
#> 1     -55.7    -11.8 2013-09-14 2014-08-29 Pasture Sinop <tibble [23 x 3]>
#> 2     -55.6    -11.8 2013-09-14 2014-08-29 Pasture Sinop <tibble [23 x 3]>
#> 3     -55.7    -11.8 2013-09-14 2014-08-29 Forest  Sinop <tibble [23 x 3]>
```

Users can also specify samples by providing shapefiles in point or polygon format. In this case, the geographical location is inferred from the geometries associated with the shapefile. For files containing points, the geographical location is obtained directly; for files with polygon, the parameter `.n_shp_pol` (defaults to 20) determines the number of samples to be extracted from each polygon. The temporal information is inferred from the data cube from which the samples are extracted or can be provided explicitly by the user. The label information is taken from the attribute file associated to the shapefile. The parameter `shp_attr` indicates the name of the column which contains the label to be associated with each time series. 


```
#> # A tibble: 3 x 7
#>   longitude latitude start_date end_date   label cube  time_series      
#>       <dbl>    <dbl> <date>     <date>     <chr> <chr> <list>           
#> 1     -55.6    -11.8 2013-09-14 2014-08-29 <NA>  Sinop <tibble [23 x 3]>
#> 2     -55.6    -11.8 2013-09-14 2014-08-29 <NA>  Sinop <tibble [23 x 3]>
#> 3     -55.6    -11.8 2013-09-14 2014-08-29 <NA>  Sinop <tibble [23 x 3]>
```

## Filtering techniques for time series

Satellite image time series generally is contaminated by atmospheric influence, geolocation error, and directional effects [@Lambin2006]. Atmospheric noise, sun angle, interferences on observations or different equipment specifications, as well as the very nature of the climate-land dynamics can be sources of variability [@Atkinson2012]. Inter-annual climate variability also changes the phenological cycles of the vegetation, resulting in time series whose periods and intensities do not match on a year-to-year basis. To make the best use of available satellite data archives, methods for satellite image time series analysis need to deal with  *noisy* and *non-homogeneous* data sets. In this vignette, we discuss filtering techniques to improve time series data that present missing values or noise.

The literature on satellite image time series has several applications of filtering to correct or smooth vegetation index data. The `sits` have support for Savitzky–Golay (`sits_sgolay()`), Whitaker (`sits_whittaker()`), envelope (`sits_envelope()`) filters. The first two filters are commonly used in the literature, while the remaining two have been developed by the authors.

Various somewhat conflicting results have been expressed in relation to the time series filtering techniques for phenology applications. For example, in an investigation of phenological parameter estimation, @Atkinson2012 found that the Whittaker and Fourier transform approaches were preferable to the double logistic and asymmetric Gaussian models. They applied the filters to preprocess MERIS NDVI time series for estimating phenological parameters in India. Comparing the same filters as in the previous work, @Shao2016 found that only Fourier transform and Whittaker techniques improved interclass separability for crop classes and significantly improved overall classification accuracy. The authors used MODIS NDVI time series from the Great Lakes region in North America. @Zhou2016 found that the asymmetric Gaussian model outperforms other filters over high latitude boreal biomes, while the Savitzky-Golay model gives the best reconstruction performance in tropical evergreen broadleaf forests. In the remaining biomes, Whittaker gives superior results. The authors compare all previously mentioned filters plus the Savitzky-Golay method for noise removal in MODIS NDVI data from sites spread worldwide in different climatological conditions. Many other techniques can be found in applications of satellite image time series such as curve fitting [@Bradley2007], wavelet decomposition [@Sakamoto2005], mean-value iteration, ARMD3-ARMA5, and 4253H [@Hird2009]. Therefore, any comparative analysis of smoothing algorithms depends on the adopted performance measurement.

One of the main uses of time series filtering is to reduce the noise and miss data produced by clouds in tropical areas. The following examples use data produced by the PRODES project [@INPE2019], which detects deforestation in the Brazilian Amazon rain forest through visual interpretation. This data set is called `samples_para_mixl8mod` and is provided together with the **sitsdata** package. It has  $617$ samples from a region corresponding to the standard Landsat Path/Row 226/064. This is an area in the East of the Brazilian Pará state. It was chosen because of its huge cloud cover from November to March, which is a significant factor in degrading time series quality. Its NDVI and EVI time series were extracted from a combination of MOD13Q1 and Landsat8 images (to best visualize the effects of each filter, we selected only NDVI time series).

### Savitzky–Golay filter

The Savitzky-Golay filter works by fitting a successive array of $2n+1$ adjacent data points with a $d$-degree polynomial through linear least squares. The central point $i$ of the window array assumes the value of the interpolated polynomial. An equivalent and much faster solution than this convolution procedure is given by the closed expression
$$
  {\hat{x}_{i}=\sum _{j=-n}^{n}C_{j}\,x_{i+j}},
$$
  where $\hat{x}$ is the the filtered time series, $C_{j}$ are the Savitzky-Golay smoothing coefficients, and $x$ is the original time series.

The coefficients $C_{j}$ depend uniquely on the polynomial degree ($d$) and the length of the window data points (given by parameter $n$). If ${d=0}$, the coefficients are constants ${C_{j}=1/(2n+1)}$ and the Savitzky-Golay filter will be equivalent to moving average filter. When the time series are equally spaced, the coefficients have an analytical solution. According to @Madden1978, for ${d\in{}[2,3]}$ each $C_{j}$ smoothing coefficients can be obtained by
$$
  C_{j}=\frac{3(3n^2+3n-1-5j^2)}{(2n+3)(2n+1)(2n-1)}.
$$
  
In general, the Savitzky-Golay filter produces smoother results for a larger value of $n$ and/or a smaller value of $d$ [@Chen2004]. The optimal value for these two parameters can vary from case to case. In SITS, the user can set the order of the polynomial using the parameter `order` (default = 3), the size of the temporal window with the parameter `length` (default = 5), and the temporal expansion with the parameter `scaling` (default = 1). The following example shows the effect of Savitsky-Golay filter on a point extracted from the MOD13Q1 product, ranging from 2000-02-18 to 2018-01-01.


\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{05-timeseries_files/figure-latex/unnamed-chunk-11-1} 

}

\caption{Savitzky-Golay filter applied on a multi-year NDVI time series.}(\#fig:unnamed-chunk-11)
\end{figure}

Notice that the resulting smoothed curve has both desirable and unwanted properties. For the period 2000 to 2008, the Savitsky-Golay filter remove noise resulting from clouds. However, after 2010, when the region has been converted to agriculture, the filter removes an important part of the natural variability from the crop cycle. Therefore, the `length` parameter is arguably too big and results in oversmoothing. Users can try to reduce this parameter and analyse the results.

### Whittaker filter

The Whittaker smoother attempts to fit a curve that represents the raw data, but is penalized if subsequent points vary too much [@Atzberger2011]. The Whittaker filter is a balancing between the residual to the original data and the "smoothness" of the fitted curve. The residual, as measured by the sum of squares of all $n$ time series points deviations, is given by
$$
  RSS=\sum_{i}(x_{i} - \hat{x_{i}})^2,
$$
   where $x$ and $\hat{x}$ are the original and the filtered time series vectors, respectively. The smoothness is assumed to be the measure of the sum of the squares of the third-order differences of the time series [@Whittaker1922], which is given by
$$
  \begin{split}
S\!S\!D = (\hat{x}_4 - 3\hat{x}_3 + 3\hat{x}_2 - \hat{x}_1)^2 + (\hat{x}_5 - 3\hat{x}_4 + 3\hat{x}_3 - \hat{x}_2)^2 \\ + \ldots + (\hat{x}_n - 3\hat{x}_{n-1} + 3\hat{x}_{n-2} - \hat{x}_{n-3})^2.
\end{split}
$$
  
  The filter is obtained by finding a new time series $\hat{x}$ whose points minimize the expression
$$
  RSS+\lambda{}S\!S\!D,
$$ 
   where $\lambda{}$, a scalar, works as a "smoothing weight" parameter. The minimization can be obtained by differentiating the expression with respect to $\hat{x}$ and equating it to zero. The solution of the resulting linear system of equations gives the filtered time series, which, in matrix form, can be expressed as

$$
  \hat{x} = ({\rm I} + \lambda {D}^{\intercal} D)^{-1}x,
$$
  where ${\rm I}$ is the identity matrix and 
$$
  D = \left[\begin{array}{ccccccc}
             1 & -3 & 3 & -1 & 0 & 0 &\cdots \\
             0 & 1 & -3 & 3 & -1 & 0 &\cdots \\
             0 & 0 & 1 & -3 & 3 & -1 & \cdots \\
             \vdots & \vdots & \vdots & \vdots & \vdots & \vdots & \ddots
             \end{array}
             \right]
$$

The following example shows the effect of Whitakker filter on a point extracted from the MOD13Q1 product, ranging from 2000-02-18 to 2018-01-01. The `lambda` parameter controls the smoothing of the filter. By default, it is set to 0.5, a small value. For illustrative purposes, we show the effect of a larger smoothing parameter

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{05-timeseries_files/figure-latex/unnamed-chunk-12-1} 

}

\caption{Whittaker filter applied on a one-year NDVI time series.}(\#fig:unnamed-chunk-12)
\end{figure}

In the same way as what is observed in the Savitsky-Golay filter, high values of the smoothing parameter `lambda` produce an oversmoothed time series that reduces the capacity of the time series to represent natural variations on crop growth. For this reason, low smoothing values are recommended when using the `sits_whittaker` function.
