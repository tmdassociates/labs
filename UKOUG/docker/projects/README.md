# Oracle Docker Images Project

This guide is based on works by [Bruno Borges](https://github.com/brunoborges) of Oracle Corporation at this [GitHub repository](https://github.com/oracle/docker-images), please make sure that you respect the Oracle licence terms and refrain from uploading your Docker images to the public cloud.

# Create the WebLogic Images

This section refers to projects directory, we need to copy the files [server-jre-8u91-linux-x64.tar.gz](http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html) and [fmw_12.2.1.0.0_wls_Disk1_1of1.zip](http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-main-097127.html) into the `jdk` and `weblogic/12.2.1` directories respectively. This is Oracle’s way of making sure you accept their licence terms when you download the software installs. Create the base Oracle containers by providing the following commands in the jdk and weblogic directories.
````
[builder@bld jdk]$ ./build.sh
[builder@bld weblogic]$ ./buildDockerImage.sh -g -v 12.2.1
````
Executing the `docker images` command should show the following images `oracle/jdk` and `oracle/weblogic`. These are the exact same images that you will get if you follow the Oracle documentation. In order to push these images to the private registry they need to be tagged with the `docker tag` command.  It is a good idea to give the images a sensible name, the pre-fix must be the host and port of your private registry. 
````
docker tag oracle/jdk:8 bld.lab:5000/jdk:8
docker tag oracle/weblogic:12.2.1-generic bld.lab:5000/weblogic:12.2.1
````
Once the images are tagged you should be able to see aliases for the Docker images, these aliases can then be used to push the images to your private registry. You are now in a position to initiate a push `docker push bld.lab:5000/jdk:8`, you will see the various layers get uploaded to the registry. It is important to note that you can initiate this push from any host in which there is a trust relationship.
````
[builder@bld projects]$ docker push bld.lab:5000/jdk:8
The push refers to a repository [bld.lab:5000/jdk]
024af6e2997d: Pushing [===>                                   ]  9.81 MB/157 MB
4f826e877914: Pushing [===>                                   ] 10.88 MB/157 MB
5f70bf18a086: Pushed
72062da526a: Pushing [=>                                      ] 6.585 MB/276.1 MB
````
You will notice layers in action when you push the WebLogic image `docker push bld.lab:5000/weblogic:12.2.1`, because the jdk image is already uploaded to the registry and the WebLogic image is based on that layer, it only uploads the new layer information to the registry.
````
The push refers to a repository [bld.lab:5000/weblogic]
ab6a0fcb80bc: Pushing [==============================>         ] 470.9 MB/781.5 MB
47d4c35cb811: Pushed
024af6e2997d: Mounted from jdk
4f826e877914: Mounted from jdk
5f70bf18a086: Pushed
472062da526a: Pushing [=======================================>] 285.3 MB
````
OK, so that is the official Oracle images built, tagged and uploaded to the registry. Next the domain image is created and pushed. In the domain directory edit the FROM section of the Dockerfile to refer to your registry version of the WebLogic image `bld.lab:5000/weblogic:12.2.1`, then execute the build command `docker build -t bld.lab:5000/domain:1 --build-arg ADMIN_PASSWORD=welcome1`. This will build and label our new image and set the console admin password.
````
[builder@bld Domain]$ vi Dockerfile
FROM bld.lab:5000/weblogic:12.2.1
````
````
[builder@bld Domain]$ docker build -t bld.lab:5000/domain:1 --build-arg ADMIN_PASSWORD=welcome1 .
Sending build context to Docker daemon  25.6 kB
Step 1 : FROM bld.lab:5000/weblogic:12.2.1
 ---> 8125801d4706
````
The docker images command should show a new image `bld.lab:5000/domain:1`. There is no need to tag it as it is already tagged with our registry details. When we push `docker push bld.lab:5000/domain:1` this new image will be quick to upload because it is only adding the configuration scripts that have been added in the `container-scripts` directory that allow us to easily manipulate our containerised version of WebLogic. 

# Create a Deployed WebLogic Application

This section extends our base containers to create a container with a data source that deploys a sample web application. For the application to work correctly it needs to point at the SOE schema and the SOE user must have `SELECT_CATALOG_ROLE` as it uses some `v$ views` to determine the database version.

In the `application/container-scripts` directory, edit the file datasource.properties to reflect the location of the SOE schema. The JNDI name must be `jdbc/SOE` because this is what the sample application `sample.war` looks for. The `dsusername/dspassword` values are case sensitive.
````
[builder@bld container-scripts]$ vi datasource.properties
dsname=DockerDS
dsjndiname=jdbc/SOE
dsdriver=oracle.jdbc.OracleDriver
dsurl=jdbc:oracle:thin:@oracle2.lab:1521/LAB2
dsusername=soe
dspassword=soe
dstestquery=SQL SELECT 1 FROM DUAL
dsmaxcapacity=5
````
Once the data source information is configured from the application directory execute the `docker build -t bld.lab:5000/webapp:1`. command to create the image. What happens is that the contents of the directory container-scripts are copied into the container, and the following scripts are executed `wlst -loadProperties /u01/oracle/datasource.properties /u01/oracle/ds-deploy.py` This creates the data source the sample application needs, then `wlst /u01/oracle/app-deploy.py` deploys the application to the server. It is worth noting that the script does not quite work, the default values in `app-deploy.py` do not get overridden by the environment variables. The image can then be pushed to the registry `docker push bld.lab:5000/webapp:1`. Finally edit the `docker-compose.yml` file that is in the root of the application folder to reflect your registry host and build host.
````
[builder@bld application]$ vi docker-compose.yml

webapp:
  restart: always
  image: bld.lab:5000/webapp:1
  ports:
    - bld.lab:8001:8001
````
Next test the application first with the foreground version of the `docker-compose` command `docker-compose up`. This will enable you to quickly diagnose any errors and faults. If there is a `jax-rs` error reported, this is an error in the base domain creation that can be ignored. When tested the command `docker-compose up -d` can be used to daemonise the container, because the compose file contains the command `restart: always` the WebLogic server will restart after a reboot or failure. We can tail the WebLogic server logs with the following commands to the Docker service `docker logs -f application_webapp_1`. What is happening inside the container is that the WebLogic start script is running in the foreground, which is consequently captured by the Docker logging process and can be interrogated with the command `docker logs`. The running server can be stopped and removed again with the command `docker-compose down` or simply stopped with the command `docker-compose stop`.

