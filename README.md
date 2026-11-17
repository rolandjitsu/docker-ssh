# Docker SSH
> Access private repos when building Docker images.

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/rolandjitsu/docker-ssh/test.yml?branch=main&style=flat-square)](https://github.com/rolandjitsu/docker-ssh/actions?query=workflow%3ATest)

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
PRIV_GIT_REPO=<my private repo> docker buildx bake --allow=ssh priv-repo
```

Now build an image that just copies whatever was in the private repo to the host:
```bash
docker buildx build -f Dockerfile -o type=local,dest=./priv-code .
```

Or build the image with bake:
```bash
docker buildx bake --allow=ssh
```

## Security & Authentication

### Security Posture
* **Least Privilege**: Only the `priv-repo` target requests the SSH socket capability; downstream extraction and packaging targets do not.
* **Ephemeral Socket Access**: BuildKit forwards the SSH agent socket only during the specific `RUN --mount=type=ssh` step. The socket is not accessible during subsequent build steps and is never persisted into image layers or metadata.
* **Git Metadata Sanitization**: When exporting code, exclude the `.git/` folder (`rsync -av --exclude '.git'`) to prevent leaking commit histories, commit signatures, or origin URLs into output artifacts.
* **Host Verification**: Mount a trusted `known_hosts` file via `--mount=type=secret` to guard against man-in-the-middle attacks.

### Deploy Keys vs GitHub Apps
* **Deploy Keys (SSH)**: This repository uses a deploy key scoped with read-only access to the private repository.
  * Always use modern `ed25519` keys (`ssh-keygen -t ed25519`). Legacy SHA-1 RSA keys were deprecated and disabled by GitHub in March 2022.
  * Deploy keys are repository-scoped and cannot be reused across multiple repositories.
* **GitHub Apps (Recommended for Organizations)**: For organization-wide CI/CD pipelines, using a GitHub App with [actions/create-github-app-token](https://github.com/actions/create-github-app-token) and BuildKit secret mounts (`--mount=type=secret`) is the recommended modern approach:
  * Generates short-lived installation tokens (1 hour lifetime) with automatic expiration.
  * Can span multiple private dependencies across an organization without managing individual SSH keys.
  * Provides fine-grained repository permissions and detailed audit log attribution.

Read more about workflow security at [security hardening for github actions](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions).
