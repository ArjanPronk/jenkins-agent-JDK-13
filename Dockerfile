# The MIT License
#
#  Copyright (c) 2015-2020, CloudBees, Inc. and other Jenkins contributors
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.


# Altered version of https://github.com/jenkinsci/docker-agent/blob/master/11/alpine/Dockerfile that install jdk 13 instead of 11

FROM alpine:3.15.0 as jre-build

RUN apk add --update --no-cache openjdk13-jdk openjdk13-jmods # CHANGED Altered to JDK 13

# Generate smaller java runtime without unneeded files
# for now we include the full module path to maintain compatibility
# while still saving space (approx 200mb from the full distribution)

# CHANGED replaced strip-debug with strip-java-debug-attributes
RUN jlink \
         --module-path /usr/lib/jvm/default-jvm/jmods \
         --add-modules ALL-MODULE-PATH \
         --strip-java-debug-attributes \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /javaruntime

FROM alpine:3.15.0

ARG VERSION=4.11.2
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN addgroup -g ${gid} ${group}
RUN adduser -h /home/${user} -u ${uid} -G ${group} -D ${user}
LABEL Description="This is a base image, which provides the Jenkins agent executable (slave.jar)" Vendor="Jenkins project" Version="${VERSION}"

ARG AGENT_WORKDIR=/home/${user}/agent

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apk add --update --no-cache curl bash git git-lfs musl-locales openssh-client openssl procps \
  && curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar \
  && apk del --purge curl \
  && rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar* /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"
COPY --from=jre-build /javaruntime $JAVA_HOME

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

LABEL \
    org.opencontainers.image.vendor="LinkPizza" \
    org.opencontainers.image.title="Unofficial Jenkins Agent Base Docker image modified to JDK 13 instead of 11" \
    org.opencontainers.image.description="This is a copy of the base image, which provides the Jenkins agent executable (agent.jar) modified to run JDK 13" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.url="https://linkpizza.com" \
    org.opencontainers.image.source="https://github.com/ArjanPronk/jenkins-agent-JDK-13" \
    org.opencontainers.image.licenses="MIT"