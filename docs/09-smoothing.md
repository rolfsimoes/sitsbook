# (PART) Post classification {-}

# Post classification smoothing

---

This chapter describes the methods available for spatial smoothing of the results of machine learning classifications.

---




## Introduction 

Smoothing methods are an important complement to machine learning algorithms for image classification. Since these methods are mostly pixel-based, it is useful to complement them with post-processing smoothing to include spatial information in the result. For each pixel, machine learning and other statistical algorithms provide the probabilities of that pixel belonging to each of the classes. As a first step in obtaining a result, each pixel is assigned to the class whose probability is higher. After this step, smoothing methods use class probabilities to detect and correct outliers or misclassified pixels. 

Image classification post-processing has been defined as "a refinement of the labelling in a classified image in order to enhance its classification accuracy" [@Huang2014]. In remote sensing image analysis, these procedures are used  to combine pixel-based classification methods with a spatial post-processing method to remove outliers and misclassified pixels. For pixel-based classifiers, post-processing methods enable the inclusion of spatial information in the final results. 

Post-processing is a desirable step in any classification process. Most statistical classifiers use training samples derived from "pure" pixels, that have been selected by users as representative of the desired output classes. However, images contain many mixed pixels irrespective of the resolution. Also, there is a considerable degree of data variability in each class. These effects lead to outliers whose chance of misclassification is significant. To offset these problems, most post-processing methods use the "smoothness assumption" [@Schindler2012]: nearby pixels tend to have the same label. To put this assumption in practice, smoothing methods use the neighbourhood information to remove outliers and enhance consistency in the resulting product.

The following spatial smoothing methods are available in **sits**: bayesian smoothing, gaussian smoothing and bilinear smoothing. These methods are called using the `sits_smooth` function, as shown in the examples below.

## Bayesian smoothing 

Bayesian inference can be thought of as way of coherently updating our uncertainty in the light of new evidence. It allows the inclusion of expert knowledge on the derivation of probabilities.  In a Bayesian context, probability is taken as a subjective belief. The observation of the class probabilities of each pixel is taken as our initial belief on what the actual class of the pixel is. We then use Bayes' rule to consider how much the class probabilities of the neighbouring pixels affect our original belief. In the case of continuous probability distributions, Bayesian inference is expressed by the rule:

$$
\pi(\theta|x) \propto \pi(x|\theta)\pi(\theta)
$$

Bayesian inference involves the estimation of an unknown parameter $\theta$, which is the random variable that describe what we are trying to measure. In the case of smoothing of image classification, $\theta$ is the class probability for a given pixel. We model our initial belief about this value by a probability distribution,  $\pi(\theta)$, called the \emph{prior} distribution. It represents what we know about $\theta$ \emph{before} observing the data. The distribution $\pi(x|\theta)$, called the \emph{likelihood}, is estimated based on the observed data. It represents the added information provided by our observations. The \emph{posterior} distribution $\pi(\theta|x)$ is our improved belief of $\theta$ \emph{after} seeing the data. Bayes's rule states that the \emph{posterior} probability is proportional to the product of the \emph{likelihood} and the \emph{prior} probability.

### Derivation of bayesian parameters for spatiotemporal smoothing

In our post-classification smoothing model, we consider the output of a machine learning algorithm that provides the probabilities of each pixel in the image to belong to target classes. More formally, consider a set of $K$ classes that are candidates for labelling each pixel. Let $p_{i,t,k}$ be the probability of pixel $i$ belonging to class $k$, $k = 1, \dots, K$ at a time $t$, $t=1,\dots{},T$. We have 
$$
\sum_{k=1}^K p_{i,t,k} = 1, p_{i,t,k} > 0
$$
We label a pixel $p_i$ as being of class $k$ if
$$
	p_{i,t,k} > p_{i,t,m}, \forall m = 1, \dots, K, m \neq k
$$


For each pixel $i$, we take the odds of the classification for class $k$, expressed as
$$
	O_{i,t,k} = p_{i,t,k} / (1-p_{i,t,k})
$$
where $p_{i,t,k}$ is the probability of class $k$ at time $t$. We have more confidence in pixels with higher odds since their class assignment is stronger. There are situations, such as border pixels or mixed ones, where the odds of different classes are similar in magnitude. We take them as cases of low confidence in the classification result. To assess and correct these cases,  Bayesian smoothing methods borrow strength from the neighbors and reduces the variance of the estimated class for each pixel.

We further make the transformation 
$$
	x_{i,t,k} = \log [O_{i,t,k}]
