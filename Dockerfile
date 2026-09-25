ARG SONARQUBE_VERSION=26.5.0.122743-community
ARG COMMUNITY_BRANCH_PLUGIN_VERSION=26.5.0

# =========================================================
# Downloader
# =========================================================
FROM alpine:3.23 AS downloader

ARG COMMUNITY_BRANCH_PLUGIN_VERSION

ENV PLUGIN_VERSION=${COMMUNITY_BRANCH_PLUGIN_VERSION}

RUN apk add --no-cache curl unzip

RUN mkdir -p /opt/sonarqube/web

# Download modified SonarQube webapp
RUN curl -fL \
    "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-webapp.zip" \
    -o /tmp/sonarqube-webapp.zip

RUN unzip /tmp/sonarqube-webapp.zip \
    -d /opt/sonarqube/web

# Download plugin JAR
RUN curl -fL \
    "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar" \
    -o /tmp/sonarqube-community-branch-plugin.jar


# =========================================================
# SonarQube
# =========================================================
FROM sonarqube:${SONARQUBE_VERSION}

USER root

# Remove original SonarQube web application
RUN rm -rf /opt/sonarqube/web/*

# Install plugin
COPY --from=downloader \
    --chown=sonarqube:root \
    /tmp/sonarqube-community-branch-plugin.jar \
    /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar

# Install modified web application
COPY --from=downloader \
    --chown=sonarqube:root \
    /opt/sonarqube/web \
    /opt/sonarqube/web

USER sonarqube

# Community Branch Plugin Java agents
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar=web"

ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar=ce"
