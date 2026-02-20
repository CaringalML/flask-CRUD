# GitHub Actions CI/CD Setup Guide

## Overview

The `.github/workflows/aws-deploy-arm64.yml` workflow automatically builds and pushes Docker images to Docker Hub on every push to the `main` branch.

## What It Does

✅ Builds Flask CRUD app for ARM64 architecture  
✅ Pushes to Docker Hub  
✅ Builds Nginx reverse proxy image  
✅ Creates GitHub releases  
✅ Updates Docker Hub description  
✅ Tags images with version and commit SHA  

## Required Secrets Setup

You need to add two secrets to your GitHub repository:

### 1. DOCKERHUB_USERNAME
- **Value**: Your Docker Hub username
- **Steps**:
  1. Go to GitHub repo → Settings → Secrets and variables → Actions
  2. Click "New repository secret"
  3. Name: `DOCKERHUB_USERNAME`
  4. Value: Your Docker Hub username (e.g., `rencecaringal000`)

### 2. DOCKERHUB_TOKEN
- **Value**: Docker Hub personal access token (NOT your password!)
- **Steps**:
  1. Go to Docker Hub → Account Settings → Security
  2. Click "New Access Token"
  3. Name it: `GitHub Actions`
  4. Copy the token
  5. Go to GitHub repo → Settings → Secrets and variables → Actions
  6. Click "New repository secret"
  7. Name: `DOCKERHUB_TOKEN`
  8. Paste your token

## Docker Images Created

After each successful build, these images are pushed to Docker Hub:

### Flask CRUD App
```bash
docker pull rencecaringal000/flask-crud:latest
docker pull rencecaringal000/flask-crud:arm64
docker pull rencecaringal000/flask-crud:YYYYMMDD-HHMMSS
```

### Nginx Reverse Proxy
```bash
docker pull rencecaringal000/flask-crud-nginx:latest
docker pull rencecaringal000/flask-crud-nginx:arm64
```

## Image Tags

Each build creates multiple tags:

| Tag | Purpose |
|-----|---------|
| `latest` | Always points to newest build |
| `arm64` | ARM64 platform identifier |
| `YYYYMMDD-HHMMSS` | Build timestamp |
| `commit_sha` | 7-char commit hash |

## Trigger Workflow

The workflow runs automatically on:
- ✅ Push to `main` branch
- ✅ Pull requests to `main` branch
- ✅ Manual trigger (Actions → Run workflow)

## Manual Workflow Trigger

To manually trigger the build:
1. Go to GitHub → Actions tab
2. Select "Build ARM64 and Push to Docker Hub"
3. Click "Run workflow"

## Using Published Images

Once images are on Docker Hub, you can use them:

```bash
# Pull the latest Flask app
docker pull rencecaringal000/flask-crud:latest

# Run with local docker-compose (update docker-compose.yml)
docker-compose up
```

Or update `docker-compose.yml` to use remote images:

```yaml
services:
  web:
    image: rencecaringal000/flask-crud:latest
    # ... rest of config

  nginx:
    image: rencecaringal000/flask-crud-nginx:latest
    # ... rest of config
```

## GitHub Releases

Each successful push to `main` creates a GitHub Release with:
- Build timestamp
- Commit SHA
- Docker image links
- Platform information

## Workflow File Breakdown

### Checkout
- Clones your repository code

### Docker Setup
- Installs Docker Buildx for multi-platform builds

### Docker Hub Login
- Authenticates using secrets

### Flask App Build
- Builds Docker image for ARM64
- Tags with multiple versions
- Pushes to Docker Hub

### Nginx Build
- Creates Nginx image with your config
- Pushes to Docker Hub

### Docker Hub Description
- Updates your Docker Hub repo description with features and usage

### GitHub Release
- Creates a release on GitHub with build info

## Troubleshooting

### Build Fails: "username/password incorrect"
- Check secrets are set correctly
- Verify Docker Hub credentials
- Try re-creating the token

### Build Takes Too Long
- ARM64 runners may be slower
- First build is typically slower
- Use `workflow_dispatch` for manual testing

### Images Not Appearing on Docker Hub
- Check GitHub Actions logs for errors
- Verify Docker Hub credentials
- Ensure repository visibility is public

## Environment Variables

```yaml
DOCKER_USERNAME: From secrets.DOCKERHUB_USERNAME
DOCKER_TOKEN: From secrets.DOCKERHUB_TOKEN
```

## Best Practices

1. **Never commit secrets** - Always use GitHub Secrets
2. **Test locally first** - Build locally before pushing
3. **Use semantic versioning** - Tag releases with versions
4. **Monitor builds** - Check Actions tab regularly
5. **Keep images small** - Alpine keeps images lean

## Next Steps

1. ✅ Add `DOCKERHUB_USERNAME` secret
2. ✅ Add `DOCKERHUB_TOKEN` secret
3. ✅ Push to `main` branch
4. ✅ Go to Actions tab to monitor build
5. ✅ Check Docker Hub for published images

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Action](https://github.com/docker/build-push-action)
- [Docker Hub Personal Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
