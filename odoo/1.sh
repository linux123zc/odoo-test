
if [ ! -d /cloudclusters/.docker-entrypoint.d ]; then
    mkdir -p /cloudclusters/.docker-entrypoint.d
fi
docker_process_init_files /cloudclusters/.docker-entrypoint.d/*