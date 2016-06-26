#!/bin/bash

#####################################################################################
## New private registry - edit this script as needed to create a private certificate# 
## and an initial auth file for the new registry.  Be sure to edit the host name    #
## bld.lab and user name and password to match your requirements.                   #
##                                                                                  #
## Anthony Macey - TMD Associates                                                   #
#####################################################################################

docker run --entrypoint htpasswd registry:2 -Bbn build manager >> auth/htpasswd

openssl genrsa -aes256 -passout pass:foobar -out ./certs/bld.lab.key.protected 2048 

openssl req \
    -new \
    -passout pass:foobar\
    -passin pass:foobar\
    -days 365 \
    -subj "/C=GB/ST=Herts/L=London/O=TMD Associates Limited/CN=bld.lab" \
    -key ./certs/bld.lab.key.protected\
    -out ./certs/bld.lab.csr

openssl rsa -in ./certs/bld.lab.key.protected -out ./certs/bld.lab.key\
    -passout pass:foobar\
    -passin pass:foobar

openssl x509 -req -days 365 -in ./certs/bld.lab.csr -signkey ./certs/bld.lab.key -out ./certs/bld.lab.crt

