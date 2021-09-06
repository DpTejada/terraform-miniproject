terraform {
  backend "s3" {
#      bucket = "devops14-winter-class-bucket"
      bucket = "devops-14-my-bucket"
      region = "us-east-1"
      #profile = "prod"
      key = "terraform.tfstate"
      dynamodb_table = "devops14-lock-table"
  }
}

