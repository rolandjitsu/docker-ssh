# Docker SSH
> Access private repos when building Docker images.

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/rolandjitsu/docker-ssh/Test?label=tests&style=flat-square)](https://github.com/rolandjitsu/docker-ssh/actions?query=workflow%3ATest)

Do note that this guide works only with Github, but with slight modifications it can easily be adapted to GitLab and others.

## Prerequisites
Install the following tools:
* [Docker](https://docs.docker.com/engine) >= `19.03.13`
* [buildx](https://github.com/docker/buildx#installing) >= `v0.4.1`

Enable the experimental features for Docker CLI by adding the following config to `~/.docker/config.json`:
```json
{
    "experimental": "enabled"
}
```

And enable the experimental features for Docker Daemon by adding the following config to the `/etc/docker/daemon.json` file (for Linux; on macOS it's `~/.docker/daemon.json`):
```json
{
    "experimental": true
}
```

Start the [ssh-agent](https://www.ssh.com/ssh/agent):
```bash
eval $(ssh-agent)
```

And add your current SSH key to the agent:
```bash
ssh-add ~/.ssh/id_rsa
```

Lastly, setup the `known_hosts` to avoid prompts from SSH:
```bash
ssh-keyscan github.com >> ./known_hosts
```

**NOTE**: On Linux, you probably don't need to start the agent as it should be started at login.

## Build
Build a base image that just clones a private repo (we'll use this in another image):
```bash
docker buildx build -f Dockerfile.priv-repo \
    --ssh default \
    --secret id=known_hosts,src=./known_hosts \
    --build-arg PRIV_GIT_REPO=<my private repo> \
    --tag priv-repo \
    .
```

Or build the base image with [bake](https://github.com/docker/buildx#buildx-bake-options-target):
```bash
PRIV_GIT_REPO=<my private repo> docker buildx bake priv-repo
```

Now build an image that just copies whatever was in the private repo to the host:
```bash
docker buildx build -f Dockerfile -o type=local,dest=./priv-code .
```

Or build the image with bake:
```bash
docker buildx bake
```

## SSH Auth
Note that the Github CI workflow is setup to use [deploy keys](https://github.com/webfactory/ssh-agent#authorizing-a-key) instead of [a user SSH key](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account).
Read more about security in workflows at [security hardening for github actions](https://docs.github.com/en/free-pro-team@latest/actions/learn-github-actions/security-hardening-for-github-actions).
