WORKER_REPLICAS ?= 3
SECRET ?= secret

run:
	elixir src/alt_main.exs

deploy_local:
	WORKER_REPLICAS=$(WORKER_REPLICAS) SECRET=$(SECRET) docker stack deploy -c docker/docker-compose.yml ip_elixir 

remove_local:
	docker stack rm ip_elixir

worker_iex:
	@if [ -z "$(num)" ]; then \
		echo "Opening shell for worker.1"; \
		docker exec -it $(shell docker ps -q -f name=ip_elixir_worker.1) iex --sname worker --cookie $(SECRET) -S mix; \
	else \
		echo "Opening shell for worker.$(num)"; \
		docker exec -it $(shell docker ps -q -f name=ip_elixir_worker.$(num)) iex --sname worker --cookie $(SECRET) -S mix; \
	fi

worker_shell:
	@if [ -z "$(num)" ]; then \
		echo "Opening shell for worker.1"; \
		docker exec -it $(shell docker ps -q -f name=ip_elixir_worker.1) sh; \
	else \
		echo "Opening shell for worker.$(num)"; \
		docker exec -it $(shell docker ps -q -f name=ip_elixir_worker.$(num)) sh; \
	fi

manager_iex:
	docker exec -it $(shell docker ps -q -f name=ip_elixir_manager) iex --sname manager --cookie $(SECRET) -S mix

manager_shell:
	docker exec -it $(shell docker ps -q -f name=ip_elixir_manager) sh