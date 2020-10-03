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
  dockerfile  = "Dockerfile.priv-repo"
  secret     = ["id=known_hosts,src=./known_hosts"]
  ssh        = ["default=${SSH_ID}"]
  tags       = ["priv-repo"]
  args       = {
    PRIV_GIT_REPO = "${PRIV_GIT_REPO}"
  }
}

target "default" {
  dockerfile  = "Dockerfile"
  output     = ["${DEST}"]
}
