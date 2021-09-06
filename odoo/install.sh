#!/bin/bash
set -x

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

# Update odoo config file with format "setting = value"
function add_setting_to_conf
{
    local _setting=${1}
    local _value=${2}

    if grep -i -q -F "${_setting}" "${ODOO_RC}"; then
        # Replace existing line with new value
        # echo "Update existing setting."
        sed -i 's/^.*'"${_setting}"'.*/'"${_setting}"' = '"${_value}"'/' "${ODOO_RC}"
    else
        # Append new setting to the end
        # echo "Append new setting."
        sed -i '$a\'"${_setting}"' = '"${_value}"'' "${ODOO_RC}"
    fi
}

if [ ! -d /cloudclusters/config ]; then
    mkdir /cloudclusters/config
    mkdir /cloudclusters/config/odoo
    #config file
    cp /opt/odoo/odoo.conf.default /cloudclusters/config/odoo/odoo.conf
	  sed -i "s#^admin_passwd.*#admin_passwd = ${MASTER_PASSWORD}#g" /cloudclusters/config/odoo/odoo.conf

	  # If var MEM_LIMIT is undefined or null, set RAM=2. Otherwise, set RAM= ${MEM_LIMIT}
    : ${RAM:=${MEM_LIMIT:-2}}
    : ${CPU:=${CPU_LIMIT:-2}}

    # Optimize Odoo parameters
    if [[ ${CPU} -ge 6 ]] && [[ ${RAM} -ge 16 ]]; then
        echo "Optimize Odoo parameters for Advanced or Advanced+ plan."
        add_setting_to_conf workers 8
        add_setting_to_conf limit_request 16384
        add_setting_to_conf limit_memory_hard 7549747200
        add_setting_to_conf limit_memory_soft 6039797760
    elif [[ ${CPU} -ge 4 ]] && [[ ${RAM} -ge 8 ]]; then
        echo "Optimize Odoo parameters for Professional plan."
        add_setting_to_conf workers 6
        add_setting_to_conf limit_request 8192
        add_setting_to_conf limit_memory_hard 5872025600
        add_setting_to_conf limit_memory_soft 4697620480
    elif [[ ${CPU} -ge 3 ]] && [[ ${RAM} -ge 4 ]]; then
        echo "Optimize Odoo parameters for Basic plan."
        add_setting_to_conf workers 4
        add_setting_to_conf limit_request 4096
        add_setting_to_conf limit_memory_hard 2684354560
        add_setting_to_conf limit_memory_soft 2147483648
    else
        echo "Optimize Odoo parameters for Express plan."
        add_setting_to_conf workers 2
        add_setting_to_conf limit_request 2048
        add_setting_to_conf limit_memory_hard 1342177280
        add_setting_to_conf limit_memory_soft 1073741824
    fi
fi

# init install
if [ ! -d /cloudclusters/odoo ]; then
    mkdir /cloudclusters/odoo
    tar -xzf /opt/odoo/odoo_*.tar.gz -C /cloudclusters/odoo --strip-components=1
    sed -i '560a\<a href="https://www.odclusters.com" title="Odoo Cloud Hosting on Kubernetes Cloud">Hosted By Odoo Clusters</a>' /cloudclusters/odoo/odoo/addons/web/views/webclient_templates.xml
    virtualenv -p python3 odoo/venv
    source odoo/venv/bin/activate
    pip3 install -r odoo/requirements.txt
    pip3 install psycopg2-binary
    pip3 install requests
    chown -R odoo:odoo /cloudclusters/odoo
    chmod -R 755 /cloudclusters/odoo

    if [ -f /cloudclusters/odoo/setup/odoo ]; then
	    chmod +x /cloudclusters/odoo/setup/odoo
	    mv /cloudclusters/odoo/setup/odoo odoo/odoo-bin
    fi

    postgres.sh postgres &

    gosu odoo odoo.sh odoo &

    while true
    do
        if psql -Uadmin -d admin -c "select * from account_account;"
        then
            break
        else
            sleep 10
        fi
    done

    exit 0
  fi
fi
