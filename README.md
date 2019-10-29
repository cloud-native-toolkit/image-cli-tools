# IBM Garage command-line tools

This repository contains a docker image to help setup an IBM Cloud Public development environment. The built image
contains the following tools:
- terraform cli
- terraform plugins:
  - terraform-provider-helm
  - terraform-provider-kube
  - terraform-provider-ibm
- calico cli
- ibmcloud cli
- ibmcloud plugins:
  - container-service
  - container-registry
  - cloud-databases
- docker cli
- kubectl cli
- kustomize cli
- openshift (oc) cli 
- helm cli
- git cli
- nvm cli
- node cli
- npm cli
- yeoman (yo) cli

Helper scripts have also been provided in the image:
- init.sh
- createNamespaces.sh
- installHelm.sh
- cluster-pull-secret-apply.sh
- setup-namespace-pull-secrets.sh
- checkPodRunning.sh
- copy-secret-to-namespace.sh

**Warning: The material contained in this repository has not been thoroughly tested. Proceed with caution.**

## Getting started

### Prerequisites

To run this image, the following tools are required:

- `Docker` - kinda obvious, but since we are running a Docker image, you need to have the tool available

### Running the client

Start the client to use it.

- To run the `icclient` container:

    ```bash
    docker run -itd --name icclient garagecatalyst/ibm-garage-cli-tools
    ```

    This  assumes the image's default name, `ibm-garage-cli-tools`.

Once the client is running in the backgroud, use it by opening a shell in it:

- To use the `icclient` container, exec shell into it:

    ```bash
    docker exec -it icclient /bin/bash
    ```

    Your terminal is now in the container. 

Use this shell to run commands using the installed CLIs.

When you're finished running commands, to exit the client.

- To leave the `icclient` container shell, like any shell:

    ```bash
    exit
    ```

    The container will keep running after you exit its shell.

If the client stops:

- To run the `icclient` container again:

    ```bash
    docker start icclient
    ```

The `icclient` container is just a Docker container, so all [Docker CLI commands](https://docs.docker.com/engine/reference/commandline/cli/) work.


## Development

### Prerequisites

To use/build this image, the following tools are required:

- `Docker` - kinda obvious, but since we are building, testing and running a Docker image, you need to have
the tool available
- `node/npm` - (optional) used to consolidate the configuration and scripts for working with the image, it
is **highly** recommended that `npm` is used; however, it is possible to run the scripts directly by looking
at `package.json` and providing the appropriate values

### Using the image

To use the image, a local image of the tool is required. You can get the image either by pulling from Docker Hub or 
building locally:

```bash
npm run pull
```

**OR**

```bash
npm run build
```

After that, start the image in an interactive terminal with:

```bash
npm start
```

### File Layout

- `package.json` - scripts and config for the image build
- `Dockerfile` - the docker image definition
- `config.yaml` - the test config file for the `container-structure-test` tool
- `scripts/` - directory for shell scripts used by `package.json` scripts to build, test, and 
push the image
- `src/` - directory containing files that should be included in the built image

### Commands

The following commands should be used when developing the docker image. They use scripts
provided in the `scripts/` folder.

#### Build the image

```bash
npm run build
```

This will build the image locally with the tag `IMAGE_NAME`:`IMAGE_VERSION`.

#### Test the image

```bash
npm test
```

This will build the image locally, if necessary, and validate the elements of the
image.

The tests use Google's `container-structure-test` to validate the structure of 
the image. Configuration for these tests are provided in the aptly named `config.yaml`.

See https://github.com/GoogleContainerTools/container-structure-test for information on the
defined values for the test definition.

#### Push the image to Docker Hub

```bash
npm run push
```

This will tag the local image version with the `IMAGE_ORG`/`IMAGE_NAME`:`IMAGE_VERSION`
tag and push it to Docker Hub.

#### Configuration

These scripts require parameters for:
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
