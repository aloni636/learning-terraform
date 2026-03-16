terraform {
  required_providers {
    # See: https://github.com/kreuzwerker/terraform-provider-docker
    docker = {
      source = "kreuzwerker/docker"
      # Latest as of right now (11.3.26) is 3.6.2; see: https://registry.terraform.io/providers/kreuzwerker/docker/latest
      version = "3.6.2"
    }
  }
}

provider "docker" {}
