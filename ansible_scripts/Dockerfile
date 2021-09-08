FROM rocker/tidyverse:4.0.3

RUN chmod a+w /var/lib/rstudio-server \
     && mkdir /home/rstudio/library \
     && echo '.libPaths(c("/home/rstudio/library")' >> /usr/local/lib/R/library/base/R/Rprofile

RUN install2.r --error \
      --deps TRUE \
      caTools                

RUN R -e 'install.packages("BiocManager");library(BiocManager)'

