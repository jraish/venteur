terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "DO_TOKEN" {}

provider "digitalocean" {
  token = var.DO_TOKEN
}

resource "digitalocean_project" "knights_path" {
  name = "knights_path"
}

# resource "digitalocean_project_resources" "knights_path_resources" {
#   project = data.digitalocean_project.knights_path.id
#   resources = [
#     digitalocean_database_cluster.knights_path_db_cluster.urn,
#     digitalocean_database_db.knights_path_db.urn,
#     digitalocean_database_user.knights_path_user.urn,
#     digitalocean_database_cluster.knights_path_redis
#   ]
# }