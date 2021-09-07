variable "ingress_ports" {
    type = list(any)
}
# variable "egress_ports" {
#     type = list(any)
  
# }

variable "ami" {
    type = map(any)
  
}

variable "tags" {
    type = list(any)
  
}
variable "public_key_location" {}

variable "private_key_location" {}


variable "instance_type" {
    type = list(any)
  
}
