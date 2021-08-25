FROM rocker/tidyverse:4.0.3
  
RUN install2.r --error \
      --deps TRUE \
      caTools                

RUN mkdir /home/rstudio/library && chown rstudio:rstudio /home/rstudio/library && echo ".libPaths(c('/home/rstudio/library'))" >> /usr/local/lib/R/library/base/R/Rprofile

RUN R -e 'install.packages("BiocManager")'