$$
which measures the *logit* (log of the odds) associated to classifying the pixel $i$ as being of class $k$ at time $t$. The support of $x_{i,t,k}$ is $\mathbb{R}$. We can express  the pixel data as a $K$-dimensional multivariate logit vector 

$$
\mathbf{x}_{i,t}=(x_{i,t,k_{0}},x_{i,t,k_{1}},\dots{},x_{i,t,k_{K}})
$$ 


For each pixel, the random variable that describes the class probability $k$ at time $t$ is denoted by $\theta_{i,t,k}$. This formulation allows uses to use the class covariance matrix in our formulations. We can express Bayes' rule for all combinations of pixel and classes for a time interval as

$$
\pi(\boldsymbol\theta_{i,t}|\mathbf{x}_{i,t}) \propto \pi(\mathbf{x}_{i,t}|\boldsymbol\theta_{i,t})\pi(\boldsymbol\theta_{i,t}).	
$$

We assume the conditional distribution $\mathbf{x}_{i,t}|\boldsymbol\theta_{i,t}$ follows a multivariate normal distribution

$$
    [\mathbf{x}_{i,t}|\boldsymbol\theta_{i,t}]\sim\mathcal{N}_{K}(\boldsymbol\theta_{i,t},\boldsymbol\Sigma_{i,t}),
$$

where $\boldsymbol\theta_{i,t}$ is the mean parameter vector for the pixel $i$ at time $t$, and $\boldsymbol\Sigma_{i,t}$ is a known $k\times{}k$ covariance matrix that we will use as a parameter to control the level of smoothness effect. We will discuss later on how to estimate $\boldsymbol\Sigma_{i,t}$. To model our uncertainty about the parameter $\boldsymbol\theta_{i,t}$, we will assume it also follows a multivariate normal distribution with hyper-parameters $\mathbf{m}_{i,t}$ for the mean vector, and $\mathbf{S}_{i,t}$ for the covariance matrix. 

$$
    [\boldsymbol\theta_{i,t}]\sim\mathcal{N}_{K}(\mathbf{m}_{i,t}, \mathbf{S}_{i,t}).
$$

The above equation defines our prior distribution. The hyper-parameters $\mathbf{m}_{i,t}$ and $\mathbf{S}_{i,t}$ are obtained by considering the neighboring pixels of pixel $i$. The neighborhood can be defined as any graph scheme (e.g. a given Chebyshev distance on the time-space lattice) and can include the referencing pixel $i$ as a neighbor. Also, it can make no reference to time steps other than $t$ defining a space-only neighborhood. More formally, let 

$$
    \mathbf{V}_{i,t}=\{\mathbf{x}_{i_{j},t_{j}}\}_{j=1}^{N}, 
$$
denote the $N$ logit vectors of a spatiotemporal neighborhood $N$ of pixel $i$ at time $t$. Then the prior mean is calculated by

$$
	\mathbf{m}_{i,t}=\operatorname{E}[\mathbf{V}_{i,t}],
$$

and the prior covariance matrix by

$$
    \mathbf{S}_{i,t}=\operatorname{E}\left[
      \left(\mathbf{V}_{i,t}-\mathbf{m}_{i,t}\right)
      \left(\mathbf{V}_{i,t}-\mathbf{m}_{i,t}\right)^\intercal
    \right].
$$

Since the likelihood and prior are multivariate normal distributions, the posterior will also be a multivariate normal distribution, whose updated parameters can be derived by applying the density functions associated to the above equations. The posterior distribution is given by

$$
    [\boldsymbol\theta_{i,t}|\mathbf{x}_{i,t}]\sim\mathcal{N}_{K}\left(
    (\mathbf{S}_{i,t}^{-1} + \boldsymbol\Sigma^{-1})^{-1}( \mathbf{S}_{i,t}^{-1}\mathbf{m}_{i,t} + \boldsymbol\Sigma^{-1} \mathbf{x}_{i,t}),
    (\mathbf{S}_{i,t}^{-1} + \boldsymbol\Sigma^{-1})^{-1}
    \right).
$$

The $\boldsymbol\theta_{i,t}$ parameter model is our initial belief about a pixel vector using the neighborhood information in the prior distribution. It represents what we know about the probable value of $\mathbf{x}_{i,t}$ (and hence, about the class probabilities as the logit function is a monotonically increasing function) \emph{before} observing it. The \emph{likelihood} function $P[\mathbf{x}_{i,t}|\boldsymbol\theta_{i,t}]$ represents the added information provided by our observation of $\mathbf{x}_{i,t}$. The \emph{posterior} probability density function $P[\boldsymbol\theta_{i,t}|\mathbf{x}_{i,t}]$ is our improved belief of the pixel vector \emph{after} seeing $\mathbf{x}_{i,t}$.

