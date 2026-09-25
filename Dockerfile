ARG SONARQUBE_VERSION=26.5.0.122743-community
ARG COMMUNITY_BRANCH_PLUGIN_VERSION=26.5.0

# =========================================================
# Downloader
# =========================================================
FROM alpine:3.23 AS downloader

ARG COMMUNITY_BRANCH_PLUGIN_VERSION

ENV PLUGIN_VERSION=${COMMUNITY_BRANCH_PLUGIN_VERSION}

RUN apk add --no-cache curl unzip

RUN mkdir -p /plugin /web

# =========================================================
# Download Community Branch Plugin JAR
# =========================================================

RUN echo "Downloading Community Branch Plugin ${PLUGIN_VERSION}"

RUN curl -fL \
    "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar" \
    -o /plugin/sonarqube-community-branch-plugin.jar

# =========================================================
# Download modified SonarQube WebApp
# =========================================================

RUN echo "Downloading SonarQube WebApp ${PLUGIN_VERSION}"

RUN curl -fL \
    "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-webapp.zip" \
    -o /tmp/sonarqube-webapp.zip

RUN unzip /tmp/sonarqube-webapp.zip -d /web


# =========================================================
# SonarQube
# =========================================================

FROM sonarqube:${SONARQUBE_VERSION}

USER root

# Remove original SonarQube WebApp
RUN rm -rf /opt/sonarqube/web/*

# Install Community Branch Plugin
COPY --from=downloader \
    --chown=sonarqube:root \
    /plugin/sonarqube-community-branch-plugin.jar \
    /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar

# Install modified WebApp
COPY --from=downloader \
    --chown=sonarqube:root \
    /web/ \
    /opt/sonarqube/web/

USER sonarqube

# Community Branch Plugin Java agents
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar=web"

ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin.jar=ce"
