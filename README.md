# SonarQube Multi-Branch (Community Edition + Branch Plugin)

Self-hosted SonarQube 8.6.1 Community with the [community-branch-plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin) baked in at build time, unlocking multi-branch and PR analysis on Community Edition.

## Structure

```
.
├── Dockerfile                          # downloads the plugin + webapp during build, no local jar needed
├── docker-compose.yml
└── .github/workflows/docker-build.yml  # CI: builds & smoke-tests the image
```

## Setup

```
docker compose up -d --build
```

The `Dockerfile` pulls `sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_PLUGIN_VERSION}.jar` and its matching `sonarqube-webapp.zip` directly from GitHub releases in a build stage, then copies them into the final image and writes `sonar.properties` with the `-javaagent` flags for both the `web` and `ce` processes. Nothing needs to be downloaded or committed locally.

Change the plugin version by editing `COMMUNITY_BRANCH_PLUGIN_VERSION` in `docker-compose.yml` (or pass `--build-arg` directly). Check the [compatibility table](https://github.com/mc1arke/sonarqube-community-branch-plugin#readme) before bumping it — plugin versions are pinned to SonarQube versions.

Open `http://127.0.0.1:9000` (default login `admin` / `admin`) once it's up, then confirm the plugin loaded:

```
docker compose logs sonarqube | grep -i "community branch"
```

## Multi-branch analysis

```
sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.branch.name=$(git rev-parse --abbrev-ref HEAD) \
  -Dsonar.host.url=http://127.0.0.1:9000 \
  -Dsonar.login=<token>
```

Each branch shows up under **Project > Branches** in the UI; PR decoration works the same way with `sonar.pullrequest.*` properties.

## CI

`.github/workflows/docker-build.yml` runs on every push/PR: builds the image (which downloads the plugin fresh, so a broken/moved release asset fails CI immediately), sets `vm.max_map_count` for the embedded Elasticsearch, brings the stack up, waits for `/api/system/status` to report `UP`, then tears it down.

## Notes

- Port 9000 is bound to `127.0.0.1` only — put a reverse proxy in front for external access.
- Add a bundled Postgres service if you don't want to rely on SonarQube's embedded default DB in production.
- Requires network access to `github.com`/`objects.githubusercontent.com` at build time.
