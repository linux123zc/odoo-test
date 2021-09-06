# usage: docker_process_init_files [file [file [...]]]
#    ie: docker_process_init_files /always-initdb.d/*
# process initializer files, based on file extensions and permissions
docker_process_init_files() {
        for f; do
                case "$f" in
                        *.sh)
                                # https://github.com/docker-library/postgres/issues/450#issuecomment-393167936
                                # https://github.com/docker-library/postgres/pull/452
                                if [ -x "$f" ]; then
                                        echo "$0: running $f"
                                        "$f"
                                else
                                        echo "$0: sourcing $f"
                                        . "$f"
                                fi
                                ;;
                        *)        echo "$0: ignoring $f" ;;
                esac
        done
}
if [ ! -d /cloudclusters/.docker-entrypoint.d ]; then
    mkdir -p /cloudclusters/.docker-entrypoint.d
fi
docker_process_init_files /cloudclusters/.docker-entrypoint.d/*