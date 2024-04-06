#!/bin/bash

docker run -itd --name seurat  \
	-v /demo/shiny-server:/srv/shiny-server \
	-v /demo/shiny-log:/var/log/shiny-server \
	-p 3839:3838 scell:4.3.3_v1


# Start APP
# http://localhost:3839