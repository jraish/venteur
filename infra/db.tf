# resource "digitalocean_database_cluster" "knights_path_db_cluster" {
#   name         = "knights_path_db_cluster"
#   region       = "nyc1"
#   version      = "14"
#   node_count   = 1
#   size         = "db-s-1vcpu-2gb"
#   engine       = "pg"
# }

# resource "digitalocean_database_firewall" "knights_path_db-fw" {
#   cluster_id = digitalocean_database_cluster.knights_path_db_cluster.uuid

#   rule {
#     type  = "app"
#     # value = "192.168.1.1"
#   }
# }

# resource "digitalocean_database_db" "knights_path_db" {
#   cluster_id = digitalocean_database_cluster.knights_path_db_cluster.id
#   name       = "knights_path_db"
# }

# resource "digitalocean_database_user" "knights_path_user" {
#   cluster_id = digitalocean_database_cluster.knights_path_db_cluster.id
#   name       = "kp_user"
# }

# resource "digitalocean_database_cluster" "knights_path_redis_cluster" {
#   name          = "knights_path_redis"
#   region       = "nyc1"
#   version      = "7"
#   node_count   = 1
#   size         = "s-1vcpu-1gb"
#   engine       = "redis"
# }

# resource "digitalocean_database_redis_config" "knights_path_redis_config" {
#   cluster_id             = digitalocean_database_cluster.knights_path_redis_cluster.id
#   maxmemory_policy       = "allkeys-lru"
#   notify_keyspace_events = "KEA"
#   timeout                = 90
# }