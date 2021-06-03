# Setup {-}

**sits** is currently available on [GitHub](https://github.com/e-sensing/sits). Thus, installing the package can be accomplished via [devtools](https://cran.r-project.org/web/packages/devtools/index.html), as presented by the code snippet below:


```r
devtools::install_github("e-sensing/sits", dependencies = TRUE)
```

## Docker images {-}

Installing the **sits** package has several dependencies that increase its installation and build time. To speed up the use of **sits** and the required dependencies in the R environment, the [Brazil Data Cube](https://github.com/brazil-data-cube) (BDC) project maintains [Docker images](https://hub.docker.com/r/brazildatacube/sits-rstudio) of the RStudio Server already configured with **sits**. The command below shows how this image can be used in Docker.


```shell
docker run --detach \
           --publish 127.0.0.1:8787:8787 \
           --name my-sits-rstudio \
           --volume ${PWD}/data:/data \
           brazildatacube/sits-rstudio:1.4.1103 
```

After the execution of above command, open the URL `http://127.0.0.1:8787` in a web browser, in order to access the RStudio:

> firefox http://127.0.0.1:8787

```To login use 'sits' as user and password.```

If you prefer a customized build of the SITS Docker images, please, visit the [sits-docker GitHub repository](https://github.com/e-sensing/sits).
