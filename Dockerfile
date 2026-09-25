ARG SONARQUBE_VERSION=26.5.0.122743-community
ARG COMMUNITY_BRANCH_PLUGIN_VERSION=26.5.0

# =========================================================
# Download Community Branch Plugin
# =========================================================
FROM alpine:3.23 AS downloader

ARG COMMUNITY_BRANCH_PLUGIN_VERSION

ENV PLUGIN_VERSION=${COMMUNITY_BRANCH_PLUGIN_VERSION}

RUN apk add --no-cache curl unzip

RUN mkdir -p /plugin /web

# Download plugin JAR
RUN curl -fL \
    "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar" \
    -o /plugin/sonarqube-community-branch-plugin.jar

# Download modified SonarQube web application
RUN curl -fL \
    "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-webapp.zip" \
    -o /tmp/sonarqube-webapp.zip

RUN unzip /tmp/sonarqube-webapp.zip -d /web


# =========================================================
# SonarQube
# =========================================================
FROM sonarqube:${SONARQUBE_VERSION}

USER root

# Remove original web application
RUN rm -rf /opt/sonarqube/web/*

# Install Community Branch Plugin
COPY --from=downloader \
    --chown=sonarqube:root \
    /plugin/sonarqube-community-branch-plugin.jar \
    /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar

# Install modified web application
COPY --from=downloader \
    --chown=sonarqube:root \
    /web \
    /opt/sonarqube/web

USER sonarqube

# Required by Community Branch Plugin
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar=web"

ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar=ce"
