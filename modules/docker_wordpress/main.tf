terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}


provider "docker" {
  host = "tcp://${var.host}:2375"
}

resource "null_resource" "ssh_target" {
  connection {
    type        = "ssh"
    host        = var.host
    user        = var.ssh_user
    private_key = file(var.ssh_key)
  }
  provisioner "remote-exec" {
    inline = ["sudo mkdir -p ${var.path}",
      "sudo chmod 777 ${var.path}",
      "sleep 5s"
    ]
  }
}

resource "docker_volume" "db_data" {
  name   = "db_data"
  driver = "local"
  driver_opts = {
    o      = "bind"
    type   = "none"
    device = var.path
  }
  depends_on = [null_resource.ssh_target]
}

resource "docker_network" "wordpress" {
  name = "wordpress_net"
}

data "docker_registry_image" "wordpress" {
  name = "wordpress:latest"
}
data "docker_registry_image" "mysql" {
  name = "mysql:latest"
}

resource "docker_image" "wordpress_img" {
  name = data.docker_registry_image.wordpress.name
  pull_triggers = [ data.docker_registry_image.wordpress.sha256_digest ]
  
}

resource "docker_image" "mysql_img" {
  name = data.docker_registry_image.mysql.name
  pull_triggers = [ data.docker_registry_image.mysql.sha256_digest ]
}


resource "docker_container" "mysql_container" {
  name  = "mysql_container"
  network_mode = "wordpress_net"
  image = docker_image.mysql_img.image_id
  env = [ "MYSQL_ROOT_PASSWORD=root",
          "MYSQL_DATABASE=wordpress",
          "MYSQL_USER=wordpress",
          "MYSQL_PASSWORD=wordpress"  ]    
  ports {
    internal = 3306
    external = 3306
  }
  networks_advanced {
    name = docker_network.wordpress.name
  }
  volumes {
    host_path = var.path
    container_path = "/var/lib/mysql"
    volume_name = "db_data"

  }
}

  resource "docker_container" "wordpress_container" {
  name  = "wordpress_container"
  image = docker_image.wordpress_img.image_id
  env = [ "WORDPRESS_DB_HOST=mysql_container:3306",
          "WORDPRESS_DB_PASSWORD=wordpress"

   ]    
  ports {
    internal = 80
    external = var.wp_port
  }
  networks_advanced {
    name = docker_network.wordpress.name
  }
  
}
