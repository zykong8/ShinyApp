FROM rocker/shiny:4.3.3

LABEL maintainer "Xiao Fei & myvictory@126.com"

# Editing mirrors
RUN sed -i 's#http://security.ubuntu.com/ubuntu/#http://mirrors.aliyun.com/ubuntu/#' /etc/apt/sources.list
RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#http://mirrors.aliyun.com/ubuntu/#' /etc/apt/sources.list

# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly).
RUN useradd docker && mkdir /home/docker && chown docker:docker /home/docker \
    && addgroup docker staff

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN apt-get update \
    && apt-get install -yq --no-install-recommends software-properties-common ed \
    && apt-get install -yq less locales vim wget ca-certificates fonts-texgyre \
    && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Configure Timezone
ENV TZ=Asia/Shanghai DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -yq tzdata \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# Basic configure
RUN apt-get update \
    && apt-get install -yq gcc cmake libcurl4-openssl-dev libxml2 libxml2-dev curl \
    && apt-get install -yq libcairo2-dev libssl-dev git g++ sudo gdebi-core pandoc \
    && apt-get install -yq pandoc-citeproc libcurl4-gnutls-dev libcairo2-dev xtail \
    && apt-get install -yq apt-utils software-properties-common gfortran libxt-dev \
    && apt-get install -yq locales unzip dos2unix sudo build-essential libxml++2.6-dev \
    && apt-get install -yq libncurses5-dev libgdbm-dev libnss3-dev zlib1g-dev \
    && apt-get install -yq libreadline-dev libffi-dev openjdk-8-jdk libfribidi-dev \
    && apt-get install -yq libwww-perl libcurl4-gnutls-dev libexpat1-dev libtiff-dev \
    && apt-get install -yq libgeos-dev libnode-dev \
    && rm -rf /var/lib/apt/lists/*


# Install python
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz \
	&& tar -zxf Python-3.10.0.tgz
WORKDIR /Python-3.10.0
RUN ./configure && make altinstall && make install \
	&& ln -s /usr/local/bin/python3 /usr/local/bin/python
RUN wget https://bootstrap.pypa.io/get-pip.py \
	&& python3 get-pip.py \
	&& pip3 install --upgrade pip \
	&& pip3 install setuptools

# Install dependencies of shiny
RUN R -e "install.packages(c('shinydashboard', 'shinyjs', 'V8'))"

# Install Seurat`s system dependencies
RUN apt-get update && apt-get install -yq libhdf5-dev libpng-dev libboost-all-dev libfftw3-dev libgsl-dev llvm-11
# Install UMAP
RUN LLVM_CONFIG=/usr/lib/llvm-11/bin/llvm-config pip3 install llvmlite
RUN pip3 install numpy umap-learn -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host=mirrors.aliyun.com/pypi/simple

# Install FIt-SNE
RUN git clone  https://github.com/KlugerLab/FIt-SNE.git
RUN g++ -std=c++11 -O3 FIt-SNE/src/sptree.cpp FIt-SNE/src/tsne.cpp FIt-SNE/src/nbodyfft.cpp  -o FIt-SNE/bin/fast_tsne -pthread -lfftw3 -lm -Wno-address-of-packed-member

# For dependences of devtools
RUN apt-get update && apt-get install -y libharfbuzz-dev libfribidi-dev \
	glpk-utils libglpk-dev glpk-doc
# For remotes
RUN R --no-echo --no-restore --no-save -e "install.packages('remotes')"

# Install bioconductor dependencies & suggests
RUN R --no-echo --no-restore --no-save -e "install.packages('BiocManager')"
RUN R --no-echo --no-restore --no-save -e "BiocManager::install(c('multtest', 'S4Vectors', 'SummarizedExperiment', 'SingleCellExperiment', 'MAST', 'DESeq2', 'BiocGenerics', 'GenomicRanges', 'IRanges', 'rtracklayer', 'monocle', 'Biobase', 'limma', 'glmGamPoi'))"
RUN R --no-echo --no-restore --no-save -e "install.packages(c('VGAM', 'R.utils', 'metap', 'Rfast2', 'ape', 'enrichR', 'mixtools'))"
RUN R --no-echo --no-restore --no-save -e "install.packages(c('hdf5r', 'devtools'))"

# Install Seurat
RUN R --no-echo --no-restore --no-save -e "install.packages('https://cran.r-project.org/src/contrib/Archive/SeuratObject/SeuratObject_4.1.4.tar.gz', repos=NULL, type='source')"
COPY seurat-v440 /soft/seurat-v440 
RUN R --no-echo --no-restore --no-save -e "devtools::install_local('/soft/seurat-v440')"

# Install slingshot
RUN R --no-echo --no-restore --no-save -e "BiocManager::install('kstreet13/slingshot')"