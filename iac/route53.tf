variable "dns_zone" {}

# importing existing dns zone 
data "aws_route53_zone" "zone" {
  name         = "${var.dns_zone}"
  private_zone = false
}

# creating dns record
# public url -> alb
resource "aws_route53_record" "app_public_url" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${terraform.workspace}.${var.proj_name}.${var.dns_zone}"
  type    = "A"

  alias {
    name                   = "${aws_lb.lb.dns_name}"
    zone_id                = "${aws_lb.lb.zone_id}"
    evaluate_target_health = true
  }
}

# outputting public url of the app
output "public_url" {
  value = "http://${aws_route53_record.app_public_url.name}"
}
