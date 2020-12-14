provider "aws" {
 region = "us-west-2"
}

module "network" {
    source = "../../modules/network"
     
    project_name = var.project_name
    environment_tag = var.environment_tag
    owner_tag = var.owner_tag
    prefix    = var.prefix 
}
/*
module "web-server-cluster" {
    source = "../../modules/services/web-server-cluster"
}*/