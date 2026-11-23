# agent-kit CD — build once, promote the same image: develop → staging, tag vX.Y.Z → production (manual approval).
# Configure GitHub environments "staging" and "production" (required reviewers on production) and replace the deploy steps.
name: cd
on:
  push:
    branches: [develop]
    tags: ["v*.*.*"]

permissions:
  contents: read

concurrency:
  group: cd-${{ github.ref }}
  cancel-in-progress: false

jobs:
  build:
    name: build & push images
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write
    strategy:
      matrix:
        include:
# @@IMAGES@@
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}/${{ matrix.name }}
          tags: |
            type=semver,pattern={{version}}
            type=sha,format=short
            type=ref,event=branch
      - uses: docker/build-push-action@v6
        with:
          context: ${{ matrix.context }}
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          provenance: true
          sbom: true
          cache-from: type=gha,scope=${{ matrix.name }}
          cache-to: type=gha,mode=max,scope=${{ matrix.name }}

  deploy-staging:
    name: deploy staging
    if: github.ref == 'refs/heads/develop'
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        env:
          IMAGE_TAG: sha-${{ github.sha }}
        run: |
          echo "TODO(devops): deploy images with tag ${IMAGE_TAG:0:11} to staging (compose pull/up over SSH, helm upgrade, or PaaS CLI)."
          echo "Keep credentials in the 'staging' environment secrets; prefer OIDC to cloud providers."
      - name: Smoke test
        run: |
          echo "TODO(devops) - curl the staging health endpoint and run kit-run perf against staging"

  deploy-production:
    name: deploy production
    if: startsWith(github.ref, 'refs/tags/v')
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        env:
          VERSION: ${{ github.ref_name }}
        run: |
          echo "TODO(devops): deploy images ${VERSION} to production — this job runs only after an approver accepts the 'production' environment."
