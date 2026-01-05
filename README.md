Plan Workflow (Triggered on PR)

1. Checkout code
2. Configure AWS credentials via OIDC
3. Setup Terraform with version pinning
4. Terraform fmt -check (fail fast on formatting)
5. Terraform init (with backend config)
6. Terraform validate
7. Run Checkov security scan (non-blocking initially, then enforce)
8. Terraform plan -out=tfplan
9. Save plan artifact (encrypted, short TTL)
10. Run Infracost (comment on PR with cost diff)
11. Post plan output as PR comment (truncated if huge)

Apply workflow
Checkout code 2. Configure AWS credentials via OIDC 3. Setup Terraform 4. Terraform init 5. Download plan artifact (if using saved plans, or re-plan) 6. Manual approval step (GitHub Environment protection) 7. Terraform apply 8. Update state (automatic with S3 backend) 9. Post-apply verification (optional smoke tests)

# Create tfvars file dynamically from GitHub Secrets

      # This pattern keeps sensitive values out of git while maintaining GitOps workflow
      # For your resume project: Show the pattern even if values aren't sensitive

# Save the binary plan file as an artifact

      # This is what the apply workflow will use - ensures we apply exactly what was reviewed
      # Artifacts are encrypted at rest by GitHub
      # Set retention to 5 days - long enough for review, short enough for security
