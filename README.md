# client-tools-image

This repository contains a docker image to help setup an IBM Cloud Public development environment.

**Warning: The material contained in this repository has not been thoroughly tested. Proceed with caution.**

## File Layout

- `package.json` - scripts and config for the image build
- `Dockerfile` - the docker image definition
- `config.yaml` - the test config file for the `container-structure-test` tool
- `scripts/` - directory for shell scripts used by `package.json` scripts to build, test, and 
push the image

## Commands

The following commands should be used when developing the docker image. They use scripts
provided in the `scripts/` folder. These scripts require parameters for:
- `IMAGE_ORG` 
- `IMAGE_NAME`
- `IMAGE_VERSION`

When the scripts are run using `npm` (recommended) then these parameters are provided from
config values in `package.json`:
- `org`
- `name`
- `version`

The default/preferred `org` for the image is `garagecatalyst`. If you need access to the
org in Docker Hub contact Matt Perrins (mjperrin@us.ibm.com) or Sean Sundberg 
(seansund@us.ibm.com).

### Build the image

```bash
npm run build
```

This will build the image locally with the tag `IMAGE_NAME`:`IMAGE_VERSION`.

### Test the image

```bash
npm test
```

This will build the image locally, if necessary, and validate the elements of the
image.

The tests use Google's `container-structure-test` to validate the structure of 
the image. Configuration for these tests are provided in the aptly named `config.yaml`.

See https://github.com/GoogleContainerTools/container-structure-test for information on the
defined values for the test definition.

### Push the image to Docker Hub

```bash
npm run push
```

This will tag the local image version with the `IMAGE_ORG`/`IMAGE_NAME`:`IMAGE_VERSION`
tag and push it to Docker Hub.
