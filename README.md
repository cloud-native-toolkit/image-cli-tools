# Cloud-Native Toolkit cli tools

[![Docker Repository on Quay](https://quay.io/repository/cloudnativetoolkit/cli-tools/status "Docker Repository on Quay")](https://quay.io/repository/cloudnativetoolkit/cli-tools)

This repository builds a Docker image whose container is a client for interacting with different cloud providers (IBM Cloud, AWS, Azure).

The container includes the following tools:
- terraform cli
- IBM Cloud cli
- AWS cli
- Azure cli
- bash
- kubectl cli
- oc cli
- git cli
- perl cli
- jq cli
- yq3 cli
- yq4 cli

**Warning: The material contained in this repository has not been thoroughly tested. Proceed with caution.**

## Getting started

### Prerequisites

To run this image, the following tools are required:

- `docker` cli
- `docker` backend - Docker Desktop, colima, etc

### Running the client

Start the client to use it.

- To run the `toolkit` container:

    ```bash
    docker run -itd --name toolkit quay.io/cloudnativetoolkit/cli-tools
    ```

Once the client is running in the background, use it by opening a shell in it.

- To use the `toolkit` container, exec shell into it:

    ```bash
    docker exec -it toolkit /bin/bash
    ```

    Your terminal is now in the container. 

Use this shell to run commands using the installed tools and scripts.

When you're finished running commands, to exit the client.

- To leave the `toolkit` container shell, as with any shell:

    ```bash
    exit
    ```

    The container will keep running after you exit its shell.

If the client stops:

- To run the `toolkit` container again:

    ```bash
    docker start toolkit
    ```

The `toolkit` container is just a Docker container, so all [Docker CLI commands](https://docs.docker.com/engine/reference/commandline/cli/) work.

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
