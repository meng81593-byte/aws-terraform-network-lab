# Security decisions for the short-lived experiment

The root lab disables subnet-level automatic public IPv4 assignment. Private subnets have explicitly managed local-only routes. The delivery service deliberately opts into a public address for outbound image pulls/logs, while task ingress remains limited to the ALB security group on port 8080.

ECR images use immutable tags, encryption, and scanning on push. The per-repository scan setting avoids changing unrelated account-wide registry rules. GitHub publishing uses OIDC, with an exact repository/branch subject and audience restriction; no long-term AWS key is put in GitHub.

Three Trivy checks have narrowly scoped inline exceptions, each documented alongside the affected resource:

- `AVD-AWS-0053`: the ALB is intentionally public because it serves a public game demo.
- `AVD-AWS-0054`: temporary HTTP hosting without a supplied domain/certificate. No login or private data is served. Permanent hosting requires HTTPS.
- `AVD-AWS-0104`: outbound TCP 443 reaches dynamic ECR and CloudWatch service endpoints. Other protocols/ports are not opened. A long-lived private-task design should choose NAT or the relevant endpoints explicitly.

These are acknowledged experiment tradeoffs, not claims that the findings were technically eliminated. Configuration checks do not replace runtime verification or a review of an actual permanent deployment.
