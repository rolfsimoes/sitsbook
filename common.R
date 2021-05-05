set.seed(123)

knitr::opts_chunk$set(
    comment = "#>",
    echo = TRUE,
    cache = TRUE,
    fig.retina = 0.8, # figures are either vectors or 300 dpi diagrams
    dpi = 300,
    out.width = "70%",
    fig.width = 6,
    fig.align = 'center',
    fig.asp = 0.618,  # 1 / phi
    fig.show = "hold"
)

# load essentials packages
library(tibble)
library(sits)
library(sitsdata)
library(dtwclust)
library(magrittr)
library(distill)
