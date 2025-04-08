# Next.js Application Template

This is a template for Next.js applications deployed with Terraform and Ansible.

## Getting Started

1. Clone this repository
2. Install dependencies with `npm install`
3. Run the development server with `npm run dev`
4. Open [http://localhost:3000](http://localhost:3000) in your browser

## Deployment

This application is automatically deployed when changes are pushed to the main branch. The deployment is managed by:

- GitHub Actions for CI/CD
- Terraform for infrastructure provisioning
- Ansible for application configuration

## Directory Structure

- `/terraform` - Terraform files for infrastructure
- `/.github/workflows` - CI/CD pipeline definitions
- `/src` - Application source code