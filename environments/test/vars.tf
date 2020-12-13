
variable "environment_tag" {
  description = "Environment"
    type = string
  default = "Test"
}
variable "owner_tag" {
    description = "Owner name"
    type = string
  default = "tstanislawczyk"
}
variable "prefix" {
  type = string
}
variable "project_name" {
  description = "Project name"
  type        = string
}