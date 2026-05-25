# EvergineDocs

Human-written documentation for Evergine. Also builds sources documentation and publish everything by the CD pipeline.

## Pipelines

CD pipeline uses a PAT token to access the "Engine" repo of Evergine. It is named `ENGINE_GITHUB_TOKEN` and it is configured as a fine-graine token with similar permissions as the [_GITHUB_TOKEN_](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication#permissions-for-the-github_token) but restricted to one repository.

## Dev

Local compilation:

```pwsh
.\scripts\create_docfx_api_config.ps1 [-evergineFolder "../Engine"]
.\scripts\build_api.ps1
.\scripts\build_docs.ps1
```

This repository now requires the **.NET 10 SDK** to build the API documentation against the current Evergine sources.

Generated documentation can be found at `build/dist` and can be served with any static file server.
