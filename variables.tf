//variables.tf
variable "ami_id" {
  // ubuntu 18.04 in us-east-2 8gb all defaults
  default = "ami-0b9064170e32bde349"
}

variable "ami_name" {
  default = "kr-ubuntu18"
}
variable "ami_key_pair_name" {
  default = "kriss"
}