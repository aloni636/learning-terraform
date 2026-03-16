resource "docker_image" "vault" {
  name = "hashicorp/vault:1.21.4"
}

resource "docker_container" "vault" {
  name = "terraform-basic-vault"
  image = docker_image.vault.image_id

  ports {
    internal = 8200
    external = 8200
  }
}