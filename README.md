## Dockerfile for DeployR Open

### Version information

This Dockerfile works with DeployR Open 7.4.1

### Before building

* If you use this with `Docker Toolbox`, uncomment line 5 in `startAll.sh`. 
 
### Usage

```
git clone https://github.com/warmdev/deployr-docker.git
cd deployr-docker
docker build -t deployr .
docker run -d -p 7400:7400 deployr
```

* For `Docker Toolbox` user, server will be live at `http://192.168.99.100:7400/revolution`
* For Linux user, add `sudo` before the `docker` commands above. Server will be live at `http://localhost:7400/revolution`

### Default password

* Default admin user is `admin` and password is `changeme`

### Changes to the sh files

The `sh` files are from the `DeployR Open` source package with the following modifications:

* `installDeployROpen.sh`: removed the `restart` section so that server will not run in the docker building process
* `startAll.sh`: added support for `Docker Toolbox`, changed Tomcat Server to non-daemon mode