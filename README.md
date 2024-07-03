terraform workspace show
terraform workspace new prod
terraform workspace select prod

terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars --auto-approve
terraform destroy -var-file=dev.tfvars --auto-approve

terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars --auto-approve
terraform destroy -var-file=prod.tfvars --auto-approve




Creating dynamodb:

aws dynamodb create-table \
  --table-name tfstate-lock-graphnode-ecs \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1


terraform init
