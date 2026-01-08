## Secure AWS Infrastructure Automation with GitHub Actions & OIDC

<Architecture diagram>

In many organizations, CI/CD pipelines represent a significant security risk due to the use of long-lived AWS IAM Access Keys. This project demonstrates a production-grade, zero-trust approach to infrastructure automation. By leveraging OpenID Connect (OIDC), we eliminate the need for static secrets, while implementing a strict least-privilege IAM architecture that separates planning and deployment phases.

The goal is to provide a "Golden Path" for infrastructure delivery that balances developer velocity with rigorous security and cost governance.

## The Business Problem

Traditional "all-access" CI/CD service accounts are a prime target for credential theft and lateral movement. Furthermore, without integrated visibility into cost and security compliance during the Pull Request (PR) phase, infrastructure teams often face "surprise" cloud bills and post-deployment security vulnerabilities.

This project solves these issues by:

- Removing Secret Sprawl: Using ephemeral, short-lived tokens via OIDC.

- Enforcing Governance: Shifting security (Checkov) and cost estimation (Infracost) left into the PR process.

- Reducing Blast Radius: Granular IAM roles ensure the plan phase cannot modify resources, and the apply phase only runs on protected branches.

## Technical Architecture & Design

### Technologies

- AWS CloudFormation
- AWS CloudWatch
- AWS Identity Centre
- AWS IAM
- AWS VPC (and components)
- Terraform
- GitHub Actions
- Infracost
- Checkov

### Bootstrapping (The Foundation)

Before Terraform runs, we establish a secure foundation using a CloudFormation bootstrap stack. This is deployed locally using AWS Identity Center (SSO), ensuring that even the initial setup avoids long-lived credentials.

- OIDC Provider: Establishes trust between GitHub and your AWS Account.

- S3 Backend: Provisioned with Versioning and Object Locking for state integrity.

- Identity-Based Guardrails: Creates specific roles with trust policies scoped to this specific GitHub repository.

### Key Security & Operational Features

- Native S3 State Locking: Utilizes S3's native locking capabilities to prevent concurrent state corruption without the overhead of a DynamoDB table.

- Branch Protection: Changes are gated behind mandatory code reviews and successful status checks

- OIDC Subject Claims: IAM trust policies are hardened using sub claims, ensuring only specific branches/environments can assume the "Apply" role.

### CI/CD Pipeline Maturity

The GitHub Actions workflow is split into two distinct logical phases: PhaseTriggerIAM Role ScopeTools IntegratedPre-Flight (Plan)Pull RequestRead-Only / State AccessCheckov (SAST), Infracost, terraform planDeployment (Apply)Merge to mainResource Creation / Modification

## Production Implementation Notes

In a real-world enterprise environment, this project would be extended by:

- Service Control Policies (SCPs): To restrict the bootstrap role from modifying sensitive networking or security logging.

- OPA/Rego Policies: Moving beyond Checkov to custom organizational compliance rules.

- Multi-Account Strategy: Deploying the OIDC provider in a Shared Services account and assuming cross-account roles into Workload accounts.
