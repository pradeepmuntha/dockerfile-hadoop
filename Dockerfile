#
# Dockerfile - Apache Hadoop
#
# based on ruo91's dockerfile : https://github.com/ruo91/docker-hadoop
#
FROM       ubuntu:14.04
MAINTAINER Larry SU <larrysu1115@gmail.com>

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      supervisor \
      openssh-server \
      net-tools \
      iputils-ping \
      telnet \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install all to /opt/*
ENV OPT_DIR /opt

# timezone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Java
ENV JAVA_HOME /opt/jdk
ENV PATH $PATH:$JAVA_HOME/bin
RUN cd $OPT_DIR \
    && curl -SL -k "http://download.oracle.com/otn-pub/java/jdk/8u66-b17/jdk-8u66-linux-x64.tar.gz" -b "oraclelicense=a" \
    |  tar xz \
    && ln -s /opt/jdk1.8.0_66 /opt/jdk \
    && rm -f /opt/jdk/*src.zip \
    && echo '' >> /etc/profile \
    && echo '# JDK' >> /etc/profile \
    && echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile \
    && echo 'export PATH="$PATH:$JAVA_HOME/bin"' >> /etc/profile \
    && echo '' >> /etc/profile

# Hadoop
ENV HADOOP_URL http://www.eu.apache.org/dist/hadoop/common
ENV HADOOP_VERSION 2.7.1
RUN cd $OPT_DIR \
    && curl -SL -k "$HADOOP_URL/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
    |  tar xz \
    && ln -s /opt/hadoop-$HADOOP_VERSION /opt/hadoop \
    && rm -Rf /opt/hadoop/share/doc

ENV HADOOP_PREFIX $OPT_DIR/hadoop
ENV PATH $PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin
ENV HADOOP_MAPRED_HOME $HADOOP_PREFIX
ENV HADOOP_COMMON_HOME $HADOOP_PREFIX
ENV HADOOP_HDFS_HOME $HADOOP_PREFIX
ENV YARN_HOME $HADOOP_PREFIX
RUN echo '# Hadoop' >> /etc/profile \
    && echo "export HADOOP_PREFIX=$HADOOP_PREFIX" >> /etc/profile \
    && echo 'export PATH=$PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin' >> /etc/profile \
    && echo 'export HADOOP_MAPRED_HOME=$HADOOP_PREFIX' >> /etc/profile \
    && echo 'export HADOOP_COMMON_HOME=$HADOOP_PREFIX' >> /etc/profile \
    && echo 'export HADOOP_HDFS_HOME=$HADOOP_PREFIX' >> /etc/profile \
    && echo 'export YARN_HOME=$HADOOP_PREFIX' >> /etc/profile

# SSH keygen
RUN cd /root && ssh-keygen -t dsa -P '' -f "/root/.ssh/id_dsa" \
    && cat /root/.ssh/id_dsa.pub >> /root/.ssh/authorized_keys \
    && chmod 644 /root/.ssh/authorized_keys 

# Daemon supervisord
RUN mkdir -p /var/log/supervisor
ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Daemon SSH 
RUN mkdir /var/run/sshd \
    && sed -i 's/without-password/yes/g' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config \
    && echo '    StrictHostKeyChecking no' >> /etc/ssh/ssh_config \
    && echo 'SSHD: ALL' >> /etc/hosts.allow

# Root password
RUN echo 'root:hadoop' | chpasswd

# Port
# Node Manager: 8042, Resource Manager: 8088, NameNode: 50070, DataNode: 50075, SecondaryNode: 50090
EXPOSE 22 8042 8088 50070 50075 50090

# Daemon
CMD ["/usr/bin/supervisord"]
