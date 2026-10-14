# State management

The standalone lab and each delivery component have separate state. Keep those working directories and their state together until cleanup completes. Local state is sufficient for a single operator's short experiment; it is not a shared automation backend.

## Shared operation

Before multiple operators or CI manage Terraform, bootstrap a dedicated S3 state bucket separately from the resources it tracks. Enable encryption, Block Public Access, versioning, and a narrowly scoped access policy. Use Terraform's S3 native lockfile support (`use_lockfile = true`). Do not introduce DynamoDB locking in a new setup: it is deprecated in current Terraform documentation.

Create a backend block only after that bucket exists. Keep per-component keys, such as `network/terraform.tfstate`, `registry/terraform.tfstate`, and `service/terraform.tfstate`. Migrate an existing state with `terraform init -migrate-state`, then verify that the plan is unchanged and concurrent operations are locked. The example below is a configuration pattern, not a bucket created by this repository:

```hcl
terraform {
  backend "s3" {}
}
```

Supply bucket, key, region, `encrypt = true`, and `use_lockfile = true` through a reviewed local backend configuration. Keep credentials in the AWS credential chain. S3 lockfile permissions apply to the `.tflock` object; do not grant broad deletion of all state objects.

Never delete the backend bucket while tracked infrastructure is still running. Keep recovery versions according to your retention needs.

Source: [HashiCorp S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3).
