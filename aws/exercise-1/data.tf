data "http" "my_ip_raw" {
  url = "https://ifconfig.me/ip"
}

locals {
  my_ipv4      = data.http.my_ip_raw.response_body
  my_ipv4_cidr = "${data.http.my_ip_raw.response_body}/32"
}

output "my_ip_raw_response" {
  value = data.http.my_ip_raw.response_body
}
