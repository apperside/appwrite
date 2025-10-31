# Deploying Appwrite from Source on Coolify

## The Problem
Coolify has a limitation when deploying complex docker-compose files with inline builds:
- It modifies the compose file (adds labels, networks, env_file directives)
- Passes the modified YAML as a shell command argument
- With 20+ services, this exceeds the shell's argument length limit
- Results in: `Error: Argument list too long`

## The Solution: Two-Service Approach

Deploy Appwrite using **TWO separate services in Coolify**:

### Service 1: Build the Image
This service builds your custom Appwrite image from source.

### Service 2: Run the Stack  
This service uses the pre-built image to run all Appwrite services.

---

## Deployment Steps

### Option A: Use Coolify's Built-in Registry (Recommended)

#### 1. Create Image Builder Service

1. In Coolify: **New Resource** → **Application** → **Dockerfile**
2. Configure:
   - **Name**: `appwrite-builder`
   - **Git Repository**: Your Appwrite fork
   - **Branch**: `my-env`
   - **Dockerfile**: `Dockerfile` (in root)
   - **Build Arguments**:
     ```
     DEBUG=false
     TESTING=false
     VERSION=1.8.0-custom
     ```
3. **Deploy** - This builds your image

#### 2. Create Docker Compose Service

1. In Coolify: **New Resource** → **Docker Compose**
2. Configure:
   - **Name**: `appwrite-stack`
   - **Git Repository**: Your Appwrite fork  
   - **Branch**: `my-env`
   - **Docker Compose Location**: `docker-compose.coolify-simple.yml`
3. **Environment Variables**: Coolify will auto-generate these (SERVICE_PASSWORD_*, SERVICE_USER_*, etc.)
4. **Important**: Update the compose file to use the image name from Step 1

#### 3. Update Image Reference

In `docker-compose.coolify-simple.yml`, change:
```yaml
image: 'appwrite-custom:latest'
```

To use Coolify's registry format:
```yaml
image: 'registry.coolify.io/your-project/appwrite-builder:latest'
```

---

### Option B: Build in Pre-Deployment Script (Simpler)

Use a single Docker Compose service with a pre-deployment build step:

#### 1. Create Docker Compose Service

1. **New Resource** → **Docker Compose**
2. **Compose File**: `docker-compose.coolify-simple.yml`
3. **Pre-Deployment Command**:
   ```bash
   #!/bin/bash
   # Build custom image before deploying
   bash build-appwrite-image.sh
   ```

This builds the image locally before docker-compose runs.

---

### Option C: Use GitHub Container Registry

#### 1. Build and Push Image via GitHub Actions

Create `.github/workflows/build-image.yml`:
```yaml
name: Build Appwrite Image

on:
  push:
    branches: [my-env]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and push
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker build -t ghcr.io/${{ github.repository }}/appwrite:latest .
          docker push ghcr.io/${{ github.repository }}/appwrite:latest
```

#### 2. Update Compose File

Use your GitHub Container Registry image:
```yaml
image: 'ghcr.io/yourusername/appwrite:latest'
```

---

## Simplified Compose File Explained

The `docker-compose.coolify-simple.yml` file:
- ✅ Uses **pre-built images** (no inline `build:` directive)
- ✅ Only **10 services** (vs 22+ in the original)
- ✅ Minimal environment variables per service
- ✅ Should be small enough for Coolify to process

Key differences from your original:
- **No build context** - image must be built separately
- **Fewer workers** - only essential ones
- **Simplified env vars** - only what each service needs

---

## Recommended Approach

I recommend **Option B** (Pre-Deployment Script):

1. Use `docker-compose.coolify-simple.yml` as your compose file
2. Set Pre-Deployment Command to: `bash build-appwrite-image.sh`
3. The image builds locally on your Coolify server
4. Docker Compose then uses the freshly built `appwrite-custom:latest`

### Why This Works:
- ✅ Image is built BEFORE Coolify processes docker-compose
- ✅ No inline build in compose = smaller processed YAML
- ✅ Fresh build on every deployment
- ✅ No external registry needed
- ✅ Single Coolify service to manage

---

## Next Steps

1. **Commit these files**:
   ```bash
   git add build-appwrite-image.sh docker-compose.coolify-simple.yml COOLIFY-DEPLOYMENT.md
   git commit -m "Add Coolify deployment strategy with pre-built images"
   git push origin my-env
   ```

2. **In Coolify**:
   - Edit your existing Appwrite application
   - Change **Docker Compose File** to: `docker-compose.coolify-simple.yml`
   - Add **Pre-Deployment Command**: `bash build-appwrite-image.sh`
   - **Redeploy**

3. **Monitor** the deployment logs:
   - You should see the build happening first
   - Then docker-compose using the built image
   - No more "Argument list too long" error!

---

## Troubleshooting

### If the image build takes too long:
- Increase Coolify's deployment timeout
- Or use Option C (GitHub Actions) to build separately

### If you need all services:
- Add them back one at a time to `docker-compose.coolify-simple.yml`
- Monitor the size to ensure it doesn't exceed Coolify's limits

### If you want faster deployments:
- Use GitHub Container Registry (Option C)
- Only rebuild when code changes, not on every deploy

