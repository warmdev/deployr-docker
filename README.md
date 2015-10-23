## Dockerfile for DeployR Open

### Version information

* DeployR Open 7.4.1
* JDK 8u65
* RRO 3.2.2

### Before building

* Please ensure that you have at least 6GB of free space, otherwise you may encounter problems during the building process (`mongod` process not found) or when running (main page showing `404` error).
 
### Usage

```
git clone https://github.com/warmdev/deployr-docker.git
cd deployr-docker
sudo docker build -t deployr .
sudo docker run -d -p 7400:7400 -p 7406:7406 deployr
```

* For Linux users, server will be live at `http://localhost:7400/revolution`

### Special instructions for `Docker Toolbox` users

* Before building
    - Uncomment line 5 in `startAll.sh`
* Usage

```
git clone https://github.com/warmdev/deployr-docker.git
cd deployr-docker
docker build -t deployr .
docker run -d -p 7400:7400 -p 7406:7406 deployr
```

* For `Docker Toolbox` users, server will be live at `http://192.168.99.100:7400/revolution`

### Default password

* Default admin user is `admin` and password is `changeme`

### Changes to the sh files

The `sh` files are from the `DeployR Open` source package with the following modifications:

* `installDeployROpen.sh`: removed the `restart` section so that server will not run in the docker building process
* `startAll.sh`: added support for `Docker Toolbox`, changed Tomcat Server to non-daemon mode
