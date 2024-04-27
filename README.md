# Image Processing Pipeline - Elixir

## Objective

This is an Elixir implementation of an image processing pipeline under [common specifications](https://github.com/tpf-concurrent-benchmarks/docs/tree/main/image_processing) defined for multiple languages.

The objective of this project is to benchmark the language on a real-world distributed system.

## Architecture

The architecture is slightly modified, needing to add broker nodes to the system as the distribution, this architecture is documented at [distributed_pipeline/distributed_framework.md](distributed_pipeline/distributed_framework.md).

## Deployment

### Requirements

- [Docker >3](https://www.docker.com/) (needs docker swarm)

### Configuration

- **Number of replicas:** `FORMAT_WORKER_REPLICAS`, `RESOLUTION_WORKER_REPLICAS` and `SIZE_WORKER_REPLICAS` constants are defined in the `Makefile` file.

### Commands

#### Startup

- `docker swarm init`: initializes docker swarm.
- `make setup` will make other required initializations: Creates required folders and gives scripts permissions.
- `template_data`: downloads test image into the input folder

#### Run

- `make clean_local_deploy` will remove old containers and deploy the system, waiting for the services to be ready.
- Afterwards: `make manager_iex` will open an iex session on the manager node.
- Afterwards: Run `DistributedPipeline.main` (on iex) to start the pipeline.
- `make remove_local` will remove the system containers.
