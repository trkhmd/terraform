terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "3.2.2"
    }
  }
}


resource "null_resource" "docker_install" {
    triggers =  {
        always_run = "${timestamp()}"
    }
    connection {
        type        = "ssh"
        host        = var.host
        user        = var.username
        private_key = file(var.ssh_key)
    }
  provisioner "remote-exec" {
    inline = [ "curl -fsSL https://get.docker.com/ -o get-docker.sh", 
                "sudo apt update -qq > /dev/null",
		"sudo chmod 755 get-docker.sh",
                "sudo ./get-docker.sh > /dev/null"
    ]
  }
  provisioner "file" {
    source="startup-options.conf"
    
    destination="/tmp/startup-options.conf"
  }

  provisioner "remote-exec" {
    inline= [
    "sudo mkdir -p /etc/systemd/system/docker.service.d",
    " sudo cp /tmp/startup-options.conf /etc/systemd/system/docker.service.d/startup-options.conf",
    " sudo systemctl daemon-reload",
    " sudo systemctl restart docker",
    " sudo usermod -aG docker ${var.username}",
]
}
}
