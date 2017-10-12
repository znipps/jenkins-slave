FROM ubuntu:xenial

MAINTAINER Bilal Sheikh <bilal@techtraits.com>

# change to aliyun
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial main multiverse restricted universe" > /etc/apt/sources.list && \
        echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main multiverse restricted universe" >> /etc/apt/sources.list && \
        echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main multiverse restricted universe" >> /etc/apt/sources.list && \
        echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-security main multiverse restricted universe" >> /etc/apt/sources.list && \
        echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main multiverse restricted universe" >> /etc/apt/sources.list && \
        echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial main multiverse restricted universe" >> /etc/apt/sources.list && \
        echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main multiverse restricted universe" >> /etc/apt/sources.list && \
        echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main multiverse restricted universe" >> /etc/apt/sources.list && \
        echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main multiverse restricted universe" >> /etc/apt/sources.list && \
        echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main multiverse restricted universe" >> /etc/apt/sources.list

RUN apt-get update && apt-get -y upgrade && apt-get -y install software-properties-common && add-apt-repository ppa:webupd8team/java -y && apt-get update

RUN (echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections) && apt-get install -y oracle-java8-installer oracle-java8-set-default

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV PATH $JAVA_HOME/bin:$PATH


# apparmor is required to run docker server within docker container
RUN apt-get update -qq && apt-get install -qqy wget curl git iptables ca-certificates apparmor

ENV JENKINS_SWARM_VERSION 3.5
ENV HOME /home/jenkins-slave


RUN useradd -c "Jenkins Slave user" -d $HOME -m jenkins-slave
RUN curl --create-dirs -sSLo $HOME/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$JENKINS_SWARM_VERSION/swarm-client-$JENKINS_SWARM_VERSION.jar
ADD cmd.sh /cmd.sh

# set our wrapper
ENTRYPOINT ["/usr/local/bin/docker-wrapper"]

# setup our local files first
ADD docker-wrapper.sh /usr/local/bin/docker-wrapper
RUN chmod +x /usr/local/bin/docker-wrapper

# now we install docker in docker - thanks to https://github.com/jpetazzo/dind
# We install newest docker into our docker in docker container
RUN curl -fsSLO https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz \
  && tar --strip-components=1 -xvzf docker-latest.tgz -C /usr/local/bin \
  && chmod +x /usr/local/bin/docker \
#RUN curl https://releases.rancher.com/install-docker/1.13.sh | sh
# install Rancher CLI
  && curl -fsSLO https://github.com/rancher/cli/releases/download/v0.4.1/rancher-linux-amd64-v0.4.1.tar.gz \
  && tar --strip-components=2 -xzvf rancher-linux-amd64-v0.4.1.tar.gz -C /usr/local/bin \
  && chmod +x /usr/local/bin/rancher

# now we install docker compose
#RUN curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose \
#  && chmod +x /usr/local/bin/docker-compose

VOLUME /var/lib/docker

#ENV JENKINS_USERNAME jenkins
#ENV JENKINS_PASSWORD jenkins
#ENV JENKINS_MASTER http://jenkins:8080

CMD /bin/bash /cmd.sh
