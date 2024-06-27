terraform workspace show
terraform workspace new xxx
terraform workspace set xxx

terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars --auto-approve
terraform destroy -var-file=dev.tfvars --auto-approve

terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars --auto-approve
terraform destroy -var-file=production.tfvars --auto-approve