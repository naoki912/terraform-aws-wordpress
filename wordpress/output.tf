output "wordpress address" {
    value = "${aws_instance.wp_wordpress_instance.public_ip}"
}