At this point, we are able to infer a point estimator $\hat{\boldsymbol\theta}_{i,t}$ for the $\boldsymbol\theta_{i,t}|\mathbf{x}_{i,t}$ parameter. For the multivariate normal distribution, the posterior mean minimises not only the quadratic loss but the absolute and zero-one loss functions. It can be taken from the updated mean parameter of the posterior distribution (Eq.\ref{eq:posterior_distribution}) which, after some algebra, can be expressed as

$$
    \hat{\boldsymbol{\theta}}_{i,t}=\operatorname{E}[\boldsymbol\theta_{i,t}|\mathbf{x}_{i,t}]=\boldsymbol\Sigma_{i,t}\left(\boldsymbol\Sigma_{i,t}+\mathbf{S}_{i,t}\right)^{-1}\mathbf{m}_{i,t} +
    \mathbf{S}_{i,t}\left(\boldsymbol\Sigma_{i,t}+\mathbf{S}_{i,t}\right)^{-1}\mathbf{x}_{i,t}.
$$

The estimator value for the logit vector $\hat{\boldsymbol\theta}_{i,t}$ is a weighted combination of the original logit vector $\mathbf{x}_{i,t}$ and the neighborhood mean vector $\mathbf{m}_{i,t}$. The weights are given by the covariance matrix $\mathbf{S}_{i,t}$ of the prior distribution and the covariance matrix of the conditional distribution. The matrix $\mathbf{S}_{i,t}$ is calculated considering the spatiotemporal neighbors and the matrix $\boldsymbol\Sigma_{i,t}$ corresponds to the smoothing factor provided as prior belief by the user. 

When the values of local class covariance $\mathbf{S}_{i,t}$ are relative to the conditional covariance $\boldsymbol\Sigma_{i,t}$, our confidence on the influence of the neighbors is low, and the smoothing algorithm gives more weight to the original pixel value $x_{i,k}$. When the local class covariance $\mathbf{S}_{i,t}$ decreases relative to the smoothness factor $\boldsymbol\Sigma_{i,t}$, then our confidence on the influence of the neighborhood increases. The smoothing procedure will be most relevant in situations where the original classification odds ratio is low, showing a low level of separability between classes. In these cases, the updated values of the classes will be influenced by the local class variances. 

In practice, $\boldsymbol\Sigma_{i,t}$ is a user-controlled covariance matrix parameter that will be set by users based on their knowledge of the region to be classified. In the simplest case, users can associate the  conditional covariance $\boldsymbol\Sigma_{i,t}$ to a diagonal matrix, using only one hyperparameter $\sigma^2_k$ to set the level of smoothness. Higher values of $\sigma^2_k$ will cause the assignment of the local mean to the pixel updated probability. In our case, after some classification tests, we decided to $\sigma^2_k=20$ by default for all $k$. 

## Use of Bayesian smoothing in SITS

Doing post-processing using Bayesian smoothing in SITS is straightforward. The result of the `sits_classify` function applied to a data cube is set of probability images, one per class. The next step is to apply the `sits_smooth` function. By default, this function selects the most likely class for each pixel considering only the probabilities of each class for each pixel. To allow for Bayesian smoothing, it suffices to include the `type = bayesian` parameter (which is also the default). If desired, the `smoothness` parameter (associated to the hyperparameter $\sigma^2_k$ described above) can control the degree of smoothness. If so desired, the `smoothness` parameter can also be expressed as a matrix




\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{09-smoothing_files/figure-latex/unnamed-chunk-3-1} 

}

\caption{Probability values for classified image}(\#fig:unnamed-chunk-3)
\end{figure}

The plots show the class probabilities, which can then be smoothed by a bayesian smoother.

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{09-smoothing_files/figure-latex/unnamed-chunk-4-1} 

}

\caption{Probability values smoothed by bayesian method}(\#fig:unnamed-chunk-4)
\end{figure}

The bayesian smoothing has removed some of local variability associated to misclassified pixels which are different from their neighbors. The impact of smoothing is best appreciated comparing the labelled map produced without smoothing to the one that follows the procedure, as shown below.

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth]{09-smoothing_files/figure-latex/unnamed-chunk-5-1} 

}

