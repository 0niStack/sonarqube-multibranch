ARG COMMUNITY_BRANCH_PLUGIN_VERSION=26.5.0
ARG SONARQUBE_VERSION=26.5-community

# ---------------------------------------------------------
# Download Community Branch Plugin
# ---------------------------------------------------------
FROM alpine:3.23 AS downloader

ARG COMMUNITY_BRANCH_PLUGIN_VERSION

RUN apk add --no-cache curl unzip

RUN mkdir -p /plugin /web

# Download plugin JAR
RUN curl -fL \
      "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${COMMUNITY_BRANCH_PLUGIN_VERSION}/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_PLUGIN_VERSION}.jar" \
      -o /plugin/sonarqube-community-branch-plugin.jar

# Download modified SonarQube web application
RUN curl -fL \
      "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${COMMUNITY_BRANCH_PLUGIN_VERSION}/sonarqube-webapp.zip" \
      -o /tmp/sonarqube-webapp.zip \
    && unzip /tmp/sonarqube-webapp.zip -d /web \
    && rm /tmp/sonarqube-webapp.zip


# ---------------------------------------------------------
# SonarQube
# ---------------------------------------------------------
FROM sonarqube:${SONARQUBE_VERSION}

USER root

# Remove original SonarQube web application
RUN rm -rf /opt/sonarqube/web/*

# Install plugin
COPY --from=downloader \
    --chown=sonarqube:root \
    /plugin/sonarqube-community-branch-plugin.jar \
    /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar

# Install modified web application
COPY --from=downloader \
    --chown=sonarqube:root \
    /web \
    /opt/sonarqube/web

# Set correct permissions
RUN chmod -R 755 /opt/sonarqube/web

USER sonarqube

# Required by newer plugin versions
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar=web"

ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar=ce"
