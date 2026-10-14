# Verification record

Date: 14 October 2026.

Local checks completed:

- Terraform 1.16.2 and AWS provider 6.68.0.
- Standalone configuration validation passed.
- Five mock-provider tests passed: network boundaries, duplicate zones, overlapping subnets, out-of-VPC subnets, and zones from another region.
- Provider checksums obtained for Linux amd64 and Windows amd64.
- Registry and service configurations validated.

Mock tests do not create AWS resources and do not prove actual packet connectivity. The separate live experiment was completed on 14 October 2026; the original Little Steps VPC was preserved.

## Live verification

- Applied five registry/identity resources and thirty service/network resources in the dedicated `10.42.0.0/16` VPC.
- Confirmed DNS, four subnet CIDRs/zones and explicit associations. Public routes used the Internet Gateway; both private route tables had only local routes. Automatic public IPv4 assignment was disabled on all four subnets.
- ECS task revision 1 became healthy, ALB target health was healthy, and `/healthz`, HTML, bundle and map assets returned HTTP 200. The task ran image digest `sha256:4a0d13134a03da5990ec23c95bcaf8105e5d61f56574ddfbfc399d0aa5d9461f` from commit `7b87c59cb2fd990ec0bc5426cb4e613412a5716f`.
- Introduced revision 2 with a deliberately failing container health check. Three failed tasks triggered the circuit breaker. At 15:40:45 UTC ECS reported rollback; revision 1 returned to a completed deployment at 15:41:24 UTC. Post-recovery endpoints and target health passed. This is one recovery exercise, not a continuous-availability or high-availability test.
- The [OIDC release workflow](https://github.com/meng81593-byte/little-steps-devops/actions/runs/38591646137) registered revision 3, waited for stability, confirmed the requested revision, and passed the live browser test: menu, tutorial selection, prompts, first move and expected resource reduction.
- Terraform plans after bootstrap and the workflow release returned exit code 0 with no changes. Terraform owns infrastructure; the application workflow owns later task revisions.
- Destroyed thirty service/network resources and five registry/identity resources. Removed the experiment image and all three task revisions. AWS readback confirmed no experiment VPC, ENIs, active cluster/task definitions, ALB, target group, log group, ECR repository or experiment roles. The created GitHub OIDC provider was removed; the original VPC remained.

Sanitized records: [bootstrap](evidence/bootstrap-evidence.json), [rollback](evidence/rollback-evidence.json), [recovery health](evidence/after-rollback-health.json), [released service](evidence/released-service-evidence.json), [image](evidence/ecr-evidence.json), [image/revision cleanup](evidence/image-and-revision-cleanup.json), [final cleanup](evidence/cleanup-evidence.json).

## Troubleshooting recorded

The initial OIDC publisher trust used the older name-only subject. This repository uses immutable owner/repository IDs; reading its actual OIDC customization prefix and matching it fixed authentication. The first automated ECS release also exposed an incorrectly resource-scoped `DescribeTaskDefinition` permission. That read API requires `Resource: *`; task registration, service updates and passing the execution role remain scoped. Both corrections are traceable in the PRs and successful reruns.

## Experiment boundaries

One task, temporary HTTP ALB hosting, public-address task egress, and local Terraform state were deliberate cost-limited choices. No private-subnet workload traffic test, load test, application high-availability claim or production SLA is made. The permanent game demo uses HTTPS GitHub Pages. AWS resources and the corresponding repository variables were removed after verification; recreate the components and configure outputs before dispatching another AWS release.
