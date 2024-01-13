# Image Processing Pipeline - Elixir

This is an Elixir implementation of an image processing pipeline under [common specifications](https://github.com/tpf-concurrent-benchmarks/docs/tree/main/image_processing) defined for multiple languages.

The architecture is slightly modified, needing to add broker nodes to the system as the distribution, this architecture is documented at [distributed_pipeline/distributed_framework.md](distributed_pipeline/distributed_framework.md).

The objective of this project is to benchmark the language on a real-world distributed system.

## Deployment

- The project is deployed using docker swarm, `docker swarm init` initializes it.

- `make setup` will make other required initializations: Creates required folders and gives scripts permissions.

- `make clean_local_deploy` will remove old containers and deploy the system, waiting for the services to be ready.
- `make manager_iex` will open an iex session on the manager node, where we should run `DistributedPipeline.main` to start the pipeline.

> `make run` should execute all steps, but fails occasionally.

## Implementation details

- The system uses a custom made framework for distributed systems, documented at [distributed_pipeline/distributed_framework.md](distributed_pipeline/distributed_framework.md).
- All logic is defined in the manager node (the one that runs the `DistributedPipeline.main` function). And distributed to the workers using native elixir capabilities.
- Source, Sink and Brokers are run in the same node as the manager. Workers have their own node.
