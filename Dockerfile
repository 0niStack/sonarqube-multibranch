ARG COMMUNITY_BRANCH_PLUGIN_VERSION=1.6.0

FROM alpine:3.20 AS downloader
ARG COMMUNITY_BRANCH_PLUGIN_VERSION
RUN apk add --no-cache curl unzip
RUN mkdir -p /plugin /web && \
    curl -fL \
      "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${COMMUNITY_BRANCH_PLUGIN_VERSION}/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_PLUGIN_VERSION}.jar" \
      -o /plugin/sonarqube-community-branch-plugin.jar && \
    curl -fL \
      "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${COMMUNITY_BRANCH_PLUGIN_VERSION}/sonarqube-webapp.zip" \
      -o /tmp/sonarqube-webapp.zip && \
    unzip -q /tmp/sonarqube-webapp.zip -d /web && \
    rm -f /tmp/sonarqube-webapp.zip

FROM sonarqube:8.6.1-community
ARG COMMUNITY_BRANCH_PLUGIN_VERSION
COPY --from=downloader /plugin/sonarqube-community-branch-plugin.jar /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_PLUGIN_VERSION}.jar
COPY --from=downloader /web/ /opt/sonarqube/web/
RUN printf 'sonar.web.javaAdditionalOpts=-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-%s.jar=web\nsonar.ce.javaAdditionalOpts=-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-%s.jar=ce\n' \
    "$COMMUNITY_BRANCH_PLUGIN_VERSION" "$COMMUNITY_BRANCH_PLUGIN_VERSION" > /opt/sonarqube/conf/sonar.properties
