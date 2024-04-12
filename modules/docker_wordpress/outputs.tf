output "docker_db_ip" {
    value = docker_container.mysql_container.network_data
}

output "docker_wp_ip" {
    value = docker_container.wordpress_container.network_data
}