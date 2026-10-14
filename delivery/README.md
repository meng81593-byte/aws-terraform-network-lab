# Short-lived container delivery experiment

This connects the network lab to [Little Steps DevOps](https://github.com/meng81593-byte/little-steps-devops). It deliberately uses a separate VPC (`10.42.0.0/16`, prefix `little-steps-portfolio`) and does not change the original `little-steps-vpc`.

## Components

- `registry/`: ECR repository with immutable tags, retention policy, and GitHub OIDC publisher role. Supply an existing GitHub OIDC provider ARN when one already exists; do not create or delete someone else's shared provider.
- `service/`: network module, public ALB, non-root Nginx Fargate task, health checks, seven-day logs, and deployment circuit-breaker rollback. The game has no AWS task role because it calls no AWS APIs.

The demonstration assigns public IPv4 to tasks so they can pull images and send logs without a NAT Gateway. Inbound access to task port 8080 is permitted only from the ALB security group. Public IP assignment is an egress choice, not permission to bypass that security group. Private subnets are retained as a foundation but do not host the demo task.

HTTP is used for the short-lived static game exercise because no domain/certificate has been supplied. It carries no login or private user data. A permanent public environment should add HTTPS and a chosen private-task egress path; this experiment is not presented as production hosting.

## Release flow

1. Initialize and review the `registry/` plan. Reuse a confirmed existing OIDC provider if appropriate.
2. Apply the registry component and use its publisher-role ARN in the game's repository variable `AWS_PUBLISH_ROLE_ARN`.
3. Publish the validated application image with its Git commit SHA; record the returned digest.
4. Set `image_uri` for `service/` to the ECR URL **with `@sha256:...`**. Initialize and review that component's plan before applying.
5. Confirm ECS stabilizes and ALB targets are healthy; check `/healthz`, HTML, bundle, and game assets, then run browser verification against the deployment URL.
6. Record stable task definition ARN and image digest. Exercise a health-check failure and verify restoration of the stable version.
7. Destroy the service component the same day, then remove only this experiment's ECR images and destroy the registry component. The registry defaults to `force_delete = false` to avoid unnoticed image deletion.

One task is the low-cost demo default. Two subnets alone do not mean application high availability. If testing two replicas, temporarily set `desired_count = 2` and verify behavior before claiming that capability.

## Costs and cleanup

Paid resources include task CPU/memory, ALB hours/LCUs, public IPv4, ECR storage, logs, and transfer. Verify current Paris-region rates before applying. The authorized experiment budget is about €5; target a short verification window and destroy resources immediately afterward. AWS cost reporting can be delayed, so an estimated budget is not an automatic spending cap.

Record creation time, validation results, rollback result, destruction result, and any resources retained. Do not report deployment or cleanup as complete based only on configuration or a successful plan.
