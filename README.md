# Docker SSH
> Access private repos when building Docker images.

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/rolandjitsu/docker-ssh/test.yml?branch=master&style=flat-square)](https://github.com/rolandjitsu/docker-ssh/actions?query=workflow%3ATest)

Do note that this guide works only with GitHub, but with slight modifications it can easily be adapted to GitLab and others.

## Prerequisites
Install the following tools:
* [Docker](https://docs.docker.com/engine) >= `20.10.0`
* [buildx](https://github.com/docker/buildx#installing) >= `v0.8.0`

In modern Docker (v23+), BuildKit and SSH mounts are enabled by default and no longer require experimental flags.

Start the [ssh-agent](https://www.ssh.com/ssh/agent):
```bash
eval $(ssh-agent)
```

And add your current SSH key to the agent:
```bash
ssh-add ~/.ssh/id_rsa # or ~/.ssh/id_ed25519
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

Or build the base image with [bake](https://docs.docker.com/build/bake/):
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
Note that the GitHub CI workflow is setup to use [deploy keys](https://github.com/webfactory/ssh-agent#authorizing-a-key) instead of [a user SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).
Read more about security in workflows at [security hardening for github actions](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions).
