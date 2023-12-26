for service in $(docker service ls --format '{{.Name}}'); do
  echo "Logs for $service:"
  docker service logs $service
done