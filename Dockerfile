FROM centos:7

RUN yum -y update; yum clean all; yum -y install wget libicu-devel psmisc gcc-c++
WORKDIR /opt/
RUN wget --no-cookies --no-check-certificate --header \
        "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
        "http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.tar.gz"; \
    tar xzf jdk-8u65-linux-x64.tar.gz; \
    alternatives --install /usr/bin/java java /opt/jdk1.8.0_65/bin/java 2; \
    alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_65/bin/jar 2; \
    alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_65/bin/javac 2; \
    alternatives --set jar /opt/jdk1.8.0_65/bin/jar; \
    alternatives --set javac /opt/jdk1.8.0_65/bin/javac; \
    rm -rf jdk-8u65-linux-x64.tar.gz

RUN wget https://mran.revolutionanalytics.com/install/RRO-3.2.2.el7.x86_64.rpm; \
    yum install -y RRO-3.2.2.el7.x86_64.rpm; rm -rf RRO-3.2.2.el7.x86_64.rpm
RUN sed -i "4s/.*/R_HOME_DIR=\/usr\/lib64\/RRO-3.2.2\/R-3.2.2\/lib64\/R/g" /usr/lib64/RRO-3.2.2/R-3.2.2/lib64/R/bin/R

RUN wget https://github.com/deployr/deployr-rserve/releases/download/v7.4.1/deployrRserve_7.4.1.tar.gz; \
    R CMD INSTALL deployrRserve_7.4.1.tar.gz; \
    rm -rf deployrRserve_7.4.1.tar.gz
RUN adduser deployr
USER deployr
WORKDIR /home/deployr/
RUN mkdir download; \
    wget http://deployr.revolutionanalytics.com/download/bundles/release/DeployR-Open-Linux-7.4.1.tar.gz -P download; \
    cd download && tar xzf DeployR-Open-Linux-7.4.1.tar.gz
ADD installDeployROpen.sh download/installFiles/
USER root
RUN chown deployr:deployr download/installFiles/installDeployROpen.sh
USER deployr
RUN cd download/installFiles/ && export JAVA_HOME=/opt/jdk1.8.0_65/ && chmod +x installDeployROpen.sh && sync && ./installDeployROpen.sh --no-ask --nolicense
ADD startAll.sh deployr/7.4.1/
ADD init.sh deployr/7.4.1/
USER root
RUN chown deployr:deployr deployr/7.4.1/startAll.sh deployr/7.4.1/init.sh
USER deployr
RUN chmod +x deployr/7.4.1/startAll.sh deployr/7.4.1/init.sh && sync
RUN rm -rf download

EXPOSE 7400 7406

CMD cd deployr/7.4.1/ && ./startAll.sh
