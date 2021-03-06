# docker-github-runner
Dockerfile for GitHub action runner

## Overview
This is a simple image for running a Linux-based GitHub action runner within Docker.
You should only allow this for private repositories that you trust.

### Build Arguments

| Argument Name          | Description                                         | Default Value          |
|------------------------|-----------------------------------------------------|------------------------|
| FROM                   | Base image to build the container from              | `debian:bullseye-slim` |
| DEBIAN_FRONTEND        | Set the frontend used for Debian images             | `noninteractive`       |
| DOCKER_REPOSITORY      | Package repository to use for installing Docker CLI | `stable`               |
| DOCKER_COMPOSE_VERSION | Version of docker-compose to install                | `1.29.2`               |
| GITHUB_RUNNER_VERSION  | Version of GitHub runner to install                 | `latest`               |

### Environment Variables

| Variable Name            | Description                                           | Default Value           |
|--------------------------|-------------------------------------------------------|-------------------------|
| RUNNER_NAME              | Name of the runner to register with GitHub            | `${HOSTNAME}`           |
| RUNNER_WORK_DIRECTORY    | Set the directory to use for runner work              | `_work`                 |
| RUNNER_REPOSITORY_URL*   | GitHub URL of the repository to register the runner   | --                      |
| RUNNER_ORGANIZATION_URL* | GitHub URL of the organization to register the runner | --                      |
| RUNNER_LABELS            | Labels to tag the runner with in GitHub               | `self-hosted,linux,x64` |
| GITHUB_ACCESS_TOKEN**    | GitHub personal access token (PAT)                    | --                      |


**\* NOTE:** Only `RUNNER_REPOSITORY_URL` *or* `RUNNER_ORGANIZATION_URL` needs to be specified.
This is dependent on whether you want the runner to be associated with a single repository or an entire organization.

**\*\* NOTE:** Your `GITHUB_ACCESS_TOKEN` must have `repo`, `workflow`, `admin:org`, and `manage_runners:enterprise` scopes.

## Docker Run

```shell
$ docker run -d \
      --name github-runner \
      --restart=unless-stopped \
      -e RUNNER_NAME="self-hosted-runner" \
      -e RUNNER_REPOSITORY_URL="https://github.com/user/repository" \
      -e RUNNER_LABELS="self-hosted,linux,x64" \
      -e GITHUB_ACCESS_TOKEN=${GITHUB_ACCESS_TOKEN} \
      -v /var/run/docker.sock:/var/run/docker.sock \
      ewrogers/github-runner
```

## Docker Compose
Alternatively, you can run via `docker-compose up -d`.

Create an `.env` file with the values above, they will be passed to the container:

```dotenv
RUNNER_NAME=self-hosted-runner
RUNNER_REPOSITORY_URL=https://github.com/user/repository
RUNNER_LABELS=self-hosted,linux,x64
GITHUB_ACCESS_TOKEN=...
```

**NOTE:** Do not use quoted strings for `.env` values!

## File Access (Artifacts)
In order for the runner to see files in steps that are run within containers, the `RUNNER_WORK_DIRECTORY` must match both on the host and container mount side.

By default, this is set to mount `/tmp/github-runner` and use `/tmp/github-runner/_work` as the work directory.
## Resource Limits
If you want to add resource limits to the GitHub runner, you can add the following to the `docker-compose.yml`:

```
services:
  runner:
    # other properties...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

Then start via `docker-compose --compatibility up -d` to enforce the resource limits on the runner.

## Automatic Removal
The `entrypoint.sh` script automatically removes the runner when it exits.
