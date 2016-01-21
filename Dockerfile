FROM centos:7

RUN yum -y update; yum clean all; yum -y install which wget libicu-devel psmisc gcc-c++ zlib-devel
WORKDIR /opt/
RUN wget --no-cookies --no-check-certificate --header \
        "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
        "http://download.oracle.com/otn-pub/java/jdk/8u71-b15/jdk-8u71-linux-x64.tar.gz"; \
    tar xzf jdk-8u71-linux-x64.tar.gz; \
    alternatives --install /usr/bin/java java /opt/jdk1.8.0_71/bin/java 2; \
    alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_71/bin/jar 2; \
    alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_71/bin/javac 2; \
    alternatives --set jar /opt/jdk1.8.0_71/bin/jar; \
    alternatives --set javac /opt/jdk1.8.0_71/bin/javac; \
    rm -rf jdk-8u71-linux-x64.tar.gz

RUN wget https://mran.revolutionanalytics.com/install/mro/3.2.3/MRO-3.2.3.el7.x86_64.rpm; \
    yum install -y MRO-3.2.3.el7.x86_64.rpm; rm -rf MRO-3.2.3.el7.x86_64.rpm
RUN sed -i "4s/.*/R_HOME_DIR=\/usr\/lib64\/MRO-3.2.3\/R-3.2.3\/lib64\/R/g" /usr/lib64/MRO-3.2.3/R-3.2.3/lib64/R/bin/R

RUN wget https://github.com/deployr/deployr-rserve/releases/download/v7.4.2/deployrRserve_7.4.2.tar.gz; \
    R CMD INSTALL deployrRserve_7.4.2.tar.gz; \
    rm -rf deployrRserve_7.4.2.tar.gz
RUN adduser deployr
USER deployr
WORKDIR /home/deployr/
RUN mkdir download; \
    wget http://deployr.revolutionanalytics.com/download/bundles/release/DeployR-Open-Linux-8.0.0.tar.gz -P download; \
    cd download && tar xzf DeployR-Open-Linux-8.0.0.tar.gz
ADD installDeployROpen.sh download/installFiles/
USER root
RUN chown deployr:deployr download/installFiles/installDeployROpen.sh
USER deployr
RUN cd download/installFiles/ && export JAVA_HOME=/opt/jdk1.8.0_71/ && chmod +x installDeployROpen.sh && sync && ./installDeployROpen.sh --no-ask --nolicense
ADD startAll.sh deployr/8.0.0/
USER root
RUN chown deployr:deployr deployr/8.0.0/startAll.sh
USER deployr
RUN chmod +x deployr/8.0.0/startAll.sh && sync
RUN rm -rf download

EXPOSE 8000 8006

CMD cd deployr/8.0.0/ && ./startAll.sh
