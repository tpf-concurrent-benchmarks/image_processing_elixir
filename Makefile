WORKER_REPLICAS ?= 3
SECRET ?= secret

_script_permisions:
	chmod -R +x ./scripts

_common_folders:
	mkdir -p shared
	mkdir -p shared/input
	rm -rf shared/formatted || true
	mkdir -p shared/formatted
	rm -rf shared/scaled || true
	mkdir -p shared/scaled
	rm -rf shared/output || true
	mkdir -p shared/output
.PHONY: _common_folders

setup: _script_permisions _common_folders

deploy_local:
	WORKER_REPLICAS=$(WORKER_REPLICAS) SECRET=$(SECRET) docker stack deploy -c docker/docker-compose.yml ip_elixir 

remove_local:
	-docker service rm $(shell docker service ls -q -f name=ip_elixir) || echo "No services to remove"

up: setup
	make remove_local
	make deploy_local
	@echo "Waiting for services to start..."
	@while [ $$(docker service ls --filter name=ip_elixir --format "{{.Replicas}}" | grep -v "0/0" | awk -F/ '{if ($$1!=$$2) print $$0}' | wc -l) -gt 0 ]; do sleep 1; done
	@echo "Waiting for setup to complete..."
		@for container in $$(docker ps -qf "name=ip_elixir" -f "status=running"); do \
				echo "> Waiting for setup to complete for $$container"; \
				while ! docker logs $$container 2>&1 | grep -q "Setup complete"; do \
						sleep 1; \
				done; \
		done
	@echo "All services are up and running."
	make manager_iex

full_remove_local:
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

manager_logs:
	docker service logs -f $(shell docker service ls -q -f name=ip_elixir_manager) --raw

worker_logs:
	./docker/logs.sh

worker1_logs:
	docker service logs -f $(shell docker service ls -q -f name=ip_elixir_worker.1) --raw