#!/bin/bash
# Quick terraform plan script
cd /mnt/c/dev/beeinfra/terraform/environments/dev || exit 1
terraform plan \
  -var-file="terraform.tfvars" \
  -var-file="vm1-infr1-dev.tfvars" \
  -var-file="vm2-secu1-dev.tfvars" \
  -var-file="vm3-apps1-dev.tfvars" \
  -var-file="vm4-apps2-dev.tfvars" \
  -var-file="vm5-data1-dev.tfvars" \
  -out=tfplan
