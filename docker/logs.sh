for service in $(docker service ls --format '{{.Name}}'); do
  echo "Logs for $service:"
  # ignore if manager
  if [[ $service == *"manager"* ]]; then
    continue
  fi
  docker service logs $service
done