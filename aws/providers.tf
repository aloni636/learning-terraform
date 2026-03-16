terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" // `~>` is a pessimistic version constraint, accepting any `6.*`
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