\caption{Classified image without smoothing}(\#fig:unnamed-chunk-5)
\end{figure}

The resulting labelled map shows a number of likely misclassified pixels which can be removed using the bayesian smoother. 

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth]{09-smoothing_files/figure-latex/unnamed-chunk-6-1} 

}

\caption{Classified image with Bayesian smoothing}(\#fig:unnamed-chunk-6)
\end{figure}

Comparing the two plots, it is apparent that the smoothing procedure has reduced a lot of the noise in the original classification and produced a more homogeneous result. 

## Bilateral smoothing 

One of the problems with post-classification smoothing is that we would like to remove noisy pixels (e.g., a pixel with high probability of being labeled "Forest" in the midst of pixels likely to be labeled "Cerrado"), but would like to preserve the edges between areas. Because of its design, bilateral filter has proven to be a useful method for post-classification processing since it preserves edges while removing noisy pixels [@Schindler2012].

Bilateral smoothing combines proximity (combining pixels which are close) and similarity (comparing the values of the pixels) [@Tomasi1998]. If most of the pixels in a neighborhood have similar values, it is easy to identify outliers and noisy pixels. In contrast, there is a strong difference between the values of pixels in a if neighborhood, it is possible that the pixel is located in a class boundary. Bilateral filtering combines domain filtering with range filtering. In domain filtering, the weights used to combine pixels decrease with distance. In range filtering, the weights are computed considering value similarity. 

The combination of domain and range filtering is mathematically expressed as: 

$$
S(x_i) = \frac{1}{W_{i}} \sum_{x_k \in \theta} I(x_k)\mathcal{N}_{\tau}(\|I(x_k) - I(x_i)\|)\mathcal{N}_{\sigma}(\|x_k - x_i\|),
$$
where

- $S(x_i)$  is the smoothed value of pixel $i$;
- $I$ is the original probability image to be filtered;
- $I(x_i)$ is the value of pixel $i$;
- $\theta$ is the neighborhood centered in $x_i$;
- $x_k$ is a pixel $k$ which belongs to neighborhood $\theta$;
- $I(x_k)$ is the value of a pixel $k$ in the neighborhood of pixel $i$;
- $\|I(x_k) - I(x_i)\|$ is the absolute difference between the values of the pixel $k$ and pixel $i$;
- $\|x_k - x_i\|$ is the distance between pixel $k$ and pixel $i$;
- $\mathcal{N}_{\tau}$ is the Gaussian range kernel for smoothing differences in intensities;
- $\mathcal{N}_{\sigma}$is the Gaussian spatial kernel for smoothing differences based on proximity.
- $\tau$ is the variance of the Gaussian range kernel;
- $\sigma$ is the variance of the Gaussian spatial kernel.

The normalization term to be applied to compute the smoothed values of pixel $i$ is defined as

$$
W_{i} = \sum_{x_k \in \theta}{\mathcal{N}_{\tau}(\|I(x_k) - I(x_i)\|)\mathcal{N}_{\sigma}(\|x_k - x_i\|)}
$$



For every pixel, the method takes a considers two factors: the distance between the pixel and its neighbors, and the difference in value between them. Each of the values contributes according to a Gaussian kernel. These factors are calculated independently. Big difference between pixel values reduce the influence of the neighbor in the smoothed pixel. Big distance between pixels also reduce the impact of neighbors. The achieve a satisfactory result, we need to balance the $\sigma$ and $\tau$. As a general rule, the values of $\tau$ should range from 0.05 to 0.50, while the values of $\sigma$ should vary between 4 and 16[@Paris2007]. The default values adopted in *sits* are `tau = 0.1` and `sigma = 8`. As the best values of $\tau$  and $\sigma$ depend on the variance of the noisy pixels, users are encouraged to experiment and find parameter values that best fit their requirements.

The following example shows the behavior of the bilateral smoother.

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{09-smoothing_files/figure-latex/unnamed-chunk-7-1} 

}

\caption{Probability values for classified image smoothed by bilateral filter}(\#fig:unnamed-chunk-7)
\end{figure}

The impact on the classified image can be seen in the following example.

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth]{09-smoothing_files/figure-latex/unnamed-chunk-8-1} 

}

\caption{Classified image with bilateral smoothing}(\#fig:unnamed-chunk-8)
\end{figure}

Bayesian smoothing tends to produce more homogeneous labeled images than bilateral smoothing. However, some spatial details and some edges are better preserved by the bilateral method. Choosing between the methods depends on user needs and requirements. In any case, as stated by @Schindler2012, smoothing improves the quality of classified images and thus should be applied in most situations.
