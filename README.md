# Flask App CI/CD Pipeline

This project automates deployment of a Flask app to AWS using GitHub Actions and Terraform.

## 🚀 Features
- Auto-builds Docker image on every `git push`
- Deploys to AWS EC2 with self-contained VPC
- Uses GitHub Secrets for secure credentials

## 🛠️ Setup
1. Set up secrets in GitHub Settings → Secrets
2. Push code → watch Actions tab

## 🌐 Live App
IP changes on each deploy — check Terraform output in GitHub Actions logs.

## 🧹 Clean Up
```bash
cd terraform
terraform destroy
