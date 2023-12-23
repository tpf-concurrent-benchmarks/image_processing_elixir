

run:
	elixir src/alt_main.exs

deploy_local:
	docker stack deploy -c docker/docker-compose.yml ip_elixir

remove_local:
	docker stack rm ip_elixir

worker_shell:
	docker exec -it $(shell docker ps -q -f name=ip_elixir_worker) iex --sname worker --cookie secret

manager_shell:
	docker exec -it $(shell docker ps -q -f name=ip_elixir_manager) iex --sname manager --cookie secret