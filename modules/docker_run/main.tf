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

resource "docker_image" "nginx" {
  name = "nginx:latest"
}


resource "docker_network" "private_network" {
  name = "nginx_network"
}

resource "docker_volume" "shared_volume" {
  name = "shared_volume2"
  driver = "local"
  driver_opts = {
	o = "bind"
        type = "none"
	device = var.path
	}
  depends_on = [null_resource.ssh_target]
}

resource "null_resource" "ssh_target" {
    connection {
        type        = "ssh"
        host        = var.host
        user        = var.ssh_user
        private_key = file(var.ssh_key)
    }
  provisioner "remote-exec" {
    inline = [ "sudo mkdir -p ${var.path}",
	       "sudo chmod 777 ${var.path}",
	       "sleep 5s"
    ]
  }
}
resource "docker_container" "nginx_container" {
  name = "nginx_container"
  image = docker_image.nginx.image_id
  ports {
   internal = 80
   external = 80
}
networks_advanced{
name = docker_network.private_network.name

}
volumes {
volume_name=docker_volume.shared_volume.name
container_path= "/usr/share/nginx/html/"

}
}
