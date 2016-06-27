# Create Your Own Private Registry

Due to the proprietary nature of Oracle’s WebLogic software it is advisable to have your own local Docker registry rather than using the public Docker hub that has all sorts of legal implications. This section describes how to use the files in the registry directory location to create your own registry.

First you will need to edit the `seed.sh` file and edit the file to suit your setup, mainly hostnames and users. Once ran `./seed.sh` will create a private self-signed SSL certificate to provide encryption between your hosts and registry. It will also create a htpasswd file to store usernames and hashed passwords inside the registry.

````
#!/bin/bash

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
````

The next file you will need to modify is the `docker-compose.yml` file. Again you will need to modify the hostname but everything else can remain the same.

````
registry:
  restart: always
  image: registry:2
  ports:
    - bld.lab:5000:5000
  environment:
    REGISTRY_HTTP_TLS_CERTIFICATE: /certs/bld.lab.crt
    REGISTRY_HTTP_TLS_KEY: /certs/bld.lab.key
    REGISTRY_AUTH: htpasswd
    REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
    REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
  hostname: bld.lab
  volumes:
    - ./data:/var/lib/registry
    - ./certs:/certs
    - ./auth:/auth
````

The registry server can now be started in the background with the following command `docker-compose up -d`. The registry image will then be pulled and started, the -d option simply detaches the container into the background. 

Install the certificates on hosts you want to talk to the Docker registry.

````bash
sudo mkdir -p /etc/docker/certs.d/bld.lab:5000/
sudo cp ./certs/bld.lab.crt /etc/docker/certs.d/bld.lab:5000/
````

You can then test the login to the registry `docker login -u build -p manager bld.lab:5000` ready to distribute your containers. If you see any errors regarding certificates, it is likely that there is a problem with the certificate creation or installation, it is worth revisiting the creation of the certificates and reinstalling them. The `docker ps` command should show that the registry is running and `docker logs registry_registry_1` will show the console output for the registry server.
