terraform {
  backend "s3" {
    bucket         = "tfstate-graphnode-ecs-bucket"
    key            = "graphnode/terraform.tfstate"
    region         = "us-east-1"  # replace with your preferred region
    encrypt        = true
    dynamodb_table = "tfstate-lock-graphnode-ecs"
  }
}