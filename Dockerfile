ARG COMMUNITY_BRANCH_PLUGIN_VERSION=1.6.0

FROM alpine:3.20 AS downloader
ARG COMMUNITY_BRANCH_PLUGIN_VERSION
RUN apk add --no-cache curl
RUN mkdir -p /plugin && \
    curl -fL \
      "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${COMMUNITY_BRANCH_PLUGIN_VERSION}/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_PLUGIN_VERSION}.jar" \
      -o /plugin/sonarqube-community-branch-plugin.jar

FROM sonarqube:8.6.1-community
ARG COMMUNITY_BRANCH_PLUGIN_VERSION
COPY --from=downloader /plugin/sonarqube-community-branch-plugin.jar /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_PLUGIN_VERSION}.jar
COPY --from=downloader /plugin/sonarqube-community-branch-plugin.jar /opt/sonarqube/lib/common/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_PLUGIN_VERSION}.jar
# No sonar.properties / javaagent needed for this plugin version (1.6.0) —
# that mechanism was only introduced in later plugin releases (~1.9.0+).
