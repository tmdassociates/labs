# LICENSE CDDL 1.0 + GPL 2.0
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.

FROM bld.lab:5000/domain:1 

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

# Define variables
ENV APP_NAME="sample" \
    APP_PKG_FILE="sample.war" \
    APP_PKG_LOCATION="/u01/oracle"

# Copy files and deploy application in WLST Offline mode
COPY container-scripts/* /u01/oracle/

RUN wlst -loadProperties /u01/oracle/datasource.properties /u01/oracle/ds-deploy.py 

RUN wlst /u01/oracle/app-deploy.py
