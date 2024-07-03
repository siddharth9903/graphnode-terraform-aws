terraform workspace show
terraform workspace new prod
terraform workspace select prod

terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars --auto-approve
terraform destroy -var-file=dev.tfvars --auto-approve

terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars --auto-approve
terraform destroy -var-file=prod.tfvars --auto-approve