variable "host" {}
variable "username" {}
variable "ssh_key" {}
variable "docker_host" {}
variable "path" {}
variable "wordpress_path" {}
variable "wp_port" {}


module "docker_install" {
  source = "./modules/docker_install"
  host = var.host
  username = var.username
  ssh_key = var.ssh_key
}

module "docker_run" {
  source = "./modules/docker_run"
  host = var.docker_host
  ssh_user = var.username
  ssh_key = var.ssh_key
  path = var.path
}
module "docker_wordpress" {
  source = "./modules/docker_wordpress"
  host = var.host
  path = var.wordpress_path
  ssh_user = var.username
  ssh_key = var.ssh_key
  wp_port = var.wp_port
}

module "kubernetes" {
  source = "./modules/kubernetes"
  host = var.host
  user = var.username
  ssh_key = var.ssh_key
}

output "docker_ip_db" {
  value = module.docker_wordpress.docker_db_ip
}
output "docker_ip_wp" {
  value = module.docker_wordpress.docker_wp_ip
}