variable "db_username" {
  default = "admin"
}

variable "db_name" {
  default = "mydb2"
}

variable "allocated_storage" {
  default = 20
}

variable "instance_class" {
  default = "db.t3.micro"
}

variable "postgres_username" {
  default = "pgadmin"
}