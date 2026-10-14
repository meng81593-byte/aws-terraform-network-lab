# Cost estimate and cleanup

Pricing checked on 14 October 2026 using AWS's public Paris-region price files.

- Linux x86 Fargate CPU: USD 0.0486 per vCPU-hour.
- Fargate memory: USD 0.0053 per GB-hour.
- Application Load Balancer: USD 0.02646 per hour, plus USD 0.0084 per LCU-hour.
- In-use public IPv4: USD 0.005 per address-hour.

A script calculated a base estimate of **USD 0.06466/hour**, or **USD 0.12932 for two hours**, assuming one task with 0.25 vCPU/0.5 GB, one ALB using one LCU, and three public IPv4 addresses. A rolling update may briefly run a second task. Registry storage, logs, transfer, tax, and currency conversion are excluded; this is not a bill or a hard spending cap.

The user-authorized experiment limit is about €5, with destruction on the same day. Use a short verification window, record resource creation times, and destroy immediately after the exercise. Preserve a stable image/task definition for rollback before removal.

Cleanup order:

1. Destroy only the `delivery/service` component using its own state.
2. Confirm no experiment ECS tasks, ALB, log groups, ENIs, or VPC remain.
3. Remove only images from the experiment ECR repository, then destroy `delivery/registry` using its own state.
4. If an existing OIDC provider was reused, it must remain. Preserve the original `little-steps-vpc` and any resources outside the experiment's state.
5. Record the final Terraform and AWS readback results. Do not delete the state before cleanup succeeds.

Sources: [AWS Fargate pricing](https://aws.amazon.com/fargate/pricing/), [ALB pricing](https://aws.amazon.com/elasticloadbalancing/pricing/), [VPC pricing](https://aws.amazon.com/vpc/pricing/). Rates were extracted from the corresponding AWS public price-list service files, not inferred from an unrelated region.

## Completed experiment

Service provisioning began at 15:30:40 UTC on 14 October 2026. Final AWS cleanup readback passed at 16:24:51 UTC the same day, a verification window of about 54 minutes. Thirty service/network resources and five registry/identity resources were destroyed; the image and three task revisions were also removed. The original VPC was preserved. Temporary GitHub AWS role and endpoint variables were removed.

The one-hour base model is USD 0.06466 for one task or USD 0.08446 for two tasks, with one ALB/LCU and public IPv4. The [duration model](evidence/cost-estimate-evidence.json) is a linear estimate and excludes service billing rounding as well as storage, logs, transfer, taxes and currency conversion. It is not the final AWS bill. [Cleanup readback](evidence/cleanup-evidence.json) confirms removal of the experiment's running resources; it does not assert that pre-existing account costs are zero.
