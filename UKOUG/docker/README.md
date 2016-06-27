# Pre-requisites 

The following software is needed to build the base Oracle images and to set up the Docker registry. The sample application makes use of the [SwingBench](http://dominicgiles.com/swingbench.html) tool to populate an order entry schema. The `docker-compose` command line tool is used as a replacement for docker run because it provides much more semantic clarity when defining how an image should run.  

| Software      | Information   |
| ------------- |---------------|
|Baseline docker setup | docker run hello-world |
|A git clone of the labs|git clone https://github.com/tmdassociates/labs.git|
|docker-compose 	|pip install -U docker-compose|
|Oracle Server JRE 	|server-jre-8u91-linux-x64.tar.gz|
|Oracle WebLogic 	|fmw_12.2.1.0.0_wls_Disk1_1of1.zip|
|SwingBench SOE Schema  with the select catalog role.	|grant SELECT_CATALOG_ROLE to soe;|

The following hosts were used.

|Hosts	|Description|
|---------|----------|
|s[1-2].lab |These 2 servers are testing deployment (Optional).|
|bld.lab	|This is the build server and host for the registry.|
|oracle2.lab|This is the database location for the SOE schema.|

The labs' GitHub repository has the following structure. The Docker section is divided into 2 parts: the registry creation and the Docker image projects.

````
labs
├── README.md
└── UKOUG
    └── docker
        ├── projects
        │   ├── application
        │   ├── domain
        │   ├── jdk
        │   └── weblogic
        └── registry
````


