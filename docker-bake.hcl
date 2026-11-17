variable "SSH_AUTH_SOCK" {
  default = ""
}

variable "SSH_ID" {
  default = ""
}

variable "PRIV_GIT_REPO" {
  default = "https://github.com/rolandjitsu/noop.git"
}

variable "DEST" {
  default = "./priv-code"
}

target "priv-repo" {
  dockerfile = "Dockerfile.priv-repo"
  secret     = ["id=known_hosts,src=./known_hosts"]
  ssh        = [
    SSH_AUTH_SOCK != "" ? "default=${SSH_AUTH_SOCK}" : (SSH_ID != "" ? "default=${SSH_ID}" : "default")
  ]
  tags       = ["priv-repo"]
  args       = {
    PRIV_GIT_REPO = "${PRIV_GIT_REPO}"
  }
}

target "default" {
  dockerfile = "Dockerfile"
  contexts = {
    priv-repo = "target:priv-repo"
  }
  ssh        = [
    SSH_AUTH_SOCK != "" ? "default=${SSH_AUTH_SOCK}" : (SSH_ID != "" ? "default=${SSH_ID}" : "default")
  ]
  output     = ["${DEST}"]
}
